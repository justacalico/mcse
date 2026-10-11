use crate::loader;
use crate::models::ServerArtifact;
use crate::models::*;
use crate::process::{self, LaunchSpec, ServerHandle};
use crate::props::ServerProperties;
use crate::store::Store;
use crate::{backup, java, paths, ping, props, Error, Result};
use std::collections::BTreeMap;
use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::Arc;
use std::time::Duration;
use tokio::sync::{broadcast, RwLock};
use uuid::Uuid;

#[derive(Debug, Clone)]
pub struct CreateRequest {
    /// Pre-generated id so callers can correlate progress events before the
    /// instance exists.
    pub id: Uuid,
    pub name: String,
    pub loader: LoaderKind,
    pub game_version: String,
    pub accept_eula: bool,
    pub min_ram_mb: u32,
    pub max_ram_mb: u32,
    pub properties: BTreeMap<String, String>,
}

pub struct Manager {
    pub data_dir: PathBuf,
    store: RwLock<Store>,
    running: RwLock<HashMap<Uuid, Arc<ServerHandle>>>,
    events: broadcast::Sender<Event>,
    http: reqwest::Client,
}

impl Manager {
    pub fn new(data_dir: PathBuf) -> Result<Arc<Manager>> {
        std::fs::create_dir_all(&data_dir)?;
        std::fs::create_dir_all(paths::instances_dir(&data_dir))?;
        std::fs::create_dir_all(paths::backups_dir(&data_dir))?;
        std::fs::create_dir_all(paths::runtimes_dir(&data_dir))?;
        std::fs::create_dir_all(paths::downloads_dir(&data_dir))?;
        let (events, _) = broadcast::channel(2048);
        Ok(Arc::new(Manager {
            store: RwLock::new(Store::load(&data_dir)?),
            running: RwLock::new(HashMap::new()),
            events,
            http: reqwest::Client::builder()
                .user_agent(concat!("mcse/", env!("CARGO_PKG_VERSION")))
                .connect_timeout(Duration::from_secs(15))
                .read_timeout(Duration::from_secs(120))
                .build()?,
            data_dir,
        }))
    }

    pub fn subscribe(&self) -> broadcast::Receiver<Event> {
        self.events.subscribe()
    }

    pub fn notify(&self, event: Event) {
        let _ = self.events.send(event);
    }

    async fn instance(&self, id: Uuid) -> Result<Instance> {
        self.store
            .read()
            .await
            .instances
            .get(&id)
            .cloned()
            .ok_or(Error::InstanceNotFound(id))
    }

    pub async fn list_instances(&self) -> Vec<InstanceSummary> {
        let store = self.store.read().await;
        let running = self.running.read().await;
        let mut out = vec![];
        for inst in store.instances.values() {
            let status = match running.get(&inst.id) {
                Some(h) => h.status().await,
                None => InstanceStatus::Stopped,
            };
            out.push(InstanceSummary {
                instance: inst.clone(),
                status,
                online_players: None,
                max_players: None,
            });
        }
        out.sort_by_key(|i| i.instance.created_at);
        out
    }

    /// Status of a single instance (Stopped when not in `running`).
    pub async fn status(&self, id: Uuid) -> Result<InstanceStatus> {
        self.instance(id).await?;
        Ok(match self.running.read().await.get(&id) {
            Some(h) => h.status().await,
            None => InstanceStatus::Stopped,
        })
    }

    pub async fn uptime_secs(&self, id: Uuid) -> Result<Option<u64>> {
        self.instance(id).await?;
        Ok(match self.running.read().await.get(&id) {
            Some(h) => h.uptime_secs().await,
            None => None,
        })
    }

    pub async fn recent_log(&self, id: Uuid) -> Result<Vec<String>> {
        self.instance(id).await?;
        Ok(match self.running.read().await.get(&id) {
            Some(h) => h.recent_log.lock().await.iter().cloned().collect(),
            None => vec![],
        })
    }

    pub async fn game_versions(&self, loader: LoaderKind) -> Result<Vec<GameVersion>> {
        loader::provider(loader).game_versions(&self.http).await
    }

    /// Create an instance: download the artifact, run installers, write
    /// eula + properties, register it. Progress arrives on the event bus.
    pub async fn create_instance(self: &Arc<Self>, req: CreateRequest) -> Result<Uuid> {
        if !req.accept_eula {
            return Err(Error::Msg(
                "the Minecraft EULA must be accepted to create a server".into(),
            ));
        }
        let id = req.id;
        let dir = paths::instances_dir(&self.data_dir).join(id.to_string());
        tokio::fs::create_dir_all(&dir).await?;
        match self.create_in_dir(id, &dir, req).await {
            Ok(()) => Ok(id),
            Err(e) => {
                let _ = tokio::fs::remove_dir_all(&dir).await;
                Err(e)
            }
        }
    }

