#!/usr/bin/env bash
# Build a Flatpak bundle + repo from a prebuilt Flutter Linux bundle.
# The manifest copies the already-compiled app — no network needed for the
# build step beyond the freedesktop runtime which is installed once here.
#
# Usage: scripts/build-flatpak.sh <bundle-dir> <version> <output.flatpak> [repo-out-dir]
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-flatpak.sh <bundle-dir> <version> <output.flatpak> [repo-dir]}"
VERSION="${2:?usage: build-flatpak.sh <bundle-dir> <version> <output.flatpak> [repo-dir]}"
OUT="${3:?usage: build-flatpak.sh <bundle-dir> <version> <output.flatpak> [repo-dir]}"
REPO_OUT="${4:-}"

APPID="gitlab.httpanimations.mcse"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

command -v flatpak-builder >/dev/null || {
  echo "build-flatpak: flatpak-builder not installed" >&2; exit 1; }

if ! flatpak remote-list --user --columns=name 2>/dev/null | grep -qx flathub; then
  flatpak remote-add --user --if-not-exists flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo
fi
flatpak install --user -y --noninteractive flathub \
  org.freedesktop.Platform//24.08 org.freedesktop.Sdk//24.08 >/dev/null

mkdir -p "$WORK/src"
cp -r "$BUNDLE_DIR/." "$WORK/src/"
cp "$ROOT/packaging/mcse.desktop" "$WORK/src/$APPID.desktop"
sed -i 's|^Exec=.*|Exec=mcse|' "$WORK/src/$APPID.desktop"
cp "$ROOT/packaging/icons/mcse-256.png" "$WORK/src/$APPID.png"
cp "$ROOT/packaging/mcse.metainfo.xml" "$WORK/src/$APPID.metainfo.xml"
sed "s/@APPID@/$APPID/g; s/@VERSION@/$VERSION/g" \
  "$ROOT/packaging/flatpak/manifest.yml" > "$WORK/manifest.yml"

flatpak-builder --force-clean --repo="$WORK/repo" \
  "$WORK/build" "$WORK/manifest.yml"

flatpak build-bundle "$WORK/repo" "$OUT" "$APPID" >/dev/null
echo "build-flatpak: $OUT"

if [ -n "$REPO_OUT" ]; then
  mkdir -p "$REPO_OUT"
  cp -r "$WORK/repo/." "$REPO_OUT/"
  echo "build-flatpak: repo -> $REPO_OUT"
fi
