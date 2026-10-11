# mcse

A desktop **Minecraft Java Edition server manager**. Create and run Vanilla, Paper, Purpur, Fabric, Forge and NeoForge servers with a live console, `server.properties` editing, Java runtime management and one-click backups — all in a single binary with an embedded Rust backend.

[![pipeline](https://gitlab.com/HttpAnimations/mcse/badges/main/pipeline.svg)](https://gitlab.com/HttpAnimations/mcse/-/pipelines)
[![release](https://gitlab.com/HttpAnimations/mcse/-/badges/release.svg)](https://gitlab.com/HttpAnimations/mcse/-/releases)
[![license: AGPL-3.0](https://img.shields.io/badge/license-AGPL--3.0-blue.svg)](https://gitlab.com/HttpAnimations/mcse/-/blob/main/LICENSE)
[![pages](https://img.shields.io/badge/landing-mcse--0c8aa9.gitlab.io-54B049)](https://mcse-0c8aa9.gitlab.io/)

**Landing page:** <https://mcse-0c8aa9.gitlab.io/>
**Downloads:** <https://gitlab.com/HttpAnimations/mcse/-/releases> · <https://github.com/justacalico/mcse/releases>

## Features

- **Every loader** — Vanilla, Paper, Purpur, Fabric, Forge and NeoForge with automatic artifact downloads.
- **Live console** — send commands and watch server output in real time.
- **Backups** — create, restore and delete zipped world backups.
- **Java management** — detects installed JDKs and can install Temurin runtimes.
- **Properties editor** — every `server.properties` key editable from the UI.
- **One binary** — the Rust backend is compiled into the desktop app via Cargokit; no separate daemon to run.
- **Update check** — the About page checks GitLab releases for newer builds.

## Screenshots

![Servers](https://gitlab.com/HttpAnimations/mcse/-/raw/main/test/goldens/servers.png)
![Create a server](https://gitlab.com/HttpAnimations/mcse/-/raw/main/test/goldens/create.png)
![Console](https://gitlab.com/HttpAnimations/mcse/-/raw/main/test/goldens/detail_console.png)

## Architecture

```
Flutter desktop app  ──FRB──▶  Rust backend (embedded)  ──▶  server processes
                                  │
                                  └─ mcse-backend: standalone REST + WebSocket API
                                     for a future web UI
```

- `rust/core` — instance store, loader providers, downloader, Java runtimes, process control, server.properties, backups, status ping.
- `rust/api` — Axum REST + WebSocket server (`mcse-backend` binary).
- `rust/frb` — flutter_rust_bridge facade used by the Flutter app.
- `landing/` — Flutter web landing page deployed to GitLab Pages.

## Building

Requires Flutter 3.47+ and Rust 1.99+.

```bash
flutter pub get
flutter run -d linux    # or windows / macos
```

The Rust library is built automatically by Cargokit during the desktop build.

The standalone backend API server:

```bash
cd rust && cargo run -p mcse-api -- --help
```

## Testing

```bash
cd rust && cargo test        # backend
flutter test                 # frontend (100% line coverage)
```

Regenerate golden screenshots with `flutter test --update-goldens`.

## Packages

Releases ship:

- **Linux:** tar.gz, zip, `.deb`, `.rpm`, AppImage, Flatpak
- **Windows:** zip
- **macOS:** dmg, zip
- **Backend only:** `mcse-backend` binaries for all three platforms

## Versioning

Versioning is managed by [Cocogitto](https://github.com/cocogitto/cocogitto). Commits use [Conventional Commits](https://www.conventionalcommits.org/); `cog bump --auto` produces tags and `CHANGELOG.md` — see `cog.toml`.

## License

[AGPL-3.0-only](LICENSE). Not affiliated with Mojang or Microsoft.
