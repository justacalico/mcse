use crate::{Error, Result};
use futures::StreamExt;
use sha1::Digest;
use std::path::{Path, PathBuf};
use tokio::io::AsyncWriteExt;

/// Download `url` to `dest`, reporting `(received, total)` through `progress`.
/// Verifies sha1/sha256 when provided. Returns the final path.
pub async fn download<F>(
    client: &reqwest::Client,
    url: &str,
    dest: &Path,
    sha1: Option<&str>,
    sha256: Option<&str>,
    progress: F,
) -> Result<PathBuf>
where
    F: Fn(u64, Option<u64>),
{
    if let Some(parent) = dest.parent() {
        tokio::fs::create_dir_all(parent).await?;
    }
    let tmp = dest.with_extension("part");
    let resp = client.get(url).send().await?.error_for_status()?;
    let total = resp.content_length();
    let mut file = tokio::fs::File::create(&tmp).await?;
    let mut received = 0u64;
    let mut s1 = sha1.map(|_| sha1::Sha1::new());
    let mut s256 = sha256.map(|_| sha2::Sha256::new());
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
        file.write_all(&chunk).await?;
        progress(received, total);
    }
    file.flush().await?;
    drop(file);

    if let (Some(expected), Some(h)) = (sha1, s1) {
        if !expected.eq_ignore_ascii_case(&hex::encode(h.finalize())) {
            let _ = tokio::fs::remove_file(&tmp).await;
            return Err(Error::Checksum(dest.to_path_buf()));
        }
    }
    if let (Some(expected), Some(h)) = (sha256, s256) {
        if !expected.eq_ignore_ascii_case(&hex::encode(h.finalize())) {
            let _ = tokio::fs::remove_file(&tmp).await;
            return Err(Error::Checksum(dest.to_path_buf()));
        }
    }
    tokio::fs::rename(&tmp, dest).await?;
    Ok(dest.to_path_buf())
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
