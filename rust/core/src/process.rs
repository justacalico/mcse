use crate::models::{Event, Instance, InstanceStatus};
use crate::{Error, Result};
use std::collections::VecDeque;
use std::path::{Path, PathBuf};
use std::process::Stdio;
use std::sync::atomic::{AtomicBool, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::process::{Child, ChildStdin, Command};
use tokio::sync::{broadcast, Mutex, RwLock};
use uuid::Uuid;

const LOG_CAP: usize = 2000;
const STOP_TIMEOUT: Duration = Duration::from_secs(30);

pub struct ServerHandle {
    pub id: Uuid,
    pub status: RwLock<InstanceStatus>,
    pub started_at: RwLock<Option<Instant>>,
    pub recent_log: Mutex<VecDeque<String>>,
    stdin: Mutex<Option<ChildStdin>>,
    killed: AtomicBool,
    child: Mutex<Option<Child>>,
}

impl ServerHandle {
    fn new(id: Uuid, child: Child, stdin: ChildStdin) -> Arc<ServerHandle> {
        Arc::new(ServerHandle {
            id,
            status: RwLock::new(InstanceStatus::Starting),
            started_at: RwLock::new(Some(Instant::now())),
            recent_log: Mutex::new(VecDeque::with_capacity(LOG_CAP)),
            stdin: Mutex::new(Some(stdin)),
            killed: AtomicBool::new(false),
            child: Mutex::new(Some(child)),
        })
    }

    pub async fn status(&self) -> InstanceStatus {
        *self.status.read().await
    }

    pub async fn uptime_secs(&self) -> Option<u64> {
        self.started_at.read().await.map(|t| t.elapsed().as_secs())
    }

    pub async fn send_command(&self, command: &str) -> Result<()> {
        let mut stdin = self.stdin.lock().await;
        let stdin = stdin.as_mut().ok_or_else(|| Error::NotRunning(self.id))?;
        stdin.write_all(command.as_bytes()).await?;
        stdin.write_all(b"\n").await?;
        stdin.flush().await?;
        Ok(())
    }

    async fn push_log(&self, line: String) {
        let mut log = self.recent_log.lock().await;
        if log.len() >= LOG_CAP {
            log.pop_front();
        }
        log.push_back(line);
    }

    /// Ask the server to stop, then force-kill after the timeout.
    pub async fn stop(&self) -> Result<()> {
        {
            let mut status = self.status.write().await;
            if *status != InstanceStatus::Running && *status != InstanceStatus::Starting {
                return Err(Error::NotRunning(self.id));
            }
            *status = InstanceStatus::Stopping;
        }
        let _ = self.send_command("stop").await;
        Ok(())
    }

    pub async fn kill(&self) {
        self.killed.store(true, Ordering::SeqCst);
        if let Some(child) = self.child.lock().await.as_mut() {
            let _ = child.kill().await;
        }
    }
}

/// Arguments needed to launch an instance's JVM.
#[derive(Debug)]
pub struct LaunchSpec {
    pub java: PathBuf,
    pub args: Vec<String>,
    pub dir: PathBuf,
}

/// Build the JVM arg list for a direct-jar instance.
pub fn jar_args(instance: &Instance) -> Vec<String> {
    let mut args = vec![
        format!("-Xms{}M", instance.min_ram_mb),
        format!("-Xmx{}M", instance.max_ram_mb),
    ];
    args.extend(instance.jvm_args.iter().cloned());
    if let Some(jar) = &instance.jar {
        args.push("-jar".into());
        args.push(jar.clone());
    }
    args.extend(installer_args(&instance.dir));
    args.push("nogui".into());
    args
}

/// For installer-based servers (Forge/NeoForge), pick up the generated
/// `@argfile`s the same way the bundled run scripts do.
fn installer_args(dir: &Path) -> Vec<String> {
    let mut args = vec![];
    let user_args = dir.join("user_jvm_args.txt");
    if user_args.exists() {
        args.push(format!("@{}", user_args.display()));
    }
    let variant = if cfg!(windows) {
        "win_args.txt"
    } else {
        "unix_args.txt"
    };
    let libs = dir.join("libraries");
    for group in ["net/minecraftforge/forge", "net/neoforged/neoforge"] {
        let base = libs.join(group);
        if let Ok(rd) = std::fs::read_dir(&base) {
            for e in rd.flatten() {
                let candidate = e.path().join(variant);
                if candidate.exists() {
                    args.push(format!("@{}", candidate.display()));
                }
            }
        }
    }
    args
}

/// Scan an installer-created dir for a runnable jar (older Forge).
pub fn find_server_jar(dir: &Path) -> Option<String> {
    let rd = std::fs::read_dir(dir).ok()?;
    let mut best: Option<String> = None;
    for e in rd.flatten() {
        let name = e.file_name().to_string_lossy().to_string();
        if !name.ends_with(".jar") || name.contains("installer") {
            continue;
        }
        if name.starts_with("forge-") || name.starts_with("minecraft_server") {
            return Some(name);
        }
        if best.is_none() {
            best = Some(name);
        }
    }
    best
}

/// Spawn the server process and wire up log streaming + lifecycle events.
/// The caller owns inserting the returned handle into its registry.
pub async fn spawn(
    spec: LaunchSpec,
    id: Uuid,
    events: broadcast::Sender<Event>,
) -> Result<Arc<ServerHandle>> {
    let mut cmd = Command::new(&spec.java);
    cmd.args(&spec.args)
        .current_dir(&spec.dir)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .kill_on_drop(true);
    let mut child = cmd
        .spawn()
        .map_err(|e| Error::Msg(format!("failed to start {:?}: {e}", spec.java)))?;
    let stdin = child.stdin.take().unwrap();
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let handle = ServerHandle::new(id, child, stdin);

    let h = Arc::clone(&handle);
    let ev = events.clone();
    tokio::spawn(async move {
        let mut lines = BufReader::new(stdout).lines();
        while let Ok(Some(line)) = lines.next_line().await {
            h.push_log(line.clone()).await;
            if line.contains("Done (") && line.contains("! For help") {
                let mut s = h.status.write().await;
                if *s == InstanceStatus::Starting {
                    *s = InstanceStatus::Running;
                    let _ = ev.send(Event::StatusChanged {
                        id,
                        status: InstanceStatus::Running,
                    });
                }
            }
            let _ = ev.send(Event::Log { id, line });
        }
    });

    let h = Arc::clone(&handle);
    let ev = events.clone();
    tokio::spawn(async move {
        let mut lines = BufReader::new(stderr).lines();
        while let Ok(Some(line)) = lines.next_line().await {
            let line = format!("[stderr] {line}");
            h.push_log(line.clone()).await;
            let _ = ev.send(Event::Log { id, line });
        }
    });

    // Watchdog: handle exit + graceful-stop timeout.
    let h = Arc::clone(&handle);
    tokio::spawn(async move {
        let mut stop_deadline: Option<Instant> = None;
        loop {
            {
                let mut child_guard = h.child.lock().await;
                if let Some(child) = child_guard.as_mut() {
                    match child.try_wait() {
                        Ok(Some(code)) => {
                            drop(child_guard);
                            finish(&h, events.clone(), code.success()).await;
                            return;
                        }
                        Ok(None) => {}
                        Err(_) => {
                            drop(child_guard);
                            finish(&h, events.clone(), false).await;
                            return;
                        }
                    }
                } else {
                    finish(&h, events.clone(), false).await;
                    return;
                }
            }
            if *h.status.read().await == InstanceStatus::Stopping {
                let deadline = *stop_deadline.get_or_insert_with(Instant::now);
                if deadline.elapsed() > STOP_TIMEOUT {
                    h.kill().await;
                }
            }
            tokio::time::sleep(Duration::from_millis(200)).await;
        }
    });

    Ok(handle)
}

async fn finish(h: &Arc<ServerHandle>, events: broadcast::Sender<Event>, clean: bool) {
    let mut status = h.status.write().await;
    if *status == InstanceStatus::Stopped {
        return;
    }
    *status = if clean || *status == InstanceStatus::Stopping || h.killed.load(Ordering::SeqCst) {
        InstanceStatus::Stopped
    } else {
        InstanceStatus::Crashed
    };
    let final_status = *status;
    *h.started_at.write().await = None;
    drop(status);
    let _ = events.send(Event::StatusChanged {
        id: h.id,
        status: final_status,
    });
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Utc;

    fn instance(dir: PathBuf, jar: Option<&str>) -> Instance {
        Instance {
            id: Uuid::new_v4(),
            name: "t".into(),
            loader: crate::models::LoaderKind::Vanilla,
            game_version: "1.21".into(),
            loader_version: None,
            dir,
            jar: jar.map(Into::into),
            java_path: None,
            min_ram_mb: 512,
            max_ram_mb: 2048,
            jvm_args: vec!["-Dfoo=bar".into()],
            created_at: Utc::now(),
        }
    }

    #[test]
    fn jar_args_built() {
        let i = instance(PathBuf::from("/tmp/none"), Some("server.jar"));
        let args = jar_args(&i);
        assert!(args.contains(&"-Xms512M".to_string()));
        assert!(args.contains(&"-Xmx2048M".to_string()));
        assert!(args.contains(&"-Dfoo=bar".to_string()));
        assert_eq!(args[args.len() - 3..], ["-jar", "server.jar", "nogui"]);
    }

    #[test]
    fn finds_jar() {
        let dir = tempfile::tempdir().unwrap();
        std::fs::write(dir.path().join("forge-1.20.1.jar"), b"x").unwrap();
        std::fs::write(dir.path().join("forge-installer.jar"), b"x").unwrap();
        assert_eq!(
            find_server_jar(dir.path()),
            Some("forge-1.20.1.jar".to_string())
        );
    }
}
