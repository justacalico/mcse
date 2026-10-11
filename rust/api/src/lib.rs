use axum::extract::{Path, Query, State, WebSocketUpgrade};
use axum::http::StatusCode;
use axum::response::IntoResponse;
use axum::routing::{delete, get, patch, post};
use axum::{Json, Router};
use futures::{SinkExt, StreamExt};
use mcse_core::manager::{CreateRequest, InstancePatch};
use mcse_core::models::{Event, LoaderKind};
use mcse_core::Manager;
use serde::Deserialize;
use std::collections::BTreeMap;
use std::net::SocketAddr;
use std::path::PathBuf;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tower_http::services::ServeDir;
use uuid::Uuid;

#[derive(Clone)]
pub struct AppState {
    pub manager: Arc<Manager>,
}

pub fn router(manager: Arc<Manager>, web_dir: Option<PathBuf>) -> Router {
    let state = AppState { manager };
    let api = Router::new()
        .route("/health", get(health))
        .route("/loaders", get(loaders))
        .route("/loaders/{kind}/versions", get(versions))
        .route("/instances", get(list_instances).post(create_instance))
        .route("/instances/{id}", get(get_instance).delete(delete_instance))
        .route("/instances/{id}", patch(update_instance))
        .route("/instances/{id}/start", post(start))
        .route("/instances/{id}/stop", post(stop))
        .route("/instances/{id}/kill", post(kill))
        .route("/instances/{id}/restart", post(restart))
        .route("/instances/{id}/command", post(command))
        .route("/instances/{id}/log", get(log))
        .route("/instances/{id}/ping", get(ping_server))
        .route(
            "/instances/{id}/properties",
            get(get_properties).put(set_properties),
        )
        .route(
            "/instances/{id}/backups",
            get(list_backups).post(create_backup),
        )
        .route("/instances/{id}/backups/{name}", delete(delete_backup))
        .route(
            "/instances/{id}/backups/{name}/restore",
            post(restore_backup),
        )
        .route("/java", get(java_runtimes).post(install_java))
        .route("/ws", get(ws))
        .with_state(state);
    let app = Router::new().nest("/api", api);
    let app = match web_dir {
        Some(dir) => app.fallback_service(ServeDir::new(dir)),
        None => app,
    };
    app.layer(CorsLayer::permissive())
}

async fn health() -> Json<serde_json::Value> {
    Json(serde_json::json!({
        "ok": true,
        "name": "mcse-backend",
        "version": env!("CARGO_PKG_VERSION"),
    }))
}

async fn loaders() -> Json<serde_json::Value> {
    Json(serde_json::json!(LoaderKind::all()
        .iter()
        .map(|k| serde_json::json!({
            "kind": serde_json::to_value(k).unwrap(),
            "label": k.label(),
        }))
        .collect::<Vec<_>>()))
}

fn parse_loader(raw: &str) -> mcse_core::Result<LoaderKind> {
    match raw.to_ascii_lowercase().as_str() {
        "vanilla" => Ok(LoaderKind::Vanilla),
        "paper" => Ok(LoaderKind::Paper),
        "purpur" => Ok(LoaderKind::Purpur),
        "fabric" => Ok(LoaderKind::Fabric),
        "forge" => Ok(LoaderKind::Forge),
        "neoforge" => Ok(LoaderKind::NeoForge),
        other => Err(mcse_core::Error::UnknownLoader(other.into())),
    }
}

async fn versions(State(s): State<AppState>, Path(kind): Path<String>) -> axum::response::Response {
    match parse_loader(&kind) {
        Ok(loader) => respond(s.manager.game_versions(loader).await),
        Err(e) => map_err(e),
    }
}

async fn list_instances(State(s): State<AppState>) -> impl IntoResponse {
    Json(s.manager.list_instances().await)
}

#[derive(Deserialize)]
pub struct CreateBody {
    name: String,
    loader: LoaderKind,
    game_version: String,
    accept_eula: bool,
    min_ram_mb: Option<u32>,
    max_ram_mb: Option<u32>,
    properties: Option<BTreeMap<String, String>>,
}

async fn create_instance(
    State(s): State<AppState>,
    Json(body): Json<CreateBody>,
) -> impl IntoResponse {
    let mgr = s.manager.clone();
    let id = Uuid::new_v4();
    let req = CreateRequest {
        id,
        name: body.name,
        loader: body.loader,
        game_version: body.game_version,
        accept_eula: body.accept_eula,
        min_ram_mb: body.min_ram_mb.unwrap_or(1024),
        max_ram_mb: body.max_ram_mb.unwrap_or(4096),
        properties: body.properties.unwrap_or_else(|| mgr.default_properties()),
    };
    // Creation downloads files and may run an installer — run it in the
    // background so the client can watch progress over /ws.
    tokio::spawn(async move {
        if let Err(e) = mgr.create_instance(req).await {
            mgr.notify(Event::Fatal {
                id: Some(id),
                message: e.to_string(),
            });
        }
    });
    (StatusCode::ACCEPTED, Json(serde_json::json!({"id": id}))).into_response()
}

async fn get_instance(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    let list = s.manager.list_instances().await;
    match list.into_iter().find(|i| i.instance.id == id) {
        Some(i) => Json(i).into_response(),
        None => err(StatusCode::NOT_FOUND, "instance not found"),
    }
}

#[derive(Deserialize)]
struct DeleteQuery {
    files: Option<bool>,
}

