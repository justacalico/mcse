use crate::frb_generated::StreamSink;
use mcse_core::manager::{CreateRequest, InstancePatch};
use mcse_core::models::{Event, Instance, InstanceStatus, LoaderKind};
use mcse_core::{java, paths, Manager};
use once_cell::sync::OnceCell;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::runtime::Runtime;
use tokio::sync::broadcast;
use uuid::Uuid;

static RT: OnceCell<Runtime> = OnceCell::new();
static MANAGER: OnceCell<Arc<Manager>> = OnceCell::new();

fn rt() -> &'static Runtime {
    RT.get().expect("init_backend must be called first")
}

fn mgr() -> Arc<Manager> {
    MANAGER
        .get()
        .expect("init_backend must be called first")
        .clone()
}

fn parse_id(id: &str) -> Result<Uuid, anyhow::Error> {
    Ok(Uuid::parse_str(id)?)
}

fn parse_loader(raw: &str) -> Result<LoaderKind, anyhow::Error> {
    Ok(serde_json::from_str(&format!("\"{raw}\""))?)
}

// ---------- DTOs (plain data crossing the bridge) ----------

pub struct InstanceDto {
    pub id: String,
    pub name: String,
    pub loader: String,
    pub game_version: String,
    pub dir: String,
    pub jar: Option<String>,
    pub java_path: Option<String>,
    pub min_ram_mb: u32,
    pub max_ram_mb: u32,
    pub jvm_args: Vec<String>,
    pub status: String,
    pub created_at: i64,
}

fn status_name(s: InstanceStatus) -> String {
    serde_json::to_value(s)
        .ok()
        .and_then(|v| v.as_str().map(str::to_string))
        .unwrap_or_else(|| "stopped".into())
}

fn instance_dto(i: &Instance, status: InstanceStatus) -> InstanceDto {
    InstanceDto {
        id: i.id.to_string(),
        name: i.name.clone(),
        loader: serde_json::to_value(i.loader)
            .ok()
            .and_then(|v| v.as_str().map(str::to_string))
            .unwrap_or_else(|| "vanilla".into()),
        game_version: i.game_version.clone(),
        dir: i.dir.to_string_lossy().to_string(),
        jar: i.jar.clone(),
        java_path: i.java_path.clone(),
        min_ram_mb: i.min_ram_mb,
        max_ram_mb: i.max_ram_mb,
        jvm_args: i.jvm_args.clone(),
        status: status_name(status),
        created_at: i.created_at.timestamp(),
    }
}

pub struct GameVersionDto {
    pub id: String,
    pub stable: bool,
}

pub struct JavaRuntimeDto {
    pub path: String,
    pub version: String,
    pub major: u32,
    pub managed: bool,
}

pub struct JavaReleaseDto {
    pub feature: u32,
    pub lts: bool,
}

pub struct BackupDto {
    pub name: String,
    pub size_bytes: u64,
    pub created_at: i64,
}

pub struct PingDto {
    pub motd: String,
    pub online_players: u32,
    pub max_players: u32,
    pub version_name: String,
    pub protocol: i64,
}

pub struct LoaderDto {
    pub kind: String,
    pub label: String,
}

pub struct EventDto {
    pub kind: String,
    pub id: Option<String>,
    pub status: Option<String>,
    pub line: Option<String>,
    pub received: Option<u64>,
    pub total: Option<u64>,
    pub name: Option<String>,
    pub message: Option<String>,
    pub feature: Option<u32>,
    pub stage: Option<String>,
}

fn event_dto(e: &Event) -> EventDto {
    let mut dto = EventDto {
        kind: String::new(),
        id: None,
        status: None,
        line: None,
        received: None,
        total: None,
        name: None,
        message: None,
        feature: None,
        stage: None,
    };
    match e {
        Event::StatusChanged { id, status } => {
            dto.kind = "status".into();
            dto.id = Some(id.to_string());
            dto.status = Some(status_name(*status));
        }
        Event::Log { id, line } => {
            dto.kind = "log".into();
            dto.id = Some(id.to_string());
            dto.line = Some(line.clone());
        }
        Event::DownloadProgress {
            id,
            received,
            total,
        } => {
            dto.kind = "download".into();
            dto.id = Some(id.to_string());
            dto.received = Some(*received);
            dto.total = *total;
        }
        Event::InstanceCreated { id } => {
            dto.kind = "created".into();
            dto.id = Some(id.to_string());
        }
        Event::BackupCreated { id, name } => {
            dto.kind = "backup".into();
            dto.id = Some(id.to_string());
            dto.name = Some(name.clone());
        }
        Event::InstallProgress { id, line } => {
            dto.kind = "install".into();
            dto.id = Some(id.to_string());
            dto.line = Some(line.clone());
        }
        Event::JavaInstall {
            feature,
            stage,
            received,
            total,
        } => {
            dto.kind = "java".into();
            dto.feature = Some(*feature);
            dto.stage = Some(stage.clone());
            dto.received = Some(*received);
            dto.total = *total;
        }
        Event::Fatal { id, message } => {
            dto.kind = "error".into();
            dto.id = id.map(|i| i.to_string());
            dto.message = Some(message.clone());
        }
    }
    dto
}

