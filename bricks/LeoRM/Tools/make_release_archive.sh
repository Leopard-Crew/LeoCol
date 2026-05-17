#!/bin/sh
#
# make_release_archive.sh
#
# Build a LeoRM source release archive with generated HeaderDoc output.
#
# Usage:
#   Tools/make_release_archive.sh v0.1.2-quality-gates
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
VERSION="${1:-}"

if [ -z "$VERSION" ]; then
    echo "error: release version argument missing." >&2
    echo "usage: Tools/make_release_archive.sh v0.1.2-quality-gates" >&2
    exit 1
fi

case "$VERSION" in
    v*)
        ;;
    *)
        echo "error: release version should start with v." >&2
        exit 1
        ;;
esac

cd "$ROOT_DIR"

COMMIT="$(git rev-parse HEAD)"
SHORT_COMMIT="$(git rev-parse --short HEAD)"
PUBLIC_VERSION="$(echo "$VERSION" | sed 's/^v//' | sed 's/-.*//')"
PACKAGE_NAME="LeoRM-$PUBLIC_VERSION-Leopard-PPC"
ARCHIVE_ROOT="$PACKAGE_NAME"
RELEASE_DIR="$ROOT_DIR/Build/Release"
STAGING_DIR="$RELEASE_DIR/$ARCHIVE_ROOT"
ARCHIVE_PATH="$RELEASE_DIR/$ARCHIVE_ROOT.tar.gz"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"
MANIFEST_PATH="$STAGING_DIR/RELEASE-MANIFEST.txt"

if [ -n "$(git status --short)" ]; then
    echo "error: working tree is not clean." >&2
    git status --short >&2
    exit 1
fi

echo "LeoRM release archive build"
echo "Release tag:     $VERSION"
echo "Public version:  $PUBLIC_VERSION"
echo "Package name:    $PACKAGE_NAME"
echo "Commit:          $COMMIT"

make clean
make
make smoke
make apidocs

rm -rf "$STAGING_DIR" "$ARCHIVE_PATH"
mkdir -p "$RELEASE_DIR"

git archive --format=tar --prefix="$ARCHIVE_ROOT/" HEAD | tar -C "$RELEASE_DIR" -xf -

mkdir -p "$STAGING_DIR/Documentation"
cp -R "$ROOT_DIR/Build/HeaderDoc/raw" "$STAGING_DIR/Documentation/HeaderDoc"

cat > "$MANIFEST_PATH" <<MANIFEST
LeoRM Release Manifest
======================

Release tag:
  $VERSION

Public version:
  $PUBLIC_VERSION

Package name:
  $PACKAGE_NAME

Commit:
  $COMMIT

Short commit:
  $SHORT_COMMIT

Target platform:
  Mac OS X 10.5.8 Leopard
  PowerPC
  MacOSX10.5.sdk
  Xcode 3.1.4-compatible toolchain
  Foundation.framework
  libsqlite3
  manual retain/release

Required verification path:
  make clean
  make
  make smoke
  make apidocs

Leak verification path:
  make leaks-check

Included:
  README.md
  Makefile
  Sources/
  Tests/
  Examples/
  Tools/
  docs/
  Documentation/HeaderDoc/
  RELEASE-MANIFEST.txt

External release artifact:
  $ARCHIVE_ROOT.tar.gz.sha256

Excluded:
  .git/
  Build/*.o
  Build/libLeoRM.a
  local test databases
  temporary build products
  user-local editor or Xcode state

Notes:
  Generated HeaderDoc HTML is included in this release archive.
  Generated HeaderDoc HTML is intentionally not committed to main.
  The static library is intentionally not included as a prebuilt binary artifact.
  Consumers should build from source on the target platform.
MANIFEST

(
    cd "$RELEASE_DIR"
    tar -czf "$ARCHIVE_PATH" "$ARCHIVE_ROOT"
)

if command -v shasum >/dev/null 2>&1; then
    (
        cd "$RELEASE_DIR"
        shasum -a 256 "$ARCHIVE_ROOT.tar.gz" > "$ARCHIVE_ROOT.tar.gz.sha256"
    )
elif command -v openssl >/dev/null 2>&1; then
    (
        cd "$RELEASE_DIR"
        openssl dgst -sha256 "$ARCHIVE_ROOT.tar.gz" | sed 's/^SHA256(//; s/)= /  /' > "$ARCHIVE_ROOT.tar.gz.sha256"
    )
else
    echo "error: neither shasum nor openssl found for SHA-256 generation." >&2
    exit 1
fi

require_archive_entry()
{
    entry="$1"

    if ! tar -tzf "$ARCHIVE_PATH" | grep -F "$entry" >/dev/null 2>&1; then
        echo "error: release archive is missing required entry: $entry" >&2
        exit 1
    fi
}

require_archive_entry "$ARCHIVE_ROOT/README.md"
require_archive_entry "$ARCHIVE_ROOT/Makefile"
require_archive_entry "$ARCHIVE_ROOT/Sources/LeoRM.h"
require_archive_entry "$ARCHIVE_ROOT/Sources/LRMDatabase.m"
require_archive_entry "$ARCHIVE_ROOT/Sources/LRMStatement.m"
require_archive_entry "$ARCHIVE_ROOT/Tests/smoke_main.m"
require_archive_entry "$ARCHIVE_ROOT/Examples/NotesStore/main.m"
require_archive_entry "$ARCHIVE_ROOT/Tools/build_headerdoc.sh"
require_archive_entry "$ARCHIVE_ROOT/Tools/make_release_archive.sh"
require_archive_entry "$ARCHIVE_ROOT/Documentation/HeaderDoc/LeoRM/index.html"
require_archive_entry "$ARCHIVE_ROOT/RELEASE-MANIFEST.txt"

echo "Release staging directory:"
echo "  $STAGING_DIR"

echo "Release archive:"
echo "  $ARCHIVE_PATH"

echo "SHA-256 checksum:"
echo "  $CHECKSUM_PATH"

echo "Archive source contents preview:"
tar -tzf "$ARCHIVE_PATH" | grep -E "/(Sources|Tests|Examples|Tools)/|/(README.md|Makefile|RELEASE-MANIFEST.txt)$" | head -80

echo "Archive documentation preview:"
tar -tzf "$ARCHIVE_PATH" | grep "/Documentation/HeaderDoc/" | head -40

echo "LeoRM release archive build OK"
