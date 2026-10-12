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
    /// Data directory (instances, registry, downloads). Defaults to the
    /// platform data dir (~/.local/share/mcse on Linux) or $MCSE_DATA_DIR.
    #[arg(long)]
    data_dir: Option<PathBuf>,
    /// Where downloaded Java runtimes are installed. Defaults to
    /// <data-dir>/runtimes or $MCSE_RUNTIMES_DIR.
    #[arg(long)]
    runtimes_dir: Option<PathBuf>,
    /// Where backups are stored. Defaults to <data-dir>/backups or
    /// $MCSE_BACKUPS_DIR.
    #[arg(long)]
    backups_dir: Option<PathBuf>,
    /// Static files to serve at / (a future web UI).
    #[arg(long)]
    web_dir: Option<PathBuf>,
    /// Allow any origin for browser clients. Off by default: with no auth
    /// on the API, permissive CORS would let any visited web page issue
    /// calls against this server.
    #[arg(long)]
    cors: bool,
}

#[tokio::main]
async fn main() -> std::io::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info".into()),
        )
        .init();
    let args = Args::parse();
    let data_dir = args.data_dir.unwrap_or_else(mcse_core::paths::data_dir);
    let manager = Manager::with_dirs(data_dir, args.runtimes_dir, args.backups_dir)
        .map_err(|e| std::io::Error::other(e.to_string()))?;
    let addr: SocketAddr = format!("{}:{}", args.host, args.port)
        .parse()
        .map_err(|e| std::io::Error::other(format!("invalid listen address: {e}")))?;
    mcse_api::serve(manager, addr, args.web_dir, args.cors).await
}
