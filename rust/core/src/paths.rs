use std::path::{Path, PathBuf};

/// Default data directory for mcse when none is supplied: `$MCSE_DATA_DIR`
/// or the platform data dir.
pub fn data_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("MCSE_DATA_DIR") {
        return PathBuf::from(dir);
    }
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("mcse")
}

pub fn instances_dir(root: &Path) -> PathBuf {
    root.join("instances")
}

pub fn backups_dir(root: &Path) -> PathBuf {
    root.join("backups")
}

pub fn runtimes_dir(root: &Path) -> PathBuf {
    root.join("runtimes")
}

pub fn downloads_dir(root: &Path) -> PathBuf {
    root.join("downloads")
}

pub fn registry_file(root: &Path) -> PathBuf {
    root.join("instances.json")
}
