use crate::models::JavaRuntime;
use crate::{paths, Error, Result};
use std::path::{Path, PathBuf};
use tokio::process::Command;

/// Parse the `java -version` output (first line like
/// `openjdk version "21.0.3" 2024-04-16`) into (full, major).
pub fn parse_version_output(out: &str) -> Option<(String, u32)> {
    let first = out.lines().next()?;
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

async fn probe(path: &Path) -> Option<JavaRuntime> {
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
    })
}

fn java_binary(dir: &Path) -> PathBuf {
    if cfg!(windows) {
        dir.join("bin").join("java.exe")
    } else {
        dir.join("bin").join("java")
    }
}

fn candidate_dirs() -> Vec<PathBuf> {
    let mut dirs = vec![];
    if let Ok(home) = std::env::var("JAVA_HOME") {
        dirs.push(PathBuf::from(home));
    }
    dirs.push(paths::runtimes_dir());
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

/// Detect every java runtime on the system + managed runtimes.
pub async fn detect_runtimes() -> Vec<JavaRuntime> {
    let mut found: Vec<JavaRuntime> = vec![];
    let mut seen = std::collections::HashSet::new();

    // `java` on PATH
    if let Ok(path) = which() {
        if let Some(rt) = probe(&path).await {
            seen.insert(rt.path.clone());
            found.push(rt);
        }
    }

    for base in candidate_dirs() {
        if !base.is_dir() {
            continue;
        }
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
            let bin = java_binary(&home);
            if !bin.exists() || seen.contains(&bin) {
                continue;
            }
            if let Some(rt) = probe(&bin).await {
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

/// Pick the best runtime for a game version: smallest major >= required,
/// preferring an exact match.
pub fn pick_runtime(runtimes: &[JavaRuntime], required: u32) -> Option<&JavaRuntime> {
    runtimes
        .iter()
        .filter(|r| r.major >= required)
        .min_by_key(|r| r.major)
}

/// Download a Temurin JRE from the Adoptium API into the managed runtimes dir.
pub async fn install_temurin(
    client: &reqwest::Client,
    feature: u32,
    on_file: impl Fn(&str),
) -> Result<JavaRuntime> {
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
    let url = format!(
        "https://api.adoptium.net/v3/binary/latest/{feature}/ga/{os}/{arch}/jre/hotspot/normal/eclipse"
    );
    let dest_dir = paths::runtimes_dir().join(format!("temurin-{feature}"));
    tokio::fs::create_dir_all(&dest_dir).await?;
    let archive = paths::downloads_dir().join(format!("temurin-{feature}.bin"));
    crate::download::download(client, &url, &archive, None, None, |_, _| {}).await?;

    on_file("extracting");
    let dest = dest_dir.clone();
    let archive_c = archive.clone();
    tokio::task::spawn_blocking(move || extract_archive(&archive_c, &dest)).await??;
    let _ = tokio::fs::remove_file(&archive).await;

    // The archive contains a top-level jdk-* dir; find the java binary.
    let mut stack = vec![dest_dir];
    while let Some(dir) = stack.pop() {
        let bin = java_binary(&dir);
        if bin.exists() {
            if let Some(rt) = probe(&bin).await {
                return Ok(rt);
            }
        }
        let mut rd = tokio::fs::read_dir(&dir).await?;
        while let Some(e) = rd.next_entry().await? {
            if e.path().is_dir() {
                stack.push(e.path());
            }
        }
    }
    Err(Error::Msg(format!(
        "extracted temurin-{feature} but found no java binary"
    )))
}

fn extract_archive(archive: &Path, dest: &Path) -> Result<()> {
    let name = archive.to_string_lossy();
    let file = std::fs::File::open(archive)?;
    if name.ends_with(".zip") {
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
        };
        let r17 = JavaRuntime {
            path: PathBuf::from("/j17"),
            version: "17".into(),
            major: 17,
        };
        let r21 = JavaRuntime {
            path: PathBuf::from("/j21"),
            version: "21".into(),
            major: 21,
        };
        let all = vec![r21.clone(), r8.clone(), r17.clone()];
        assert_eq!(pick_runtime(&all, 8).unwrap().major, 8);
        assert_eq!(pick_runtime(&all, 17).unwrap().major, 17);
        assert_eq!(pick_runtime(&all, 21).unwrap().major, 21);
        assert!(pick_runtime(std::slice::from_ref(&r8), 21).is_none());
    }
}
