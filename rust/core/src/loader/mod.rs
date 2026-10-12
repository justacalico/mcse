mod fabric;
mod forge;
mod paper;
mod purpur;
mod vanilla;

use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::{Error, Result};
use async_trait::async_trait;

#[async_trait]
pub trait LoaderProvider: Send + Sync {
    fn kind(&self) -> LoaderKind;
    /// All game versions this loader can serve, newest first.
    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>>;
    /// Resolve a concrete downloadable artifact for a game version.
    async fn resolve(&self, client: &reqwest::Client, game_version: &str)
        -> Result<ServerArtifact>;
}

pub fn provider(kind: LoaderKind) -> Box<dyn LoaderProvider> {
    match kind {
        LoaderKind::Vanilla => Box::new(vanilla::Vanilla),
        LoaderKind::Paper => Box::new(paper::Paper),
        LoaderKind::Purpur => Box::new(purpur::Purpur),
        LoaderKind::Fabric => Box::new(fabric::Fabric),
        LoaderKind::Forge => Box::new(forge::Forge { neoforge: false }),
        LoaderKind::NeoForge => Box::new(forge::Forge { neoforge: true }),
    }
}

/// Parse "1.20.4" into (1, 20, 4). Missing components are 0.
/// Non-numeric versions (snapshots) return None.
pub fn version_tuple(v: &str) -> Option<(u32, u32, u32)> {
    let mut it = v.split('.');
    let a = it.next()?.parse().ok()?;
    let b = it.next().unwrap_or("0").parse().ok()?;
    let c = it.next().unwrap_or("0").parse().ok()?;
    Some((a, b, c))
}

pub fn is_release_version(v: &str) -> bool {
    version_tuple(v).is_some()
}

pub(crate) async fn get_json<T: serde::de::DeserializeOwned>(
    client: &reqwest::Client,
    url: &str,
) -> Result<T> {
    let resp = client.get(url).send().await?.error_for_status()?;
    Ok(resp.json().await?)
}

pub(crate) fn err_not_found(v: &str) -> Error {
    Error::VersionNotFound(v.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn tuples() {
        assert_eq!(version_tuple("1.20.4"), Some((1, 20, 4)));
        assert_eq!(version_tuple("1.19"), Some((1, 19, 0)));
        assert_eq!(version_tuple("24w01a"), None);
        assert!(is_release_version("1.21.1"));
        assert!(is_release_version("26.3"));
        assert!(!is_release_version("24w14potato"));
        assert!(!is_release_version("1.21.11-rc3"));
    }
}
