use super::{get_json, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;

const API: &str = "https://api.purpurmc.org/v2/purpur";

pub struct Purpur;

#[derive(Deserialize)]
struct Project {
    versions: Vec<String>,
}

#[derive(Deserialize)]
struct VersionInfo {
    builds: Builds,
}

#[derive(Deserialize)]
struct Builds {
    latest: String,
}

#[derive(Deserialize)]
struct BuildMeta {
    md5: Option<String>,
}

#[async_trait]
impl LoaderProvider for Purpur {
    fn kind(&self) -> LoaderKind {
        LoaderKind::Purpur
    }

    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>> {
        let project: Project = get_json(client, API).await?;
        Ok(project
            .versions
            .into_iter()
            .rev()
            .map(|id| GameVersion {
                stable: super::is_release_version(&id),
                id,
            })
            .collect())
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        let info: VersionInfo = get_json(client, &format!("{API}/{game_version}")).await?;
        let build = &info.builds.latest;
        let meta: BuildMeta = get_json(client, &format!("{API}/{game_version}/{build}")).await?;
        Ok(ServerArtifact::Jar {
            url: format!("{API}/{game_version}/{build}/download"),
            filename: format!("purpur-{game_version}-{build}.jar"),
            sha1: None,
            md5: meta.md5,
            sha256: None,
        })
    }
}
