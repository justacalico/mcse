use crate::models::Instance;
use crate::{paths, Result};
use std::collections::HashMap;
use std::path::PathBuf;
use uuid::Uuid;

/// Persistent registry of all instances, stored as JSON under the data dir.
#[derive(Debug)]
pub struct Store {
    pub instances: HashMap<Uuid, Instance>,
    root: PathBuf,
}

impl Store {
    pub fn load(root: &std::path::Path) -> Result<Store> {
        let file = paths::registry_file(root);
        if !file.exists() {
            return Ok(Store {
                instances: HashMap::new(),
                root: root.to_path_buf(),
            });
        }
        let raw = std::fs::read_to_string(&file)?;
        let instances: Vec<Instance> = serde_json::from_str(&raw)?;
        Ok(Store {
            instances: instances.into_iter().map(|i| (i.id, i)).collect(),
            root: root.to_path_buf(),
        })
    }

    pub fn save(&self) -> Result<()> {
        let file = paths::registry_file(&self.root);
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
        let id = instance.id;
        let prev = self.instances.insert(id, instance);
        if let Err(e) = self.save() {
            match prev {
                Some(p) => self.instances.insert(id, p),
                None => self.instances.remove(&id),
            };
            return Err(e);
        }
        Ok(())
    }

    pub fn remove(&mut self, id: Uuid) -> Result<Option<Instance>> {
        let removed = self.instances.remove(&id);
        if let Some(inst) = &removed {
            if let Err(e) = self.save() {
                self.instances.insert(id, inst.clone());
                return Err(e);
            }
        }
        Ok(removed)
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
    fn roundtrip() {
        let dir = tempfile::tempdir().unwrap();
        let mut store = Store::load(dir.path()).unwrap();
        let i = inst("a");
        store.insert(i.clone()).unwrap();
        let mut loaded = Store::load(dir.path()).unwrap();
        assert_eq!(loaded.instances[&i.id].name, "a");
        assert!(loaded.remove(i.id).unwrap().is_some());
        assert!(Store::load(dir.path()).unwrap().instances.is_empty());
    }
}
