use super::{err_not_found, get_json, version_tuple, LoaderProvider};
use crate::models::{GameVersion, LoaderKind, ServerArtifact};
use crate::Result;
use async_trait::async_trait;
use serde::Deserialize;
use std::collections::BTreeMap;

const FORGE_PROMOS: &str =
    "https://files.minecraftforge.net/net/minecraftforge/forge/promotions_slim.json";
const NEOFORGE_META: &str =
    "https://maven.neoforged.net/releases/net/neoforged/neoforge/maven-metadata.xml";

/// Forge and NeoForge share the same shape: an installer jar that is run
/// with `--installServer` to produce the server files.
pub struct Forge {
    pub neoforge: bool,
}

#[derive(Deserialize)]
struct Promos {
    promos: BTreeMap<String, String>,
}

impl Forge {
    /// Forge promotions look like `"1.20.1-recommended" -> "47.2.0"`.
    fn forge_versions(promos: &Promos) -> Vec<(String, String)> {
        let mut out: Vec<(String, String)> = vec![];
        for (key, forge) in &promos.promos {
            if let Some(mc) = key.strip_suffix("-recommended") {
                out.push((mc.to_string(), forge.clone()));
            }
        }
        // Fill gaps with -latest where no recommended exists.
        for (key, forge) in &promos.promos {
            if let Some(mc) = key.strip_suffix("-latest") {
                if !out.iter().any(|(m, _)| m == mc) {
                    out.push((mc.to_string(), forge.clone()));
                }
            }
        }
        out
    }

    fn neoforge_game_version(neoforge_version: &str) -> Option<String> {
        // NeoForge versions look like "21.1.72" -> MC "1.21.1", or
        // "20.4.237" -> MC "1.20.4", "21.0.167" -> MC "1.21".
        let mut parts = neoforge_version.split('.');
        let major: u32 = parts.next()?.parse().ok()?;
        let minor: u32 = parts.next()?.parse().ok()?;
        if major == 20 {
            Some(format!("1.20.{minor}"))
        } else if minor == 0 {
            Some(format!("1.{major}"))
        } else {
            Some(format!("1.{major}.{minor}"))
        }
    }
}

#[async_trait]
impl LoaderProvider for Forge {
    fn kind(&self) -> LoaderKind {
        if self.neoforge {
            LoaderKind::NeoForge
        } else {
            LoaderKind::Forge
        }
    }

    async fn game_versions(&self, client: &reqwest::Client) -> Result<Vec<GameVersion>> {
        if self.neoforge {
            let text = client
                .get(NEOFORGE_META)
                .send()
                .await?
                .error_for_status()?
                .text()
                .await?;
            let mut versions: Vec<String> = vec![];
            for line in text.lines() {
                let line = line.trim();
                if line.starts_with("<version>") && line.ends_with("</version>") {
                    versions.push(line[9..line.len() - 10].to_string());
                }
            }
            let mut games: Vec<String> = versions
                .iter()
                .filter_map(|v| Self::neoforge_game_version(v))
                .collect();
            games.sort_by_key(|v| version_tuple(v).unwrap_or((0, 0, 0)));
            games.dedup();
            games.reverse();
            Ok(games
                .into_iter()
                .map(|id| GameVersion { id, stable: true })
                .collect())
        } else {
            let promos: Promos = get_json(client, FORGE_PROMOS).await?;
            let mut pairs = Self::forge_versions(&promos);
            pairs.sort_by_key(|(mc, _)| version_tuple(mc).unwrap_or((0, 0, 0)));
            pairs.reverse();
            Ok(pairs
                .into_iter()
                .map(|(id, _)| GameVersion { id, stable: true })
                .collect())
        }
    }

