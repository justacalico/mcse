use crate::{Error, Result};
use std::collections::BTreeMap;
use std::path::Path;

/// A parsed `server.properties` file that preserves comments and ordering.
#[derive(Debug, Default)]
pub struct ServerProperties {
    pub map: BTreeMap<String, String>,
}

impl ServerProperties {
    pub fn parse(text: &str) -> ServerProperties {
        let mut map = BTreeMap::new();
        for line in text.lines() {
            let line = line.trim();
            if line.is_empty() || line.starts_with('#') || line.starts_with('!') {
                continue;
            }
            if let Some((k, v)) = line.split_once('=') {
                map.insert(k.trim().to_string(), v.trim().to_string());
            }
        }
        ServerProperties { map }
    }

    pub fn load(path: &Path) -> Result<ServerProperties> {
        if !path.exists() {
            return Ok(ServerProperties::default());
        }
        Ok(ServerProperties::parse(&std::fs::read_to_string(path)?))
    }

    pub fn get(&self, key: &str) -> Option<&str> {
        self.map.get(key).map(String::as_str)
    }

    pub fn get_u16(&self, key: &str, default: u16) -> u16 {
        self.get(key)
            .and_then(|v| v.parse().ok())
            .unwrap_or(default)
    }

    pub fn set(&mut self, key: &str, value: &str) {
        self.map.insert(key.to_string(), value.to_string());
    }

    /// A property key/value may not contain line breaks or `=` in the key;
    /// anything else would inject extra property lines into the file.
    fn sanitize(key: &str, value: &str) -> Result<(String, String)> {
        let key = key.trim();
        if key.is_empty() || key.contains(['\n', '\r', '=']) || value.contains(['\n', '\r']) {
            return Err(Error::InvalidInput(format!(
                "illegal property entry {key:?}"
            )));
        }
        Ok((key.to_string(), value.to_string()))
    }

    /// Merge `changes` into the existing file, preserving untouched keys and
    /// any comments that were already present.
    pub fn update_file(path: &Path, changes: &BTreeMap<String, String>) -> Result<()> {
        let existing = if path.exists() {
            std::fs::read_to_string(path)?
        } else {
            String::new()
        };
        let changes: BTreeMap<String, String> = changes
            .iter()
            .map(|(k, v)| Self::sanitize(k, v))
            .collect::<Result<_>>()?;
        let mut out = String::new();
        let mut seen = std::collections::HashSet::new();
        for line in existing.lines() {
            let trimmed = line.trim();
            if trimmed.is_empty() || trimmed.starts_with('#') || trimmed.starts_with('!') {
                out.push_str(line);
                out.push('\n');
                continue;
            }
            if let Some((k, _)) = line.split_once('=') {
                let k = k.trim();
                if let Some(v) = changes.get(k) {
                    out.push_str(k);
                    out.push('=');
                    out.push_str(v);
                    out.push('\n');
                    seen.insert(k.to_string());
                    continue;
                }
            }
            out.push_str(line);
            out.push('\n');
        }
        for (k, v) in &changes {
            if !seen.contains(k) {
                out.push_str(k);
                out.push('=');
                out.push_str(v);
                out.push('\n');
            }
        }
        let tmp = path.with_extension("properties.tmp");
        std::fs::write(&tmp, out)?;
        std::fs::rename(tmp, path)?;
        Ok(())
    }

    pub fn to_text(&self) -> String {
        let mut out = String::from("#Minecraft server properties\n");
        for (k, v) in &self.map {
            out.push_str(k);
            out.push('=');
            out.push_str(v);
            out.push('\n');
        }
        out
    }
}

pub fn default_properties() -> BTreeMap<&'static str, &'static str> {
    BTreeMap::from([
        ("server-port", "25565"),
        ("motd", "A Minecraft Server"),
        ("max-players", "20"),
        ("online-mode", "true"),
        ("difficulty", "normal"),
        ("gamemode", "survival"),
        ("pvp", "true"),
        ("spawn-protection", "16"),
        ("view-distance", "10"),
        ("simulation-distance", "10"),
        ("white-list", "false"),
        ("enable-command-block", "false"),
    ])
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_basic() {
        let p = ServerProperties::parse("# comment\nserver-port=25565\nmotd=hi there\n\n");
        assert_eq!(p.get("server-port"), Some("25565"));
        assert_eq!(p.get("motd"), Some("hi there"));
        assert_eq!(p.get_u16("server-port", 0), 25565);
        assert_eq!(p.get_u16("missing", 7), 7);
    }

    #[test]
    fn update_preserves_comments() {
        let dir = tempfile::tempdir().unwrap();
        let f = dir.path().join("server.properties");
        std::fs::write(&f, "# my comment\nserver-port=25565\nmotd=old\n").unwrap();
        let changes = BTreeMap::from([
            ("motd".to_string(), "new".to_string()),
            ("pvp".to_string(), "false".to_string()),
        ]);
        ServerProperties::update_file(&f, &changes).unwrap();
        let text = std::fs::read_to_string(&f).unwrap();
        assert!(text.contains("# my comment"));
        assert!(text.contains("server-port=25565"));
        assert!(text.contains("motd=new"));
        assert!(text.contains("pvp=false"));
    }

    #[test]
    fn roundtrip_text() {
        let mut p = ServerProperties::default();
        p.set("a", "1");
        let p2 = ServerProperties::parse(&p.to_text());
        assert_eq!(p2.get("a"), Some("1"));
    }

    #[test]
    fn rejects_line_injection() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("server.properties");
        let mut bad = std::collections::BTreeMap::new();
        bad.insert("motd".to_string(), "hi\nonline-mode=false".to_string());
        assert!(ServerProperties::update_file(&path, &bad).is_err());
        let mut bad_key = std::collections::BTreeMap::new();
        bad_key.insert("a=b".to_string(), "1".to_string());
        assert!(ServerProperties::update_file(&path, &bad_key).is_err());
    }
}
