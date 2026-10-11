use super::{err_not_found, get_json, is_release_version, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;

const MANIFEST: &str = "https://piston-meta.mojang.com/mc/game/version_manifest_v2.json";

pub struct Vanilla;

#[derive(Deserialize)]
struct Manifest {
    versions: Vec<ManifestEntry>,
}

#[derive(Deserialize)]
struct ManifestEntry {
    id: String,
    #[serde(rename = "type")]
    kind: String,
    url: String,
}

#[derive(Deserialize)]
struct VersionMeta {
    downloads: Downloads,
}

#[derive(Deserialize)]
struct Downloads {
    server: Option<ServerDownload>,
}

#[derive(Deserialize)]
struct ServerDownload {
    sha1: String,
    url: String,
}

#[async_trait]
impl LoaderProvider for Vanilla {
    fn kind(&self) -> LoaderKind {
        LoaderKind::Vanilla
    }

    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>> {
        let manifest: Manifest = get_json(client, MANIFEST).await?;
        Ok(manifest
            .versions
            .into_iter()
            .map(|v| GameVersion {
                stable: v.kind == "release" && is_release_version(&v.id),
                id: v.id,
            })
            .collect())
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        let manifest: Manifest = get_json(client, MANIFEST).await?;
        let entry = manifest
            .versions
            .into_iter()
            .find(|v| v.id == game_version)
            .ok_or_else(|| err_not_found(game_version))?;
        let meta: VersionMeta = get_json(client, &entry.url).await?;
        let server = meta
            .downloads
            .server
            .ok_or_else(|| err_not_found(game_version))?;
        Ok(ServerArtifact::Jar {
            url: server.url,
            filename: format!("minecraft-server-{game_version}.jar"),
            sha1: Some(server.sha1),
            sha256: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_manifest() {
        let json = r#"{"latest":{"release":"1.21.1"},"versions":[
            {"id":"1.21.1","type":"release","url":"https://x/1.json"},
            {"id":"24w01a","type":"snapshot","url":"https://x/2.json"}]}"#;
        let m: Manifest = serde_json::from_str(json).unwrap();
        assert_eq!(m.versions.len(), 2);
        assert_eq!(m.versions[0].kind, "release");
    }

    #[test]
    fn parses_version_meta() {
        let json = r#"{"downloads":{"server":{"sha1":"abc","size":1,"url":"https://x/s.jar"}}}"#;
        let m: VersionMeta = serde_json::from_str(json).unwrap();
        assert_eq!(m.downloads.server.unwrap().sha1, "abc");
    }
}
