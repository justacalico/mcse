use std::path::PathBuf;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),
    #[error("http error: {0}")]
    Http(#[from] reqwest::Error),
    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),
    #[error("zip error: {0}")]
    Zip(#[from] zip::result::ZipError),
    #[error("task join error: {0}")]
    Join(#[from] tokio::task::JoinError),
    #[error("instance not found: {0}")]
    InstanceNotFound(uuid::Uuid),
    #[error("instance already running: {0}")]
    AlreadyRunning(uuid::Uuid),
    #[error("instance not running: {0}")]
    NotRunning(uuid::Uuid),
    #[error("unknown loader: {0}")]
    UnknownLoader(String),
    #[error("version not found: {0}")]
    VersionNotFound(String),
    #[error("checksum mismatch for {0}")]
    Checksum(PathBuf),
    #[error("no usable java runtime (need java {required}, have: {have})")]
    NoJava { required: u32, have: String },
    #[error("backup not found: {0}")]
    BackupNotFound(String),
    #[error("installer failed: {0}")]
    Installer(String),
    #[error("{0}")]
    Msg(String),
}

pub type Result<T> = std::result::Result<T, Error>;