    async fn create_in_dir(
        self: &Arc<Self>,
        id: Uuid,
        dir: &std::path::Path,
        req: CreateRequest,
    ) -> Result<()> {
        let provider = loader::provider(req.loader);
        let artifact = provider.resolve(&self.http, &req.game_version).await?;
        let (url, filename, sha1, sha256, md5, installer) = match artifact {
            ServerArtifact::Jar {
                url,
                filename,
                sha1,
                sha256,
                md5,
            } => (url, filename, sha1, sha256, md5, None),
            ServerArtifact::Installer {
                url,
                filename,
                sha1,
                args,
            } => (url, filename, sha1, None, None, Some(args)),
        };

        let jar_path = dir.join(&filename);
        let events = self.events.clone();
        crate::download::download(
            &self.http,
            &url,
            &jar_path,
            sha1.as_deref(),
            sha256.as_deref(),
            md5.as_deref(),
            move |received, total| {
                let _ = events.send(Event::DownloadProgress {
                    id,
                    received,
                    total,
                });
            },
        )
        .await?;

        let mut jar = Some(filename.clone());
        if let Some(args) = installer {
            self.run_installer(id, dir, &jar_path, &args).await?;
            let _ = tokio::fs::remove_file(&jar_path).await;
            jar = process::find_server_jar(dir);
        }

        tokio::fs::write(dir.join("eula.txt"), "eula=true\n").await?;
        ServerProperties::update_file(&dir.join("server.properties"), &req.properties)?;

        let instance = Instance {
            id,
            name: req.name,
            loader: req.loader,
            game_version: req.game_version.clone(),
            loader_version: None,
            dir: dir.to_path_buf(),
            jar,
            java_path: None,
            min_ram_mb: req.min_ram_mb,
            max_ram_mb: req.max_ram_mb,
            jvm_args: vec![],
            created_at: chrono::Utc::now(),
        };
        self.store.write().await.insert(instance)?;
        let _ = self.events.send(Event::InstanceCreated { id });
        Ok(())
    }

    async fn run_installer(
        &self,
        id: Uuid,
        dir: &std::path::Path,
        jar: &std::path::Path,
        args: &[String],
    ) -> Result<()> {
        let runtimes = java::detect_runtimes(&self.data_dir).await;
        let java = java::pick_runtime(&runtimes, 8)
            .or_else(|| runtimes.first())
            .ok_or(Error::NoJava {
                required: 8,
                have: "none".into(),
            })?
            .path
            .clone();
        let mut cmd = tokio::process::Command::new(java);
        cmd.arg("-jar").arg(jar).args(args).current_dir(dir);
        cmd.stdout(std::process::Stdio::piped());
        cmd.stderr(std::process::Stdio::piped());
        let mut child = cmd.spawn()?;
        let events = self.events.clone();
        use tokio::io::AsyncRead;
        let pipes: Vec<Option<Box<dyn AsyncRead + Send + Unpin>>> = vec![
            child.stdout.take().map(|o| Box::new(o) as _),
            child.stderr.take().map(|o| Box::new(o) as _),
        ];
        for pipe in pipes.into_iter().flatten() {
            let events = events.clone();
            tokio::spawn(async move {
                use tokio::io::{AsyncBufReadExt, BufReader};
                let mut lines = BufReader::new(pipe).lines();
                while let Ok(Some(line)) = lines.next_line().await {
                    let _ = events.send(Event::InstallProgress { id, line });
                }
            });
        }
        let status = child.wait().await?;
        if !status.success() {
            return Err(Error::Installer(format!("installer exited with {status}")));
        }
        Ok(())
    }

    pub async fn delete_instance(&self, id: Uuid, remove_files: bool) -> Result<()> {
        self.stop_internal(id, true).await;
        self.running.write().await.remove(&id);
        let inst = self
            .store
            .write()
            .await
            .remove(id)?
            .ok_or(Error::InstanceNotFound(id))?;
        if remove_files {
            let instances_root = paths::instances_dir(&self.data_dir);
            if inst.dir.starts_with(&instances_root) {
                let _ = tokio::fs::remove_dir_all(&inst.dir).await;
            }
            let backup_dir = paths::backups_dir(&self.data_dir).join(id.to_string());
            let _ = tokio::fs::remove_dir_all(&backup_dir).await;
        }
        Ok(())
    }

