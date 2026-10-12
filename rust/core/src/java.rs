use crate::models::{JavaRelease, JavaRuntime};
use crate::{Error, Result};
use std::path::{Path, PathBuf};
use tokio::process::Command;

/// Parse the `java -version` output (first line like
/// `openjdk version "21.0.3" 2024-04-16`) into (full, major).
pub fn parse_version_output(out: &str) -> Option<(String, u32)> {
    let first = out.lines().find(|l| l.contains('"'))?;
    let start = first.find('"')?;
    let end = first[start + 1..].find('"')? + start + 1;
    let version = first[start + 1..end].to_string();
    let major = if let Some(rest) = version.strip_prefix("1.") {
        rest.split('.').next()?.parse().ok()?
    } else {
        version.split(['.', '-', '+', '_']).next()?.parse().ok()?
    };
    Some((version, major))
}

async fn probe(path: &Path, managed: bool) -> Option<JavaRuntime> {
    let out = Command::new(path).arg("-version").output().await.ok()?;
    let text = format!(
        "{}\n{}",
        String::from_utf8_lossy(&out.stdout),
        String::from_utf8_lossy(&out.stderr)
    );
    let (version, major) = parse_version_output(&text)?;
    Some(JavaRuntime {
        path: path.to_path_buf(),
        version,
        major,
        managed,
    })
}

fn java_binary(dir: &Path) -> PathBuf {
    if cfg!(windows) {
        dir.join("bin").join("java.exe")
    } else {
        dir.join("bin").join("java")
    }
}

fn candidate_dirs(runtimes_dir: &Path) -> Vec<PathBuf> {
    let mut dirs = vec![];
    if let Ok(home) = std::env::var("JAVA_HOME") {
        dirs.push(PathBuf::from(home));
    }
    dirs.push(runtimes_dir.to_path_buf());
    if cfg!(target_os = "linux") {
        dirs.push(PathBuf::from("/usr/lib/jvm"));
        dirs.push(PathBuf::from("/usr/java"));
    } else if cfg!(target_os = "macos") {
        dirs.push(PathBuf::from("/Library/Java/JavaVirtualMachines"));
    } else if cfg!(windows) {
        dirs.push(PathBuf::from("C:\\Program Files\\Java"));
        dirs.push(PathBuf::from("C:\\Program Files\\Eclipse Adoptium"));
        dirs.push(PathBuf::from("C:\\Program Files\\Microsoft"));
    }
    dirs
}

/// Detect every java runtime on the system + managed runtimes under
/// `runtimes_dir`.
pub async fn detect_runtimes(runtimes_dir: &Path) -> Vec<JavaRuntime> {
    let mut found: Vec<JavaRuntime> = vec![];
    let mut seen = std::collections::HashSet::new();
    let managed_root =
        dunce::canonicalize(runtimes_dir).unwrap_or_else(|_| runtimes_dir.to_path_buf());

    // `java` on PATH
    if let Ok(path) = which() {
        if let Some(rt) = probe(&path, path.starts_with(&managed_root)).await {
            seen.insert(rt.path.clone());
            found.push(rt);
        }
    }

    for base in candidate_dirs(&managed_root) {
        if !base.is_dir() {
            continue;
        }
        let managed = base == managed_root;
        let mut homes = vec![base.clone()];
        if let Ok(mut rd) = tokio::fs::read_dir(&base).await {
            while let Ok(Some(e)) = rd.next_entry().await {
                let p = e.path();
                if p.is_dir() {
                    homes.push(p.clone());
                    // macOS: <name>.jdk/Contents/Home
                    let mac = p.join("Contents").join("Home");
                    if mac.is_dir() {
                        homes.push(mac);
                    }
                }
            }
        }
        for home in homes {
            // Managed installs nest as temurin-N/jdk-*/bin/java, so walk
            // them recursively; system dirs only go one level deep.
            let bin = if managed {
                match find_java(&home) {
                    Some(b) => b,
                    None => continue,
                }
            } else {
                java_binary(&home)
            };
            if !bin.exists() || seen.contains(&bin) {
                continue;
            }
            if let Some(rt) = probe(&bin, bin.starts_with(&managed_root)).await {
                seen.insert(rt.path.clone());
                found.push(rt);
            }
        }
    }
    found.sort_by_key(|r| r.major);
    found
}

