use super::{err_not_found, get_json, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;

const API: &str = "https://api.papermc.io/v2/projects/paper";

pub struct Paper;

#[derive(Deserialize)]
struct Project {
    versions: Vec<String>,
}

#[derive(Deserialize)]
struct VersionBuilds {
    builds: Vec<u32>,
}

#[derive(Deserialize)]
struct BuildInfo {
    downloads: Downloads,
}

#[derive(Deserialize)]
struct Downloads {
    application: Application,
}

#[derive(Deserialize)]
struct Application {
    name: String,
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
            .into_iter()
            .rev()
            .map(|id| GameVersion {
                stable: super::is_release_version(&id),
                id,
            })
            .collect();
        versions.retain(|v| v.stable);
        Ok(versions)
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        let builds: VersionBuilds =
            get_json(client, &format!("{API}/versions/{game_version}")).await?;
        let build = builds
            .builds
            .last()
            .copied()
            .ok_or_else(|| err_not_found(game_version))?;
        let info: BuildInfo = get_json(
            client,
            &format!("{API}/versions/{game_version}/builds/{build}"),
        )
        .await?;
        let app = info.downloads.application;
        Ok(ServerArtifact::Jar {
            url: format!(
                "{API}/versions/{game_version}/builds/{build}/downloads/{}",
                app.name
            ),
            filename: app.name,
            sha1: None,
            sha256: Some(app.sha256),
            md5: None,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_project() {
        let p: Project = serde_json::from_str(r#"{"versions":["1.20.4","1.21.1"]}"#).unwrap();
        assert_eq!(p.versions.len(), 2);
    }

    #[test]
    fn parses_build() {
        let b: BuildInfo = serde_json::from_str(
            r#"{"downloads":{"application":{"name":"paper-1.21.1-132.jar","sha256":"aa"}}}"#,
        )
        .unwrap();
        assert_eq!(b.downloads.application.name, "paper-1.21.1-132.jar");
    }
}
