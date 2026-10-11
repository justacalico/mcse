use crate::models::Instance;
use crate::{paths, Result};
use std::collections::HashMap;
use uuid::Uuid;

/// Persistent registry of all instances, stored as JSON in the data dir.
#[derive(Debug, Default)]
pub struct Store {
    pub instances: HashMap<Uuid, Instance>,
}

impl Store {
    pub fn load() -> Result<Store> {
        let file = paths::registry_file();
        if !file.exists() {
            return Ok(Store::default());
        }
        let raw = std::fs::read_to_string(&file)?;
        let instances: Vec<Instance> = serde_json::from_str(&raw)?;
        Ok(Store {
            instances: instances.into_iter().map(|i| (i.id, i)).collect(),
        })
    }

    pub fn save(&self) -> Result<()> {
        let file = paths::registry_file();
        if let Some(parent) = file.parent() {
            std::fs::create_dir_all(parent)?;
        }
        let mut list: Vec<&Instance> = self.instances.values().collect();
        list.sort_by_key(|i| i.created_at);
        let tmp = file.with_extension("json.tmp");
        std::fs::write(&tmp, serde_json::to_string_pretty(&list)?)?;
        std::fs::rename(tmp, file)?;
        Ok(())
    }

    pub fn insert(&mut self, instance: Instance) -> Result<()> {
        self.instances.insert(instance.id, instance);
        self.save()
    }

    pub fn remove(&mut self, id: Uuid) -> Option<Instance> {
        let removed = self.instances.remove(&id);
        if removed.is_some() {
            let _ = self.save();
        }
        removed
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::LoaderKind;
    use chrono::Utc;
    use std::path::PathBuf;

    fn inst(name: &str) -> Instance {
        Instance {
            id: Uuid::new_v4(),
            name: name.into(),
            loader: LoaderKind::Paper,
            game_version: "1.21.1".into(),
            loader_version: None,
            dir: PathBuf::from("/tmp/x"),
            jar: Some("server.jar".into()),
            java_path: None,
            min_ram_mb: 1024,
            max_ram_mb: 4096,
            jvm_args: vec![],
            created_at: Utc::now(),
        }
    }

    #[test]
    #[serial_test::serial]
    fn roundtrip() {
        let dir = tempfile::tempdir().unwrap();
        std::env::set_var("MCSE_DATA_DIR", dir.path());
        let mut store = Store::load().unwrap();
        let i = inst("a");
        store.insert(i.clone()).unwrap();
        let mut loaded = Store::load().unwrap();
        assert_eq!(loaded.instances[&i.id].name, "a");
        assert!(loaded.remove(i.id).is_some());
        assert!(Store::load().unwrap().instances.is_empty());
        std::env::remove_var("MCSE_DATA_DIR");
    }
}
