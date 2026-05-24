#!/bin/sh
#
# Copy LeoCol local XHTML help into the built app bundle.
#
# The help source is localized under App/Help/<language>.lproj/LeoCol Help.
# The built bundle receives matching localized resource folders.
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/App/build/Debug/LeoCol.app}"
HELP_ROOT="$ROOT_DIR/App/Help"
RESOURCES_DIR="$APP_BUNDLE/Contents/Resources"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "copy_help_into_bundle: app bundle not found: $APP_BUNDLE" >&2
    exit 1
fi

if [ ! -d "$HELP_ROOT" ]; then
    echo "copy_help_into_bundle: help root directory not found: $HELP_ROOT" >&2
    exit 1
fi

rm -rf "$RESOURCES_DIR/LeoCol Help"

for language in English German
do
    SOURCE_DIR="$HELP_ROOT/$language.lproj/LeoCol Help"

    if [ ! -d "$SOURCE_DIR" ]; then
        SOURCE_DIR="$HELP_ROOT/LeoCol Help"
    fi

    if [ ! -d "$SOURCE_DIR" ]; then
        echo "copy_help_into_bundle: help source directory not found for $language" >&2
        exit 1
    fi

    TARGET_DIR="$RESOURCES_DIR/$language.lproj/LeoCol Help"

    rm -rf "$TARGET_DIR"
    mkdir -p "$RESOURCES_DIR/$language.lproj"

    /usr/bin/ditto "$SOURCE_DIR" "$TARGET_DIR"

    echo "copy_help_into_bundle: copied $language LeoCol Help into $TARGET_DIR"
done
