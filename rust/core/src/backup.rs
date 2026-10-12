use crate::models::{BackupMeta, Instance};
use crate::{Error, Result};
use chrono::Utc;
use std::path::{Path, PathBuf};

/// Entries inside an instance dir that are never worth backing up.
const EXCLUDED: &[&str] = &["logs", "cache", "crash-reports", "tmp", ".jars"];

fn backup_root(backups_dir: &Path, instance: &Instance) -> PathBuf {
    backups_dir.join(instance.id.to_string())
}

/// Everything in the instance dir minus caches/logs — a modded instance
/// needs its mods, configs and libraries to restore correctly.
fn included(dir: &Path) -> Vec<PathBuf> {
    let mut out = vec![];
    if let Ok(rd) = std::fs::read_dir(dir) {
        for e in rd.flatten() {
            let name = e.file_name().to_string_lossy().to_string();
            if !EXCLUDED.contains(&name.as_str()) && !name.ends_with(".part") {
                out.push(e.path());
            }
        }
    }
    out
}

pub async fn create(backups_dir: &Path, instance: &Instance) -> Result<BackupMeta> {
    let root = backup_root(backups_dir, instance);
    tokio::fs::create_dir_all(&root).await?;
    let mut name = format!("backup-{}.zip", Utc::now().format("%Y%m%d-%H%M%S"));
    for i in 2.. {
        if !root.join(&name).exists() {
            break;
        }
        name = format!("backup-{}-{i}.zip", Utc::now().format("%Y%m%d-%H%M%S"));
    }
    let path = root.join(&name);
    let dir = instance.dir.clone();
    let path_c = path.clone();
    let name_c = name.clone();
    tokio::task::spawn_blocking(move || zip_dir(&dir, &path_c).map(|_| name_c)).await??;
    let size = tokio::fs::metadata(&path).await?.len();
    Ok(BackupMeta {
        name,
        path,
        size_bytes: size,
        created_at: Utc::now(),
    })
}

fn zip_dir(dir: &Path, dest: &Path) -> Result<()> {
    let file = std::fs::File::create(dest)?;
    let mut zip = zip::ZipWriter::new(file);
    let opts = zip::write::SimpleFileOptions::default()
        .compression_method(zip::CompressionMethod::Deflated);
    for entry in included(dir) {
        let base = entry
            .file_name()
            .unwrap_or_default()
            .to_string_lossy()
            .to_string();
        if entry.is_dir() {
            add_dir(&mut zip, &entry, &base, opts)?;
        } else {
            zip.start_file(base, opts)?;
            std::io::copy(&mut std::fs::File::open(&entry)?, &mut zip)?;
        }
    }
    zip.finish()?;
    Ok(())
}

fn add_dir(
    zip: &mut zip::ZipWriter<std::fs::File>,
    dir: &Path,
    prefix: &str,
    opts: zip::write::SimpleFileOptions,
) -> Result<()> {
    zip.add_directory(format!("{prefix}/"), opts)?;
    for e in std::fs::read_dir(dir)?.flatten() {
        let p = e.path();
        let name = format!("{prefix}/{}", e.file_name().to_string_lossy());
        if p.is_dir() {
            add_dir(zip, &p, &name, opts)?;
        } else {
            zip.start_file(name, opts)?;
            std::io::copy(&mut std::fs::File::open(&p)?, &mut *zip)?;
        }
    }
    Ok(())
}

pub async fn list(backups_dir: &Path, instance: &Instance) -> Result<Vec<BackupMeta>> {
    let root = backup_root(backups_dir, instance);
    let mut out = vec![];
    let mut rd = match tokio::fs::read_dir(&root).await {
        Ok(rd) => rd,
        Err(e) if e.kind() == std::io::ErrorKind::NotFound => return Ok(out),
        Err(e) => return Err(e.into()),
    };
    while let Some(e) = rd.next_entry().await? {
        let p = e.path();
        if p.extension().is_some_and(|x| x == "zip") {
            let meta = e.metadata().await?;
            out.push(BackupMeta {
                name: e.file_name().to_string_lossy().to_string(),
                path: p,
                size_bytes: meta.len(),
                created_at: meta
                    .modified()
                    .map(Into::into)
                    .unwrap_or_else(|_| Utc::now()),
            });
        }
    }
    out.sort_by(|a, b| b.name.cmp(&a.name));
    Ok(out)
}

