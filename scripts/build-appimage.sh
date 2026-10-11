#!/usr/bin/env bash
# Package a built Flutter Linux bundle as an AppImage using appimagetool.
#
# Usage: scripts/build-appimage.sh <bundle-dir> <version> <output-file>
set -euo pipefail

BUNDLE_DIR="${1:?usage: build-appimage.sh <bundle-dir> <version> <output-file>}"
VERSION="${2:?usage: build-appimage.sh <bundle-dir> <version> <output-file>}"
OUT="${3:?usage: build-appimage.sh <bundle-dir> <version> <output-file>}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPDIR="$(mktemp -d)/mcse.AppDir"
trap 'rm -rf "$(dirname "$APPDIR")"' EXIT

mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/icons/hicolor/256x256/apps"
cp -r "$BUNDLE_DIR/." "$APPDIR/usr/bin/"
cp "$ROOT/packaging/icons/mcse-256.png" "$APPDIR/mcse.png"
cp "$ROOT/packaging/icons/mcse-256.png" \
  "$APPDIR/usr/share/icons/hicolor/256x256/apps/mcse.png"

cat > "$APPDIR/mcse.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=mcse
Comment=Minecraft Java Edition server manager
Exec=mcse
Icon=mcse
Categories=Game;Utility;
Terminal=false
EOF

cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
exec "$HERE/usr/bin/mcse" "$@"
EOF
chmod +x "$APPDIR/AppRun"

TOOL="$(mktemp -d)/appimagetool"
curl -fsSL --retry 3 -o "$TOOL" \
  "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
chmod +x "$TOOL"

ARCH=x86_64 VERSION="$VERSION" "$TOOL" "$APPDIR" "$OUT"
echo "build-appimage: $OUT"
