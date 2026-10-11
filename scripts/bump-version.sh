#!/usr/bin/env bash
set -euo pipefail

VERSION="$1"

if [ -z "$VERSION" ]; then
  echo "Error: version is required" >&2
  exit 1
fi

cd "$(dirname "$0")/.."

awk -v ver="$VERSION" '
/^\[workspace.package\]/ { in_pkg = 1 }
in_pkg && /^version = / {
  print "version = \"" ver "\""
  in_pkg = 0
  next
}
{ print }
' rust/Cargo.toml > rust/Cargo.toml.tmp && mv rust/Cargo.toml.tmp rust/Cargo.toml

build=1
if grep -q '^version: .*+' pubspec.yaml; then
  build=$(grep '^version: ' pubspec.yaml | sed 's/.*+//')
  build=$((build + 1))
fi
sed -i "s/^version: .*/version: ${VERSION}+${build}/" pubspec.yaml

if [[ -f rust/Cargo.lock ]]; then
  awk -v ver="$VERSION" '
  /^name = "mcse-/ { in_pkg = 1 }
  /^\[\[package\]\]/ && !/^name = "mcse-/ { if (!pending) in_pkg = 0 }
  in_pkg && /^version = / {
    print "version = \"" ver "\""
    in_pkg = 0
    next
  }
  { print }
  ' rust/Cargo.lock > rust/Cargo.lock.tmp && mv rust/Cargo.lock.tmp rust/Cargo.lock
fi

if ! grep -q "^version = \"$VERSION\"" rust/Cargo.toml; then
  echo "Error: rust/Cargo.toml version not updated" >&2
  exit 1
fi
if ! grep -q "^version: ${VERSION}+" pubspec.yaml; then
  echo "Error: pubspec.yaml version not updated" >&2
  exit 1
fi
