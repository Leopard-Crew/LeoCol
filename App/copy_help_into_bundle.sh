#!/bin/sh
#
# Copy LeoCol local XHTML help into the built app bundle.
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/App/build/Debug/LeoCol.app}"
SOURCE_DIR="$ROOT_DIR/App/Help/LeoCol Help"
TARGET_DIR="$APP_BUNDLE/Contents/Resources/LeoCol Help"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "copy_help_into_bundle: app bundle not found: $APP_BUNDLE" >&2
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "copy_help_into_bundle: help source directory not found: $SOURCE_DIR" >&2
    exit 1
fi

rm -rf "$TARGET_DIR"
mkdir -p "$TARGET_DIR"

cp "$SOURCE_DIR"/*.html "$TARGET_DIR"/
cp "$SOURCE_DIR"/*.css "$TARGET_DIR"/

echo "copy_help_into_bundle: copied LeoCol Help into $TARGET_DIR"
