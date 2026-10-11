# AGENTS.md

- Read README.md, AGENTS.md, and CLAUDE.md before proposing or making any changes.
- Keep modules focused and small; do not create god files.
- Add tests for everything new — Dart (Flutter) and Rust.
- Do not finish while tests fail. Run the full suites locally; CI status is not a substitute.
- Do not squash merge requests. Use a regular merge commit so each conventional commit is preserved for the changelog.
- Install the commit hook so non-conventional subjects get `misc:` prefixed automatically:

  ```bash
  git config core.hooksPath .githooks
  ```

## Layout

- `rust/` — Rust workspace: `core` (manager, loaders, downloads, java, processes, backups), `api` (axum REST + WebSocket, `mcse-backend` binary), `frb` (flutter_rust_bridge facade).
- `lib/` — Flutter desktop app (Linux, Windows, macOS).
- `packages/mcse_bridge/` — generated FRB Dart bindings.
- `rust_builder/` — Cargokit glue that compiles `rust/frb` into desktop builds.
- `landing/` — Flutter web landing page (GitLab Pages).
- `test/` — Dart unit, widget, and golden tests.

## Local verification

Backend:

```bash
cd rust && cargo test
```

Frontend (repo root):

```bash
flutter test
```

Regenerate goldens after intentional UI changes:

```bash
flutter test --update-goldens
```

Regenerate FRB bindings after changing `rust/frb/src/api.rs`:

```bash
flutter_rust_bridge_codegen generate
```

## Commit message format

All commits follow Conventional Commits so cocogitto can bump versions and generate changelogs.

- Format: `<type>: <description>` — English type, imperative mood, no trailing period.
- Allowed types: `feat`, `fix`, `chore`, `ci`, `docs`, `refactor`, `style`, `test`, `perf`, `revert`, `build`, `misc`.
- `feat`/`fix`/`perf` trigger version bumps; everything else is grouped under "Other".
- Examples:

  ```
  feat: 添加实例备份恢复界面
  fix: 修复控制台命令发送问题
  ci: 添加 Flatpak 打包步骤
  ```