// ---------- lifecycle ----------

pub fn init_backend(
    data_dir: Option<String>,
    runtimes_dir: Option<String>,
    backups_dir: Option<String>,
) -> Result<(), anyhow::Error> {
    RT.get_or_init(|| Runtime::new().expect("tokio runtime"));
    let non_empty = |s: Option<String>| {
        s.filter(|v| !v.trim().is_empty())
            .map(|v| PathBuf::from(v.trim()))
    };
    let dir = non_empty(data_dir).unwrap_or_else(paths::data_dir);
    let manager = Manager::with_dirs(dir, non_empty(runtimes_dir), non_empty(backups_dir))?;
    MANAGER
        .set(manager)
        .map_err(|_| anyhow::anyhow!("backend already initialized"))
}

pub fn backend_data_dir() -> String {
    mgr().data_dir.to_string_lossy().to_string()
}

pub fn backend_runtimes_dir() -> String {
    mgr().runtimes_dir.to_string_lossy().to_string()
}

pub fn backend_backups_dir() -> String {
    mgr().backups_dir.to_string_lossy().to_string()
}

/// Stream every backend event to Dart.
pub fn subscribe_events(sink: StreamSink<EventDto>) {
    let mut rx = mgr().subscribe();
    rt().spawn(async move {
        loop {
            match rx.recv().await {
                Ok(event) => {
                    let _ = sink.add(event_dto(&event));
                }
                Err(broadcast::error::RecvError::Lagged(_)) => continue,
                Err(broadcast::error::RecvError::Closed) => break,
            }
        }
    });
}

// ---------- loaders & versions ----------

pub fn list_loaders() -> Vec<LoaderDto> {
    LoaderKind::all()
        .iter()
        .map(|k| LoaderDto {
            kind: serde_json::to_value(k)
                .ok()
                .and_then(|v| v.as_str().map(str::to_string))
                .unwrap_or_default(),
            label: k.label().to_string(),
        })
        .collect()
}

pub fn game_versions(loader: String) -> Result<Vec<GameVersionDto>, anyhow::Error> {
    let loader = parse_loader(&loader)?;
    let versions = rt().block_on(mgr().game_versions(loader))?;
    Ok(versions
        .into_iter()
        .map(|v| GameVersionDto {
            id: v.id,
            stable: v.stable,
        })
        .collect())
}

// ---------- instances ----------

/// Kick off a create (download + install) in the background. Returns the
/// new instance id immediately; progress arrives via events.
pub fn create_instance(
    name: String,
    loader: String,
    game_version: String,
    accept_eula: bool,
    min_ram_mb: u32,
    max_ram_mb: u32,
    properties: HashMap<String, String>,
) -> Result<String, anyhow::Error> {
    let loader = parse_loader(&loader)?;
    let manager = mgr();
    let id = Uuid::new_v4();
    let req = CreateRequest {
        id,
        name,
        loader,
        game_version,
        accept_eula,
        min_ram_mb,
        max_ram_mb,
        properties: properties.into_iter().collect(),
    };
    let m = manager.clone();
    rt().spawn(async move {
        if let Err(e) = m.create_instance(req).await {
            m.notify(Event::Fatal {
                id: Some(id),
                message: e.to_string(),
            });
        }
    });
    Ok(id.to_string())
}

pub fn list_instances() -> Vec<InstanceDto> {
    rt().block_on(async {
        mgr()
            .list_instances()
            .await
            .iter()
            .map(|s| instance_dto(&s.instance, s.status))
            .collect()
    })
}

pub fn delete_instance(id: String, remove_files: bool) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().delete_instance(parse_id(&id)?, remove_files))?)
}