fn which() -> std::io::Result<PathBuf> {
    let cmd = if cfg!(windows) { "where" } else { "which" };
    let out = std::process::Command::new(cmd).arg("java").output()?;
    if !out.status.success() {
        return Err(std::io::Error::new(
            std::io::ErrorKind::NotFound,
            "java not on PATH",
        ));
    }
    let first = String::from_utf8_lossy(&out.stdout)
        .lines()
        .next()
        .unwrap_or("")
        .trim()
        .to_string();
    Ok(PathBuf::from(first))
}

/// Minimum java major version required for a Minecraft version string
/// like "1.20.5", "1.19", "23w31a" or "1.7.10".
pub fn required_java(game_version: &str) -> u32 {
    let parts: Vec<u32> = game_version
        .split('.')
        .filter_map(|p| {
            p.chars()
                .take_while(|c| c.is_ascii_digit())
                .collect::<String>()
                .parse()
                .ok()
        })
        .collect();
    let minor = parts.get(1).copied().unwrap_or(0);
    let patch = parts.get(2).copied().unwrap_or(0);
    if !game_version.starts_with("1.") {
        return 21; // snapshots / unknown — assume latest
    }
    match minor {
        0..=16 => 8,
        17 => 16,
        18..=19 => 17,
        20 if patch <= 4 => 17,
        _ => 21,
    }
}

/// Pick the best runtime for a game version: exact match first, then the
/// smallest major >= required. Majors far above the requirement are avoided:
/// old Minecraft breaks on new Java, so picking one would crash on launch.
pub fn pick_runtime(runtimes: &[JavaRuntime], required: u32) -> Option<&JavaRuntime> {
    runtimes.iter().find(|r| r.major == required).or_else(|| {
        let ceiling = match required {
            0..=11 => 17,
            12..=17 => 21,
            _ => u32::MAX,
        };
        runtimes
            .iter()
            .filter(|r| r.major >= required && r.major <= ceiling)
            .min_by_key(|r| r.major)
    })
}

/// Every feature release the Adoptium API lists as downloadable, newest
/// first. `lts` marks long-term-support releases.
pub async fn available_releases(client: &reqwest::Client) -> Result<Vec<JavaRelease>> {
    let body = client
        .get("https://api.adoptium.net/v3/info/available_releases")
        .send()
        .await?
        .error_for_status()?
        .text()
        .await?;
    parse_releases(&body)
}

fn parse_releases(body: &str) -> Result<Vec<JavaRelease>> {
    #[derive(serde::Deserialize)]
    struct Info {
        available_releases: Vec<u32>,
        #[serde(default)]
        available_lts_releases: Vec<u32>,
    }
    let info: Info = serde_json::from_str(body)?;
    let lts: std::collections::HashSet<u32> = info.available_lts_releases.into_iter().collect();
    let mut releases: Vec<JavaRelease> = info
        .available_releases
        .into_iter()
        .map(|feature| JavaRelease {
            feature,
            lts: lts.contains(&feature),
        })
        .collect();
    releases.sort_by_key(|r| std::cmp::Reverse(r.feature));
    Ok(releases)
}

/// Locate a `java` binary under `dir` (the archive nests it inside a
/// top-level jdk-* folder; macOS adds Contents/Home).
fn find_java(dir: &Path) -> Option<PathBuf> {
    let mut stack = vec![dir.to_path_buf()];
    let mut seen = std::collections::HashSet::new();
    while let Some(d) = stack.pop() {
        let key = dunce::canonicalize(&d).unwrap_or_else(|_| d.clone());
        if !seen.insert(key) {
            continue;
        }
        let bin = java_binary(&d);
        if bin.exists() {
            return Some(bin);
        }
        if let Ok(rd) = std::fs::read_dir(&d) {
            for e in rd.flatten() {
                if e.path().is_dir() {
                    stack.push(e.path());
                }
            }
        }
    }
    None
}