async fn delete_instance(
    State(s): State<AppState>,
    Path(id): Path<Uuid>,
    Query(q): Query<DeleteQuery>,
) -> impl IntoResponse {
    respond_unit(s.manager.delete_instance(id, q.files.unwrap_or(true)).await)
}

#[derive(Deserialize)]
struct PatchBody {
    name: Option<String>,
    min_ram_mb: Option<u32>,
    max_ram_mb: Option<u32>,
    jvm_args: Option<Vec<String>>,
    java_path: Option<Option<String>>,
}

async fn update_instance(
    State(s): State<AppState>,
    Path(id): Path<Uuid>,
    Json(body): Json<PatchBody>,
) -> impl IntoResponse {
    respond_unit(
        s.manager
            .update_instance(
                id,
                InstancePatch {
                    name: body.name,
                    min_ram_mb: body.min_ram_mb,
                    max_ram_mb: body.max_ram_mb,
                    jvm_args: body.jvm_args,
                    java_path: body.java_path,
                },
            )
            .await,
    )
}

async fn start(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond_unit(s.manager.start(id).await)
}

async fn stop(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond_unit(s.manager.stop(id).await)
}

async fn kill(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond_unit(s.manager.kill(id).await)
}

async fn restart(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond_unit(s.manager.restart(id).await)
}

#[derive(Deserialize)]
struct CommandBody {
    command: String,
}

async fn command(
    State(s): State<AppState>,
    Path(id): Path<Uuid>,
    Json(body): Json<CommandBody>,
) -> impl IntoResponse {
    respond_unit(s.manager.send_command(id, &body.command).await)
}

async fn log(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond(s.manager.recent_log(id).await)
}

async fn ping_server(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond(s.manager.ping(id).await)
}

async fn get_properties(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond(s.manager.get_properties(id).await)
}

async fn set_properties(
    State(s): State<AppState>,
    Path(id): Path<Uuid>,
    Json(changes): Json<BTreeMap<String, String>>,
) -> impl IntoResponse {
    respond_unit(s.manager.set_properties(id, changes).await)
}

async fn list_backups(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond(s.manager.list_backups(id).await)
}

async fn create_backup(State(s): State<AppState>, Path(id): Path<Uuid>) -> impl IntoResponse {
    respond(s.manager.create_backup(id).await)
}

async fn delete_backup(
    State(s): State<AppState>,
    Path((id, name)): Path<(Uuid, String)>,
) -> impl IntoResponse {
    respond_unit(s.manager.delete_backup(id, &name).await)
}

async fn restore_backup(
    State(s): State<AppState>,
    Path((id, name)): Path<(Uuid, String)>,
) -> impl IntoResponse {
    respond_unit(s.manager.restore_backup(id, &name).await)
}

async fn java_runtimes(State(s): State<AppState>) -> impl IntoResponse {
    Json(s.manager.runtimes().await)
}

#[derive(Deserialize)]
struct InstallJavaBody {
    feature: u32,
}

async fn install_java(
    State(s): State<AppState>,
    Json(body): Json<InstallJavaBody>,
) -> impl IntoResponse {
    respond(s.manager.install_java(body.feature).await)
}

async fn ws(State(s): State<AppState>, ws: WebSocketUpgrade) -> impl IntoResponse {
    ws.on_upgrade(move |socket| ws_loop(s.manager, socket))
}

async fn ws_loop(manager: Arc<Manager>, socket: axum::extract::ws::WebSocket) {
    let (mut tx, mut rx) = socket.split();
    let mut events = manager.subscribe();
    let send = tokio::spawn(async move {
        while let Ok(event) = events.recv().await {
            let Ok(text) = serde_json::to_string(&event) else {
                continue;
            };
            if tx
                .send(axum::extract::ws::Message::Text(text.into()))
                .await
                .is_err()
            {
                break;
            }
        }
    });
    // Drain inbound so ping/pong + close frames are handled.
    while rx.next().await.is_some() {}
    send.abort();
}

fn respond<T: serde::Serialize>(r: mcse_core::Result<T>) -> axum::response::Response {
    match r {
        Ok(v) => Json(v).into_response(),
        Err(e) => map_err(e),
    }
}

fn respond_unit(r: mcse_core::Result<()>) -> axum::response::Response {
    match r {
        Ok(()) => StatusCode::NO_CONTENT.into_response(),
        Err(e) => map_err(e),
    }
}

fn map_err(e: mcse_core::Error) -> axum::response::Response {
    use mcse_core::Error::*;
    let code = match e {
        InstanceNotFound(_) | BackupNotFound(_) | VersionNotFound(_) => StatusCode::NOT_FOUND,
        AlreadyRunning(_) | NotRunning(_) | UnknownLoader(_) => StatusCode::CONFLICT,
        _ => StatusCode::INTERNAL_SERVER_ERROR,
    };
    err(code, &e.to_string())
}

fn err(code: StatusCode, msg: &str) -> axum::response::Response {
    (code, Json(serde_json::json!({"error": msg}))).into_response()
}

pub async fn serve(
    manager: Arc<Manager>,
    addr: SocketAddr,
    web_dir: Option<PathBuf>,
) -> std::io::Result<()> {
    let listener = tokio::net::TcpListener::bind(addr).await?;
    tracing::info!("mcse-backend listening on {addr}");
    axum::serve(listener, router(manager, web_dir)).await
}
