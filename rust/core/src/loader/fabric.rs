use super::{err_not_found, get_json, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;

const META: &str = "https://meta.fabricmc.net/v2/versions";

pub struct Fabric;

#[derive(Deserialize)]
struct MetaVersion {
    version: String,
    stable: bool,
}

#[async_trait]
impl LoaderProvider for Fabric {
    fn kind(&self) -> LoaderKind {
        LoaderKind::Fabric
    }

    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>> {
        let versions: Vec<MetaVersion> = get_json(client, &format!("{META}/game")).await?;
        Ok(versions
            .into_iter()
            .map(|v| GameVersion {
                id: v.version,
                stable: v.stable,
            })
            .collect())
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        let loaders: Vec<MetaVersion> =
            get_json(client, &format!("{META}/loader/{game_version}")).await?;
        let loader = loaders
            .first()
            .map(|l| l.version.clone())
            .ok_or_else(|| err_not_found(game_version))?;
        let installers: Vec<MetaVersion> = get_json(client, &format!("{META}/installer")).await?;
        let installer = installers
            .first()
            .map(|i| i.version.clone())
            .ok_or_else(|| err_not_found(game_version))?;
        Ok(ServerArtifact::Jar {
            url: format!("{META}/loader/{game_version}/{loader}/{installer}/server/jar"),
            filename: format!("fabric-server-{game_version}-{loader}.jar"),
            sha1: None,
            sha256: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_meta() {
        let v: Vec<MetaVersion> =
            serde_json::from_str(r#"[{"version":"1.21.1","stable":true}]"#).unwrap();
        assert_eq!(v[0].version, "1.21.1");
    }
}
