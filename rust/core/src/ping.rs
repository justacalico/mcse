use crate::models::PingResult;
use crate::{Error, Result};
use serde::Deserialize;
use std::time::Duration;
use tokio::io::{AsyncReadExt, AsyncWriteExt};
use tokio::net::TcpStream;

/// Server-list ping ("status ping") against a Java Edition server.
pub async fn ping(host: &str, port: u16, timeout: Duration) -> Result<PingResult> {
    tokio::time::timeout(timeout, ping_inner(host, port))
        .await
        .map_err(|_| Error::Msg("ping timed out".into()))?
}

async fn ping_inner(host: &str, port: u16) -> Result<PingResult> {
    let mut sock = TcpStream::connect((host, port)).await?;

    // Handshake packet: id 0, protocol -1, host, port, next-state 1.
    let mut payload = Vec::new();
    payload.push(0x00);
    write_varint(&mut payload, -1);
    write_string(&mut payload, host);
    payload.extend_from_slice(&port.to_be_bytes());
    write_varint(&mut payload, 1);
    send_packet(&mut sock, &payload).await?;

    // Status request: empty packet id 0.
    send_packet(&mut sock, &[0x00]).await?;

    // Read response packet: len varint, id 0x00, json string.
    let _len = read_varint(&mut sock).await?;
    let id = read_varint(&mut sock).await?;
    if id != 0 {
        return Err(Error::Msg(format!("unexpected packet id {id}")));
    }
    let json = read_string(&mut sock).await?;
    let resp: StatusResponse = serde_json::from_str(&json)?;
    Ok(PingResult {
        motd: resp.motd(),
        online_players: resp.players.as_ref().map(|p| p.online).unwrap_or(0),
        max_players: resp.players.as_ref().map(|p| p.max).unwrap_or(0),
        version_name: resp
            .version
            .as_ref()
            .map(|v| v.name.clone())
            .unwrap_or_default(),
        protocol: resp.version.and_then(|v| v.protocol).unwrap_or_default(),
        favicon: resp.favicon,
    })
}

#[derive(Deserialize)]
struct StatusResponse {
    version: Option<Version>,
    players: Option<Players>,
    description: Option<serde_json::Value>,
    favicon: Option<String>,
}

#[derive(Deserialize)]
struct Version {
    name: String,
    protocol: Option<i64>,
}

#[derive(Deserialize)]
struct Players {
    online: u32,
    max: u32,
}

impl StatusResponse {
    fn motd(&self) -> String {
        match &self.description {
            Some(serde_json::Value::String(s)) => s.clone(),
            Some(serde_json::Value::Object(o)) => o
                .get("text")
                .and_then(|t| t.as_str())
                .unwrap_or_default()
                .to_string(),
            _ => String::new(),
        }
    }
}

fn write_varint(out: &mut Vec<u8>, value: i32) {
    let mut v = value as u32;
    loop {
        let mut b = (v & 0x7f) as u8;
        v >>= 7;
        if v != 0 {
            b |= 0x80;
        }
        out.push(b);
        if v == 0 {
            break;
        }
    }
}

fn write_string(out: &mut Vec<u8>, s: &str) {
    write_varint(out, s.len() as i32);
    out.extend_from_slice(s.as_bytes());
}

async fn send_packet(sock: &mut TcpStream, payload: &[u8]) -> Result<()> {
    let mut pkt = Vec::with_capacity(payload.len() + 5);
    write_varint(&mut pkt, payload.len() as i32);
    pkt.extend_from_slice(payload);
    sock.write_all(&pkt).await?;
    Ok(())
}

async fn read_varint(sock: &mut TcpStream) -> Result<i32> {
    let mut result = 0i32;
    for i in 0..5 {
        let b = sock.read_u8().await?;
        result |= ((b & 0x7f) as i32) << (7 * i);
        if b & 0x80 == 0 {
            return Ok(result);
        }
    }
    Err(Error::Msg("varint too long".into()))
}

async fn read_string(sock: &mut TcpStream) -> Result<String> {
    let len = read_varint(sock).await? as usize;
    if len > 4 * 1024 * 1024 {
        return Err(Error::Msg("oversized status response".into()));
    }
    let mut buf = vec![0u8; len];
    sock.read_exact(&mut buf).await?;
    Ok(String::from_utf8_lossy(&buf).to_string())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn varint_roundtrip() {
        let mut buf = Vec::new();
        write_varint(&mut buf, -1);
        assert_eq!(buf, [0xff, 0xff, 0xff, 0xff, 0x0f]);
        buf.clear();
        write_varint(&mut buf, 300);
        assert_eq!(buf, [0xac, 0x02]);
    }

    #[test]
    fn motd_forms() {
        let r: StatusResponse = serde_json::from_str(r#"{"description":"hello"}"#).unwrap();
        assert_eq!(r.motd(), "hello");
        let r: StatusResponse =
            serde_json::from_str(r#"{"description":{"text":"world"}}"#).unwrap();
        assert_eq!(r.motd(), "world");
        let r: StatusResponse = serde_json::from_str(r#"{}"#).unwrap();
        assert_eq!(r.motd(), "");
    }
}
