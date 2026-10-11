use std::path::PathBuf;

/// Root data directory for mcse: instances, runtimes, backups, registry.
pub fn data_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("MCSE_DATA_DIR") {
        return PathBuf::from(dir);
    }
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("mcse")
}

pub fn instances_dir() -> PathBuf {
    data_dir().join("instances")
}

pub fn backups_dir() -> PathBuf {
    data_dir().join("backups")
}

pub fn runtimes_dir() -> PathBuf {
    data_dir().join("runtimes")
}

pub fn downloads_dir() -> PathBuf {
    data_dir().join("downloads")
}

pub fn registry_file() -> PathBuf {
    data_dir().join("instances.json")
}