pub fn start_instance(id: String) -> Result<(), anyhow::Error> {
    let manager = mgr();
    Ok(rt().block_on(manager.start(parse_id(&id)?))?)
}

pub fn stop_instance(id: String) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().stop(parse_id(&id)?))?)
}

pub fn restart_instance(id: String) -> Result<(), anyhow::Error> {
    let manager = mgr();
    Ok(rt().block_on(manager.restart(parse_id(&id)?))?)
}

pub fn kill_instance(id: String) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().kill(parse_id(&id)?))?)
}

pub fn send_command(id: String, command: String) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().send_command(parse_id(&id)?, &command))?)
}

pub fn recent_log(id: String) -> Result<Vec<String>, anyhow::Error> {
    Ok(rt().block_on(mgr().recent_log(parse_id(&id)?))?)
}

pub fn ping_instance(id: String) -> Result<PingDto, anyhow::Error> {
    let p = rt().block_on(mgr().ping(parse_id(&id)?))?;
    Ok(PingDto {
        motd: p.motd,
        online_players: p.online_players,
        max_players: p.max_players,
        version_name: p.version_name,
        protocol: p.protocol,
    })
}

pub fn update_instance(
    id: String,
    name: Option<String>,
    min_ram_mb: Option<u32>,
    max_ram_mb: Option<u32>,
    jvm_args: Option<Vec<String>>,
) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().update_instance(
        parse_id(&id)?,
        InstancePatch {
            name,
            min_ram_mb,
            max_ram_mb,
            jvm_args,
            java_path: None,
        },
    ))?)
}

/// Tri-state java selection: `Some(path)` pins a runtime, `None` clears it
/// back to auto-detect.
pub fn set_java(id: String, path: Option<String>) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().set_java(parse_id(&id)?, path))?)
}

// ---------- properties ----------

pub fn get_properties(id: String) -> Result<HashMap<String, String>, anyhow::Error> {
    Ok(rt()
        .block_on(mgr().get_properties(parse_id(&id)?))?
        .into_iter()
        .collect())
}

pub fn set_properties(id: String, changes: HashMap<String, String>) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().set_properties(parse_id(&id)?, changes.into_iter().collect()))?)
}

pub fn default_properties() -> HashMap<String, String> {
    mgr().default_properties().into_iter().collect()
}

// ---------- backups ----------

pub fn list_backups(id: String) -> Result<Vec<BackupDto>, anyhow::Error> {
    let backups = rt().block_on(mgr().list_backups(parse_id(&id)?))?;
    Ok(backups
        .into_iter()
        .map(|b| BackupDto {
            name: b.name,
            size_bytes: b.size_bytes,
            created_at: b.created_at.timestamp(),
        })
        .collect())
}

pub fn create_backup(id: String) -> Result<BackupDto, anyhow::Error> {
    let b = rt().block_on(mgr().create_backup(parse_id(&id)?))?;
    Ok(BackupDto {
        name: b.name,
        size_bytes: b.size_bytes,
        created_at: b.created_at.timestamp(),
    })
}

pub fn delete_backup(id: String, name: String) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().delete_backup(parse_id(&id)?, &name))?)
}

pub fn restore_backup(id: String, name: String) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().restore_backup(parse_id(&id)?, &name))?)
}

// ---------- java ----------

pub fn java_runtimes() -> Vec<JavaRuntimeDto> {
    rt().block_on(mgr().runtimes())
        .into_iter()
        .map(|r| JavaRuntimeDto {
            path: r.path.to_string_lossy().to_string(),
            version: r.version,
            major: r.major,
            managed: r.managed,
        })
        .collect()
}

pub fn java_releases() -> Result<Vec<JavaReleaseDto>, anyhow::Error> {
    Ok(rt()
        .block_on(mgr().java_releases())?
        .into_iter()
        .map(|r| JavaReleaseDto {
            feature: r.feature,
            lts: r.lts,
        })
        .collect())
}

pub fn install_java(feature: u32) -> Result<JavaRuntimeDto, anyhow::Error> {
    let r = rt().block_on(mgr().install_java(feature))?;
    Ok(JavaRuntimeDto {
        path: r.path.to_string_lossy().to_string(),
        version: r.version,
        major: r.major,
        managed: r.managed,
    })
}

pub fn remove_java(feature: u32) -> Result<(), anyhow::Error> {
    Ok(rt().block_on(mgr().remove_java(feature))?)
}

pub fn required_java(game_version: String) -> u32 {
    java::required_java(&game_version)
}