/// Download a Temurin runtime from the Adoptium API into `runtimes_dir`,
/// staging the archive in `downloads_dir`. No-ops when the feature is
/// already installed. Newer feature releases only ship a JDK, so it falls
/// back from JRE to JDK.
pub async fn install_temurin(
    client: &reqwest::Client,
    runtimes_dir: &Path,
    downloads_dir: &Path,
    feature: u32,
    on_progress: impl Fn(u64, Option<u64>),
    on_stage: impl Fn(&str),
) -> Result<JavaRuntime> {
    let dest_dir = runtimes_dir.join(format!("temurin-{feature}"));
    if let Some(bin) = find_java(&dest_dir) {
        if let Some(rt) = probe(&bin, true).await {
            return Ok(rt);
        }
    }

    let os = if cfg!(target_os = "windows") {
        "windows"
    } else if cfg!(target_os = "macos") {
        "mac"
    } else {
        "linux"
    };
    let arch = if cfg!(target_arch = "aarch64") {
        "aarch64"
    } else {
        "x64"
    };
    tokio::fs::create_dir_all(&dest_dir).await?;
    tokio::fs::create_dir_all(downloads_dir).await?;
    let archive = downloads_dir.join(format!("temurin-{feature}.bin"));

    let mut last_err = None;
    for image_type in ["jre", "jdk"] {
        let url = format!(
            "https://api.adoptium.net/v3/binary/latest/{feature}/ga/{os}/{arch}/{image_type}/hotspot/normal/eclipse"
        );
        match crate::download::download(client, &url, &archive, None, None, None, &on_progress)
            .await
        {
            Ok(_) => {
                last_err = None;
                break;
            }
            Err(e) => {
                let missing = matches!(&e, Error::Http(h)
                    if h.status() == Some(reqwest::StatusCode::NOT_FOUND));
                if !missing {
                    return Err(e);
                }
                last_err = Some(e);
            }
        }
    }
    if let Some(e) = last_err {
        return Err(e);
    }

    on_stage("extract");
    let dest = dest_dir.clone();
    let archive_c = archive.clone();
    tokio::task::spawn_blocking(move || extract_archive(&archive_c, &dest)).await??;
    let _ = tokio::fs::remove_file(&archive).await;

    match find_java(&dest_dir) {
        Some(bin) => probe(&bin, true)
            .await
            .ok_or_else(|| Error::Msg(format!("extracted temurin-{feature} but java won't run"))),
        None => Err(Error::Msg(format!(
            "extracted temurin-{feature} but found no java binary"
        ))),
    }
}

/// Delete a runtime mcse installed under `runtimes_dir`. Returns the
/// removed directory.
pub async fn remove_managed(runtimes_dir: &Path, feature: u32) -> Result<PathBuf> {
    let dir = runtimes_dir.join(format!("temurin-{feature}"));
    if !dir.is_dir() {
        return Err(Error::InvalidInput(format!(
            "java {feature} is not installed by mcse"
        )));
    }
    tokio::fs::remove_dir_all(&dir).await?;
    Ok(dir)
}

