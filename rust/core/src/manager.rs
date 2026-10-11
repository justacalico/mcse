use crate::loader;
use crate::models::ServerArtifact;
use crate::models::*;
use crate::process::{self, LaunchSpec, ServerHandle};
use crate::props::ServerProperties;
use crate::store::Store;
use crate::{backup, java, paths, ping, props, Error, Result};
use std::collections::BTreeMap;
use std::collections::HashMap;
use std::path::PathBuf;
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
        std::fs::create_dir_all(paths::instances_dir())?;
        std::fs::create_dir_all(paths::backups_dir())?;
        std::fs::create_dir_all(paths::runtimes_dir())?;
        std::fs::create_dir_all(paths::downloads_dir())?;
        let (events, _) = broadcast::channel(2048);
        Ok(Arc::new(Manager {
            data_dir,
            store: RwLock::new(Store::load()?),
            running: RwLock::new(HashMap::new()),
            events,
            http: reqwest::Client::builder()
                .user_agent(concat!("mcse/", env!("CARGO_PKG_VERSION")))
                .build()?,
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
        let dir = paths::instances_dir().join(id.to_string());
        tokio::fs::create_dir_all(&dir).await?;

        let provider = loader::provider(req.loader);
        let artifact = provider.resolve(&self.http, &req.game_version).await?;
        let (url, filename, sha1, sha256, installer) = match artifact {
            ServerArtifact::Jar {
                url,
                filename,
                sha1,
                sha256,
            } => (url, filename, sha1, sha256, None),
            ServerArtifact::Installer {
                url,
                filename,
                sha1,
                args,
            } => (url, filename, sha1, None, Some(args)),
        };

        let jar_path = dir.join(&filename);
        let events = self.events.clone();
        let progress_id = id;
        crate::download::download(
            &self.http,
            &url,
            &jar_path,
            sha1.as_deref(),
            sha256.as_deref(),
            move |received, total| {
                let _ = events.send(Event::DownloadProgress {
                    id: progress_id,
                    received,
                    total,
                });
            },
        )
        .await?;

        let mut jar = Some(filename.clone());
        if let Some(args) = installer {
            self.run_installer(id, &dir, &jar_path, &args).await?;
            let _ = tokio::fs::remove_file(&jar_path).await;
            jar = process::find_server_jar(&dir);
        }

        tokio::fs::write(dir.join("eula.txt"), "eula=true\n").await?;
        ServerProperties::update_file(&dir.join("server.properties"), &req.properties)?;

        let instance = Instance {
            id,
            name: req.name,
            loader: req.loader,
            game_version: req.game_version.clone(),
            loader_version: None,
            dir,
            jar,
            java_path: None,
            min_ram_mb: req.min_ram_mb,
            max_ram_mb: req.max_ram_mb,
            jvm_args: vec![],
            created_at: chrono::Utc::now(),
        };
        self.store.write().await.insert(instance)?;
        let _ = self.events.send(Event::InstanceCreated { id });
        Ok(id)
    }

    async fn run_installer(
        &self,
        id: Uuid,
        dir: &std::path::Path,
        jar: &std::path::Path,
        args: &[String],
    ) -> Result<()> {
        let runtimes = java::detect_runtimes().await;
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
        if let Some(out) = child.stdout.take() {
            let events = events.clone();
            tokio::spawn(async move {
                use tokio::io::{AsyncBufReadExt, BufReader};
                let mut lines = BufReader::new(out).lines();
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
        let inst = self
            .store
            .write()
            .await
            .remove(id)
            .ok_or(Error::InstanceNotFound(id))?;
        if remove_files {
            let _ = tokio::fs::remove_dir_all(&inst.dir).await;
            let backup_dir = paths::backups_dir().join(id.to_string());
            let _ = tokio::fs::remove_dir_all(&backup_dir).await;
        }
        Ok(())
    }

    async fn launch_spec(&self, inst: &Instance) -> Result<LaunchSpec> {
        let required = java::required_java(&inst.game_version);
        let java_path = match &inst.java_path {
            Some(p) => PathBuf::from(p),
            None => {
                let runtimes = java::detect_runtimes().await;
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
        if self.running.read().await.contains_key(&id) {
            return Err(Error::AlreadyRunning(id));
        }
        let spec = self.launch_spec(&inst).await?;
        let handle = process::spawn(spec, id, self.events.clone()).await?;
        self.running.write().await.insert(id, handle);
        let _ = self.events.send(Event::StatusChanged {
            id,
            status: InstanceStatus::Starting,
        });
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
        backup::list(&inst).await
    }

    pub async fn create_backup(&self, id: Uuid) -> Result<BackupMeta> {
        let inst = self.instance(id).await?;
        let meta = backup::create(&inst).await?;
        let _ = self.events.send(Event::BackupCreated {
            id,
            name: meta.name.clone(),
        });
        Ok(meta)
    }

    pub async fn delete_backup(&self, id: Uuid, name: &str) -> Result<()> {
        let inst = self.instance(id).await?;
        backup::remove(&inst, name).await
    }

    pub async fn restore_backup(self: &Arc<Self>, id: Uuid, name: &str) -> Result<()> {
        let inst = self.instance(id).await?;
        if self.running.read().await.contains_key(&id) {
            self.stop_internal(id, true).await;
            self.reap(id).await;
        }
        backup::restore(&inst, name).await
    }

    /// Server-list ping to 127.0.0.1 on the configured port.
    pub async fn ping(&self, id: Uuid) -> Result<PingResult> {
        let inst = self.instance(id).await?;
        let props = ServerProperties::load(&inst.dir.join("server.properties"))?;
        let port = props.get_u16("server-port", 25565);
        ping::ping("127.0.0.1", port, Duration::from_secs(3)).await
    }

    pub async fn runtimes(&self) -> Vec<JavaRuntime> {
        java::detect_runtimes().await
    }

    pub async fn install_java(&self, feature: u32) -> Result<JavaRuntime> {
        java::install_temurin(&self.http, feature, |line| {
            tracing::info!(line);
        })
        .await
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
            inst.name = name;
        }
        if let Some(min) = patch.min_ram_mb {
            inst.min_ram_mb = min;
        }
        if let Some(max) = patch.max_ram_mb {
            inst.max_ram_mb = max;
        }
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