    async fn resolve(
        &self,
        client: &reqwest::Client,
        game_version: &str,
    ) -> Result<ServerArtifact> {
        if self.neoforge {
            let text = client
                .get(NEOFORGE_META)
                .send()
                .await?
                .error_for_status()?
                .text()
                .await?;
            let wanted_prefix = match Self::neoforge_game_version_to_prefix(game_version) {
                Some(p) => p,
                None => return Err(err_not_found(game_version)),
            };
            let mut best: Option<String> = None;
            for line in text.lines() {
                let line = line.trim();
                if line.starts_with("<version>") && line.ends_with("</version>") {
                    let v = &line[9..line.len() - 10];
                    if v.starts_with(&wanted_prefix) {
                        best = Some(v.to_string());
                    }
                }
            }
            let neo = best.ok_or_else(|| err_not_found(game_version))?;
            Ok(ServerArtifact::Installer {
                url: format!(
                    "https://maven.neoforged.net/releases/net/neoforged/neoforge/{neo}/neoforge-{neo}-installer.jar"
                ),
                filename: format!("neoforge-{neo}-installer.jar"),
                sha1: None,
                args: vec!["--installServer".to_string(), ".".to_string()],
            })
        } else {
            let promos: Promos = get_json(client, FORGE_PROMOS).await?;
            let pairs = Self::forge_versions(&promos);
            let (_, forge) = pairs
                .into_iter()
                .find(|(mc, _)| mc == game_version)
                .ok_or_else(|| err_not_found(game_version))?;
            // Forge maven versions are "<mc>-<forge>" (older ones have an
            // extra "-<mc>" suffix, handled by trying the plain form first —
            // the promos data only covers versions that use the plain form).
            let full = format!("{game_version}-{forge}");
            Ok(ServerArtifact::Installer {
                url: format!(
                    "https://maven.minecraftforge.net/net/minecraftforge/forge/{full}/forge-{full}-installer.jar"
                ),
                filename: format!("forge-{full}-installer.jar"),
                sha1: None,
                args: vec!["--installServer".to_string(), ".".to_string()],
            })
        }
    }
}

impl Forge {
    fn neoforge_game_version_to_prefix(game_version: &str) -> Option<String> {
        // "1.21.1" -> "21.1.", "1.21" -> "21.0.", "1.20.4" -> "20.4."
        let (major, minor, patch) = version_tuple(game_version)?;
        if major != 1 {
            return None;
        }
        if minor == 20 {
            Some(format!("20.{patch}."))
        } else if patch == 0
            && !game_version.ends_with(".0")
            && game_version.matches('.').count() == 1
        {
            Some(format!("{minor}.0."))
        } else {
            Some(format!("{minor}.{patch}."))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn forge_pairs() {
        let promos: Promos = serde_json::from_str(
            r#"{"promos":{"1.20.1-latest":"47.3.0","1.20.1-recommended":"47.2.0","1.19.4-latest":"45.2.0"}}"#,
        )
        .unwrap();
        let pairs = Forge::forge_versions(&promos);
        assert!(pairs.contains(&("1.20.1".into(), "47.2.0".into())));
        assert!(pairs.contains(&("1.19.4".into(), "45.2.0".into())));
        assert_eq!(pairs.iter().filter(|(m, _)| m == "1.20.1").count(), 1);
    }

    #[test]
    fn neoforge_map() {
        assert_eq!(
            Forge::neoforge_game_version("21.1.72"),
            Some("1.21.1".into())
        );
        assert_eq!(
            Forge::neoforge_game_version("20.4.237"),
            Some("1.20.4".into())
        );
        assert_eq!(
            Forge::neoforge_game_version("21.0.167"),
            Some("1.21".into())
        );
        assert_eq!(
            Forge::neoforge_game_version_to_prefix("1.21.1"),
            Some("21.1.".into())
        );
        assert_eq!(
            Forge::neoforge_game_version_to_prefix("1.20.4"),
            Some("20.4.".into())
        );
        assert_eq!(
            Forge::neoforge_game_version_to_prefix("1.21"),
            Some("21.0.".into())
        );
    }
}