fn extract_archive(archive: &Path, dest: &Path) -> Result<()> {
    let file = std::fs::File::open(archive)?;
    let mut magic = [0u8; 4];
    use std::io::Read;
    file.take(4).read_exact(&mut magic)?;
    let file = std::fs::File::open(archive)?;
    // Adoptium serves .zip on Windows and .tar.gz elsewhere; detect by magic.
    if magic.starts_with(b"PK") {
        zip::ZipArchive::new(file)?.extract(dest)?;
    } else {
        let gz = flate2::read::GzDecoder::new(file);
        tar::Archive::new(gz).unpack(dest)?;
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_openjdk() {
        let (v, m) = parse_version_output(
            "openjdk version \"21.0.3\" 2024-04-16 LTS\nOpenJDK Runtime Environment",
        )
        .unwrap();
        assert_eq!(v, "21.0.3");
        assert_eq!(m, 21);
        let (_, m) = parse_version_output("java version \"1.8.0_402\"\n").unwrap();
        assert_eq!(m, 8);
        assert!(parse_version_output("garbage").is_none());
    }

    #[test]
    fn required_versions() {
        assert_eq!(required_java("1.12.2"), 8);
        assert_eq!(required_java("1.16.5"), 8);
        assert_eq!(required_java("1.17.1"), 16);
        assert_eq!(required_java("1.18.2"), 17);
        assert_eq!(required_java("1.20.4"), 17);
        assert_eq!(required_java("1.20.5"), 21);
        assert_eq!(required_java("1.21.1"), 21);
        assert_eq!(required_java("25w14a"), 21);
    }

    #[test]
    fn pick_best() {
        let r8 = JavaRuntime {
            path: PathBuf::from("/j8"),
            version: "1.8".into(),
            major: 8,
            managed: false,
        };
        let r17 = JavaRuntime {
            path: PathBuf::from("/j17"),
            version: "17".into(),
            major: 17,
            managed: false,
        };
        let r21 = JavaRuntime {
            path: PathBuf::from("/j21"),
            version: "21".into(),
            major: 21,
            managed: true,
        };
        let all = vec![r21.clone(), r8.clone(), r17.clone()];
        assert_eq!(pick_runtime(&all, 8).unwrap().major, 8);
        assert_eq!(pick_runtime(&all, 11).unwrap().major, 17);
        assert_eq!(pick_runtime(&all, 17).unwrap().major, 17);
        assert_eq!(pick_runtime(&all, 21).unwrap().major, 21);
        assert!(pick_runtime(std::slice::from_ref(&r8), 21).is_none());
        // Old MC may not pick a runtime that is far too new.
        assert!(pick_runtime(std::slice::from_ref(&r21), 8).is_none());
        assert_eq!(pick_runtime(&all, 20).unwrap().major, 21);
    }

    #[test]
    fn parse_stderr_style_output() {
        // Real JVMs write `java -version` to stderr with stdout empty,
        // which used to leave a leading blank line in the combined text.
        let text = "\nopenjdk version \"1.8.0_362\" 2023-01-24";
        let (v, m) = parse_version_output(text).unwrap();
        assert_eq!(v, "1.8.0_362");
        assert_eq!(m, 8);
    }

    #[test]
    fn releases_sorted_and_lts_flagged() {
        let body = r#"{
            "available_releases": [8, 21, 17, 24, 11],
            "available_lts_releases": [8, 11, 17, 21],
            "most_recent_feature_release": 24,
            "most_recent_lts": 21
        }"#;
        let releases = parse_releases(body).unwrap();
        let features: Vec<u32> = releases.iter().map(|r| r.feature).collect();
        assert_eq!(features, [24, 21, 17, 11, 8]);
        assert!(releases[1].lts);
        assert!(!releases[0].lts);
        assert!(parse_releases("{}").is_err());
    }

    #[tokio::test]
    async fn remove_managed_only_managed_dirs() {
        let runtimes = tempfile::tempdir().unwrap();
        let dir = runtimes.path().join("temurin-21");
        tokio::fs::create_dir_all(&dir).await.unwrap();
        remove_managed(runtimes.path(), 21).await.unwrap();
        assert!(!dir.exists());
        // Not installed → error, and no directory gets created.
        assert!(remove_managed(runtimes.path(), 17).await.is_err());
        assert!(!runtimes.path().join("temurin-17").exists());
    }

    #[tokio::test]
    #[cfg(unix)]
    async fn detects_nested_managed_runtime() {
        let root = tempfile::tempdir().unwrap();
        let home = root.path().join("temurin-21/jdk-21.0.3");
        let bin = java_binary(&home);
        std::fs::create_dir_all(bin.parent().unwrap()).unwrap();
        std::fs::write(&bin, "#!/bin/sh\necho 'openjdk version \"21.0.3\"' >&2\n").unwrap();
        use std::os::unix::fs::PermissionsExt;
        std::fs::set_permissions(&bin, std::fs::Permissions::from_mode(0o755)).unwrap();
        let found = detect_runtimes(root.path()).await;
        assert!(found
            .iter()
            .any(|r| r.major == 21 && r.managed && r.path == bin));
    }

    #[test]
    fn find_java_walks_nested_dirs() {
        let root = tempfile::tempdir().unwrap();
        let bin = java_binary(&root.path().join("jdk-21"));
        std::fs::create_dir_all(bin.parent().unwrap()).unwrap();
        std::fs::write(&bin, b"#!").unwrap();
        assert_eq!(find_java(root.path()), Some(bin));
        assert!(find_java(&root.path().join("empty")).is_none());
    }
}