    async fn launch_spec(&self, inst: &Instance) -> Result<LaunchSpec> {
        let required = java::required_java(&inst.game_version);
        let java_path = match &inst.java_path {
            Some(p) => PathBuf::from(p),
            None => {
                let runtimes = java::detect_runtimes(&self.data_dir).await;
                java::pick_runtime(&runtimes, required)
                    .ok_or_else(|| Error::NoJava {
                        required,
                        have: runtimes
                            .iter()
                            .map(|r| r.major.to_string())
                            .collect::<Vec<_>>()
                            .join(", "),
                    })?
                    .path
                    .clone()
            }
        };
        Ok(LaunchSpec {
            java: java_path,
            args: process::jar_args(inst),
            dir: inst.dir.clone(),
        })
    }

    pub async fn start(self: &Arc<Self>, id: Uuid) -> Result<()> {
        let inst = self.instance(id).await?;
        let spec = self.launch_spec(&inst).await?;
        let mut running = self.running.write().await;
        if let Some(h) = running.get(&id) {
            let s = h.status().await;
            if s == InstanceStatus::Stopped || s == InstanceStatus::Crashed {
                running.remove(&id);
            } else {
                return Err(Error::AlreadyRunning(id));
            }
        }
        let _ = self.events.send(Event::StatusChanged {
            id,
            status: InstanceStatus::Starting,
        });
        let handle = process::spawn(spec, id, self.events.clone()).await?;
        running.insert(id, handle);
        Ok(())
    }

    async fn stop_internal(&self, id: Uuid, wait: bool) {
        let handle = self.running.read().await.get(&id).cloned();
        if let Some(h) = handle {
            let _ = h.stop().await;
            let _ = self.events.send(Event::StatusChanged {
                id,
                status: InstanceStatus::Stopping,
            });
            if wait {
                for _ in 0..600 {
                    if h.status().await == InstanceStatus::Stopped
                        || h.status().await == InstanceStatus::Crashed
                    {
                        break;
                    }
                    tokio::time::sleep(Duration::from_millis(100)).await;
                }
                h.kill().await;
            }
        }
    }

    pub async fn stop(&self, id: Uuid) -> Result<()> {
        self.instance(id).await?;
        if !self.running.read().await.contains_key(&id) {
            return Err(Error::NotRunning(id));
        }
        self.stop_internal(id, false).await;
        Ok(())
    }

    pub async fn kill(&self, id: Uuid) -> Result<()> {
        self.instance(id).await?;
        let h = self
            .running
            .read()
            .await
            .get(&id)
            .cloned()
            .ok_or(Error::NotRunning(id))?;
        h.kill().await;
        Ok(())
    }

    /// Remove a finished/crashed handle so the instance can start again.
    pub async fn reap(&self, id: Uuid) {
        let dead = match self.running.read().await.get(&id) {
            Some(h) => {
                let s = h.status().await;
                s == InstanceStatus::Stopped || s == InstanceStatus::Crashed
            }
            None => false,
        };
        if dead {
            self.running.write().await.remove(&id);
        }
    }

    pub async fn restart(self: &Arc<Self>, id: Uuid) -> Result<()> {
        self.instance(id).await?;
        if self.running.read().await.contains_key(&id) {
            self.stop_internal(id, true).await;
            self.reap(id).await;
        }
        self.start(id).await
    }

    pub async fn send_command(&self, id: Uuid, command: &str) -> Result<()> {
        let h = self
            .running
            .read()
            .await
            .get(&id)
            .cloned()
            .ok_or(Error::NotRunning(id))?;
        h.send_command(command).await
    }

    pub async fn get_properties(&self, id: Uuid) -> Result<BTreeMap<String, String>> {
        let inst = self.instance(id).await?;
        Ok(ServerProperties::load(&inst.dir.join("server.properties"))?.map)
    }

    pub async fn set_properties(&self, id: Uuid, changes: BTreeMap<String, String>) -> Result<()> {
        let inst = self.instance(id).await?;
        ServerProperties::update_file(&inst.dir.join("server.properties"), &changes)
    }

    pub async fn list_backups(&self, id: Uuid) -> Result<Vec<BackupMeta>> {
        let inst = self.instance(id).await?;
        backup::list(&self.data_dir, &inst).await
    }

