use crate::{Error, Result};
use futures::StreamExt;
use sha1::Digest;
use std::path::{Path, PathBuf};
use tokio::io::AsyncWriteExt;

/// Download `url` to `dest`, reporting `(received, total)` through `progress`.
/// Verifies sha1/sha256/md5 when provided. Returns the final path.
/// A partial download is removed if anything fails midway.
pub async fn download<F>(
    client: &reqwest::Client,
    url: &str,
    dest: &Path,
    sha1: Option<&str>,
    sha256: Option<&str>,
    md5: Option<&str>,
    progress: F,
) -> Result<PathBuf>
where
    F: Fn(u64, Option<u64>),
{
    if let Some(parent) = dest.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    let tmp = dest.with_extension("part");
    let result = run(client, url, &tmp, sha1, sha256, md5, progress).await;
    match result {
        Ok(()) => {
            tokio::fs::rename(&tmp, dest).await?;
            Ok(dest.to_path_buf())
        }
        Err(e) => {
            let _ = tokio::fs::remove_file(&tmp).await;
            Err(e)
        }
    }
}

#[allow(clippy::too_many_arguments)]
async fn run<F>(
    client: &reqwest::Client,
    url: &str,
    tmp: &Path,
    sha1: Option<&str>,
    sha256: Option<&str>,
    md5: Option<&str>,
    progress: F,
) -> Result<()>
where
    F: Fn(u64, Option<u64>),
{
    let resp = client.get(url).send().await?.error_for_status()?;
    let total = resp.content_length();
    let mut file = tokio::fs::File::create(tmp).await?;
    let mut received = 0u64;
    let mut s1 = sha1.map(|_| sha1::Sha1::new());
    let mut s256 = sha256.map(|_| sha2::Sha256::new());
    let mut m5 = md5.map(|_| md5::Md5::new());
    let mut stream = resp.bytes_stream();
    while let Some(chunk) = stream.next().await {
        let chunk = chunk?;
        received += chunk.len() as u64;
        if let Some(h) = s1.as_mut() {
            h.update(&chunk);
        }
        if let Some(h) = s256.as_mut() {
            h.update(&chunk);
        }
        if let Some(h) = m5.as_mut() {
            h.update(&chunk);
        }
        file.write_all(&chunk).await?;
        progress(received, total);
    }
    file.flush().await?;
    drop(file);

    for (expected, hash) in [
        (sha1, s1.map(|h| hex::encode(h.finalize()))),
        (sha256, s256.map(|h| hex::encode(h.finalize()))),
        (md5, m5.map(|h| hex::encode(h.finalize()))),
    ] {
        if let (Some(expected), Some(hash)) = (expected, hash) {
            if !expected.eq_ignore_ascii_case(&hash) {
                return Err(Error::Checksum(tmp.to_path_buf()));
            }
        }
    }
    Ok(())
}

mod hex {
    pub fn encode(bytes: impl AsRef<[u8]>) -> String {
        bytes.as_ref().iter().map(|b| format!("{b:02x}")).collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn hex_encode() {
        assert_eq!(hex::encode([0xde, 0xad]), "dead");
    }
}
