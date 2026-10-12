use super::{err_not_found, get_json, version_tuple, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;
use std::collections::HashMap;

const API: &str = "https://fill.papermc.io/v3/projects/paper";

pub struct Paper;

#[derive(Deserialize)]
struct Project {
    versions: HashMap<String, Vec<String>>,
}

#[derive(Deserialize)]
struct Build {
    downloads: Downloads,
}

#[derive(Deserialize)]
struct Downloads {
    #[serde(rename = "server:default")]
    server: Download,
}

#[derive(Deserialize)]
struct Download {
    name: String,
    url: String,
    checksums: Checksums,
}

#[derive(Deserialize)]
struct Checksums {
    sha256: String,
}

#[async_trait]
impl LoaderProvider for Paper {
    fn kind(&self) -> LoaderKind {
        LoaderKind::Paper
    }

    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>> {
        let project: Project = get_json(client, API).await?;
        let mut versions: Vec<GameVersion> = project
            .versions
            .into_values()
            .flatten()
            .map(|id| GameVersion {
                stable: super::is_release_version(&id),
                id,
            })
            .collect();
        versions.retain(|v| v.stable);
        versions.sort_by_key(|v| version_tuple(&v.id).unwrap_or((0, 0, 0)));
        versions.reverse();
        Ok(versions)
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        let builds: Vec<Build> =
            get_json(client, &format!("{API}/versions/{game_version}/builds")).await?;
        let app = builds
            .into_iter()
            .next()
            .ok_or_else(|| err_not_found(game_version))?
            .downloads
            .server;
        Ok(ServerArtifact::Jar {
            url: app.url,
            filename: app.name,
            sha1: None,
            sha256: Some(app.checksums.sha256),
            md5: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_project() {
        let p: Project = serde_json::from_str(
            r#"{"versions":{"1.21":["1.21.11","1.21.11-rc1"],"1.20":["1.20.4"]}}"#,
        )
        .unwrap();
        assert_eq!(p.versions["1.21"].len(), 2);
    }

    #[test]
    fn parses_builds() {
        let b: Vec<Build> = serde_json::from_str(
            r#"[{"id":132,"downloads":{"server:default":{"name":"paper-1.21.11-132.jar","url":"https://x/paper.jar","checksums":{"sha256":"aa"}}}}]"#,
        )
        .unwrap();
        assert_eq!(b[0].downloads.server.name, "paper-1.21.11-132.jar");
        assert_eq!(b[0].downloads.server.checksums.sha256, "aa");
    }
}
