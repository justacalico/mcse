use clap::Parser;
use mcse_core::Manager;
use std::net::SocketAddr;
use std::path::PathBuf;

/// Standalone mcse backend: serves the REST + WebSocket API and,
/// optionally, a static web UI directory.
#[derive(Parser)]
#[command(name = "mcse-backend", version, about)]
struct Args {
    #[arg(short, long, default_value_t = 4790)]
    port: u16,
    #[arg(long, default_value = "127.0.0.1")]
    host: String,
    /// Data directory (instances, backups, runtimes). Defaults to the
    /// platform data dir (~/.local/share/mcse on Linux).
    #[arg(long)]
    data_dir: Option<PathBuf>,
    /// Static files to serve at / (a future web UI).
    #[arg(long)]
    web_dir: Option<PathBuf>,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info".into()),
        )
        .init();
    let args = Args::parse();
    let data_dir = args
        .data_dir
        .unwrap_or_else(mcse_core::paths::data_dir);
    let manager = Manager::new(data_dir)
        .map_err(|e| std::io::Error::new(std::io::ErrorKind::Other, e.to_string()))?;
    let addr: SocketAddr = format!("{}:{}", args.host, args.port)
        .parse()
        .expect("invalid listen address");
    mcse_api::serve(manager, addr, args.web_dir).await
}