    pub async fn create_backup(&self, id: Uuid) -> Result<BackupMeta> {
        let inst = self.instance(id).await?;
        let running = self.running.read().await.get(&id).cloned();
        let meta = if let Some(h) = running {
            // Flush world data before zipping a live server.
            let _ = h.send_command("save-off").await;
            let _ = h.send_command("save-all").await;
            tokio::time::sleep(Duration::from_secs(2)).await;
            let meta = backup::create(&self.data_dir, &inst).await;
            let _ = h.send_command("save-on").await;
            meta?
        } else {
            backup::create(&self.data_dir, &inst).await?
        };
        let _ = self.events.send(Event::BackupCreated {
            id,
            name: meta.name.clone(),
        });
        Ok(meta)
    }

    pub async fn delete_backup(&self, id: Uuid, name: &str) -> Result<()> {
        let inst = self.instance(id).await?;
        backup::remove(&self.data_dir, &inst, name).await
    }

    pub async fn restore_backup(self: &Arc<Self>, id: Uuid, name: &str) -> Result<()> {
        let inst = self.instance(id).await?;
        if self.running.read().await.contains_key(&id) {
            self.stop_internal(id, true).await;
            self.reap(id).await;
        }
        backup::restore(&self.data_dir, &inst, name).await
    }

    /// Server-list ping to 127.0.0.1 on the configured port.
    pub async fn ping(&self, id: Uuid) -> Result<PingResult> {
        let inst = self.instance(id).await?;
        let props = ServerProperties::load(&inst.dir.join("server.properties"))?;
        let port = props.get_u16("server-port", 25565);
        ping::ping("127.0.0.1", port, Duration::from_secs(3)).await
    }

    pub async fn runtimes(&self) -> Vec<JavaRuntime> {
        java::detect_runtimes(&self.data_dir).await
    }

    pub async fn java_releases(&self) -> Result<Vec<JavaRelease>> {
        java::available_releases(&self.http).await
    }

    pub async fn install_java(&self, feature: u32) -> Result<JavaRuntime> {
        let send = |stage: &str, received: u64, total: Option<u64>| {
            let _ = self.events.send(Event::JavaInstall {
                feature,
                stage: stage.to_string(),
                received,
                total,
            });
        };
        let rt = java::install_temurin(
            &self.http,
            &self.data_dir,
            feature,
            |received, total| send("download", received, total),
            |stage| send(stage, 0, None),
        )
        .await?;
        send("installed", 0, None);
        Ok(rt)
    }

    pub async fn remove_java(&self, feature: u32) -> Result<()> {
        let removed = java::remove_managed(&self.data_dir, feature).await?;
        // Instances pinned to a java under the removed dir fall back to
        // auto-detect instead of failing to launch.
        let mut store = self.store.write().await;
        for inst in store.instances.values_mut() {
            if let Some(p) = &inst.java_path {
                if Path::new(p).starts_with(&removed) {
                    inst.java_path = None;
                }
            }
        }
        store.save()
    }

    pub async fn set_java(&self, id: Uuid, java_path: Option<String>) -> Result<()> {
        let mut store = self.store.write().await;
        let inst = store
            .instances
            .get_mut(&id)
            .ok_or(Error::InstanceNotFound(id))?;
        inst.java_path = java_path;
        store.save()
    }

    pub async fn update_instance(&self, id: Uuid, patch: InstancePatch) -> Result<()> {
        let mut store = self.store.write().await;
        let inst = store
            .instances
            .get_mut(&id)
            .ok_or(Error::InstanceNotFound(id))?;
        if let Some(name) = patch.name {
            if name.trim().is_empty() {
                return Err(Error::InvalidInput("name must not be empty".into()));
            }
            inst.name = name;
        }
        let min = patch.min_ram_mb.unwrap_or(inst.min_ram_mb);
        let max = patch.max_ram_mb.unwrap_or(inst.max_ram_mb);
        if min == 0 || min > max {
            return Err(Error::InvalidInput(format!(
                "ram must satisfy 0 < min ({min}) <= max ({max})"
            )));
        }
        inst.min_ram_mb = min;
        inst.max_ram_mb = max;
        if let Some(args) = patch.jvm_args {
            inst.jvm_args = args;
        }
        if let Some(java) = patch.java_path {
            inst.java_path = java;
        }
        store.save()
    }

    pub fn default_properties(&self) -> BTreeMap<String, String> {
        props::default_properties()
            .into_iter()
            .map(|(k, v)| (k.to_string(), v.to_string()))
            .collect()
    }
}

#[derive(Debug, Default)]
pub struct InstancePatch {
    pub name: Option<String>,
    pub min_ram_mb: Option<u32>,
    pub max_ram_mb: Option<u32>,
    pub jvm_args: Option<Vec<String>>,
    pub java_path: Option<Option<String>>,
}
