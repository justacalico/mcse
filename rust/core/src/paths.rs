use std::path::{Path, PathBuf};

/// Default data directory for mcse when none is supplied: `$MCSE_DATA_DIR`
/// or the platform data dir.
pub fn data_dir() -> PathBuf {
    if let Ok(dir) = std::env::var("MCSE_DATA_DIR").map(|v| v.trim().to_string()) {
        if !dir.is_empty() {
            return PathBuf::from(dir);
        }
    }
    dirs::data_dir()
        .unwrap_or_else(|| PathBuf::from("."))
        .join("mcse")
}

/// Resolve a configurable directory: an explicit argument wins over the
/// env var, which wins over `default`.
pub fn configured_dir(explicit: Option<PathBuf>, env_var: &str, default: PathBuf) -> PathBuf {
    explicit
        .filter(|p| !p.as_os_str().is_empty())
        .or_else(|| {
            std::env::var(env_var)
                .ok()
                .filter(|v| !v.trim().is_empty())
                .map(|v| PathBuf::from(v.trim()))
        })
        .unwrap_or(default)
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn configured_dir_prefers_explicit() {
        let dir = configured_dir(
            Some(PathBuf::from("/explicit")),
            "MCSE_TEST_CONFIGURED_DIR_A",
            PathBuf::from("/default"),
        );
        assert_eq!(dir, PathBuf::from("/explicit"));
    }

    #[test]
    fn configured_dir_uses_env_then_default() {
        let var = "MCSE_TEST_CONFIGURED_DIR_B";
        std::env::set_var(var, "/from-env");
        assert_eq!(
            configured_dir(None, var, PathBuf::from("/default")),
            PathBuf::from("/from-env")
        );
        std::env::remove_var(var);
        assert_eq!(
            configured_dir(None, var, PathBuf::from("/default")),
            PathBuf::from("/default")
        );
    }
}