pub async fn remove(backups_dir: &Path, instance: &Instance, name: &str) -> Result<()> {
    let path = backup_path(backups_dir, instance, name)?;
    tokio::fs::remove_file(path).await?;
    Ok(())
}

fn backup_path(backups_dir: &Path, instance: &Instance, name: &str) -> Result<PathBuf> {
    if name.contains('/') || name.contains('\\') || name.contains("..") {
        return Err(Error::BackupNotFound(name.into()));
    }
    let path = backup_root(backups_dir, instance).join(name);
    if !path.exists() {
        return Err(Error::BackupNotFound(name.into()));
    }
    Ok(path)
}

/// Extract a backup over the instance dir. Caller must ensure the server
/// is stopped.
pub async fn restore(backups_dir: &Path, instance: &Instance, name: &str) -> Result<()> {
    let path = backup_path(backups_dir, instance, name)?;
    let dir = instance.dir.clone();
    tokio::task::spawn_blocking(move || {
        let file = std::fs::File::open(&path)?;
        let mut archive = zip::ZipArchive::new(file)?;
        for i in 0..archive.len() {
            let mut entry = archive.by_index(i)?;
            let Some(enclosed) = entry.enclosed_name() else {
                continue; // zip-slip guard
            };
            let out = dir.join(enclosed);
            if entry.is_dir() {
                std::fs::create_dir_all(&out)?;
            } else {
                if let Some(parent) = out.parent() {
                    std::fs::create_dir_all(parent)?;
                }
                std::io::copy(&mut entry, &mut std::fs::File::create(&out)?)?;
            }
        }
        Ok(())
    })
    .await?
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::LoaderKind;

    fn instance(dir: PathBuf) -> Instance {
        Instance {
            id: uuid::Uuid::new_v4(),
            name: "t".into(),
            loader: LoaderKind::Vanilla,
            game_version: "1.21".into(),
            loader_version: None,
            dir,
            jar: Some("server.jar".into()),
            java_path: None,
            min_ram_mb: 512,
            max_ram_mb: 1024,
            jvm_args: vec![],
            created_at: Utc::now(),
        }
    }

    #[tokio::test]
    async fn backup_roundtrip() {
        let data = tempfile::tempdir().unwrap();
        let idir = tempfile::tempdir().unwrap();
        std::fs::create_dir_all(idir.path().join("world/region")).unwrap();
        std::fs::write(idir.path().join("world/region/r.0.0.mca"), b"chunk").unwrap();
        std::fs::write(idir.path().join("server.properties"), "a=1").unwrap();
        std::fs::write(idir.path().join("server.jar"), b"binary").unwrap();
        let inst = instance(idir.path().to_path_buf());

        let meta = create(data.path(), &inst).await.unwrap();
        assert!(meta.path.exists());
        let entries = list(data.path(), &inst).await.unwrap();
        assert_eq!(entries.len(), 1);

        std::fs::remove_file(idir.path().join("world/region/r.0.0.mca")).unwrap();
        restore(data.path(), &inst, &meta.name).await.unwrap();
        assert_eq!(
            std::fs::read(idir.path().join("world/region/r.0.0.mca")).unwrap(),
            b"chunk"
        );

        remove(data.path(), &inst, &meta.name).await.unwrap();
        assert!(list(data.path(), &inst).await.unwrap().is_empty());
        assert!(remove(data.path(), &inst, "nope.zip").await.is_err());
        assert!(remove(data.path(), &inst, "../evil").await.is_err());
    }
}
