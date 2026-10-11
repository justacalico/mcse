use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use uuid::Uuid;

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LoaderKind {
    Vanilla,
    Paper,
    Purpur,
    Fabric,
    Forge,
    NeoForge,
}

impl LoaderKind {
    pub fn all() -> &'static [LoaderKind] {
        &[
            LoaderKind::Vanilla,
            LoaderKind::Paper,
            LoaderKind::Purpur,
            LoaderKind::Fabric,
            LoaderKind::Forge,
            LoaderKind::NeoForge,
        ]
    }

    pub fn label(self) -> &'static str {
        match self {
            LoaderKind::Vanilla => "Vanilla",
            LoaderKind::Paper => "Paper",
            LoaderKind::Purpur => "Purpur",
            LoaderKind::Fabric => "Fabric",
            LoaderKind::Forge => "Forge",
            LoaderKind::NeoForge => "NeoForge",
        }
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct GameVersion {
    pub id: String,
    pub stable: bool,
}

#[derive(Debug, Clone)]
pub enum ServerArtifact {
    /// A directly runnable server jar.
    Jar {
        url: String,
        filename: String,
        sha1: Option<String>,
        sha256: Option<String>,
        md5: Option<String>,
    },
    /// An installer jar that must be executed to produce the server files.
    Installer {
        url: String,
        filename: String,
        sha1: Option<String>,
        args: Vec<String>,
    },
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Instance {
    pub id: Uuid,
    pub name: String,
    pub loader: LoaderKind,
    pub game_version: String,
    pub loader_version: Option<String>,
    pub dir: PathBuf,
    /// Relative path of the runnable jar, or marker file for installer setups.
    pub jar: Option<String>,
    pub java_path: Option<String>,
    pub min_ram_mb: u32,
    pub max_ram_mb: u32,
    pub jvm_args: Vec<String>,
    pub created_at: DateTime<Utc>,
}

impl Instance {
    pub fn jar_path(&self) -> Option<PathBuf> {
        self.jar.as_ref().map(|j| self.dir.join(j))
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum InstanceStatus {
    Stopped,
    Starting,
    Running,
    Stopping,
    Crashed,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InstanceSummary {
    #[serde(flatten)]
    pub instance: Instance,
    pub status: InstanceStatus,
    pub online_players: Option<u32>,
    pub max_players: Option<u32>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JavaRuntime {
    pub path: PathBuf,
    pub version: String,
    pub major: u32,
    /// True when the runtime lives under the managed runtimes dir and was
    /// installed by mcse (so it can be removed again).
    pub managed: bool,
}

/// A Java feature release the Adoptium API offers for download.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct JavaRelease {
    pub feature: u32,
    pub lts: bool,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackupMeta {
    pub name: String,
    pub path: PathBuf,
    pub size_bytes: u64,
    pub created_at: DateTime<Utc>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PingResult {
    pub motd: String,
    pub online_players: u32,
    pub max_players: u32,
    pub version_name: String,
    pub protocol: i64,
    pub favicon: Option<String>,
}

#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum Event {
    StatusChanged {
        id: Uuid,
        status: InstanceStatus,
    },
    Log {
        id: Uuid,
        line: String,
    },
    DownloadProgress {
        id: Uuid,
        received: u64,
        total: Option<u64>,
    },
    InstanceCreated {
        id: Uuid,
    },
    BackupCreated {
        id: Uuid,
        name: String,
    },
    InstallProgress {
        id: Uuid,
        line: String,
    },
    JavaInstall {
        feature: u32,
        stage: String,
        received: u64,
        total: Option<u64>,
    },
    Fatal {
        id: Option<Uuid>,
        message: String,
    },
}
