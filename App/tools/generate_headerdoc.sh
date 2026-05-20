#!/bin/sh
#
# Generate LeoCol HeaderDoc documentation on Mac OS X Leopard.
#
# This script documents LeoCol's public app headers only.
# LeoRM HeaderDoc is owned by the LeoRM brick.
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
APP_DIR="$ROOT_DIR/App"
OUT_DIR="$ROOT_DIR/Documentation/HeaderDoc/LeoCol"

HEADERS="
$APP_DIR/LCAppDelegate.h
$APP_DIR/LCDateFormatting.h
$APP_DIR/LCOperationPanel.h
$APP_DIR/LCPresentation.h
$APP_DIR/LCProcessStore.h
$APP_DIR/LCProvenanceStore.h
$APP_DIR/LCSnapshotStore.h
$APP_DIR/LCStoreSupport.h
$APP_DIR/LCString.h
"

if ! command -v headerdoc2html >/dev/null 2>&1; then
    echo "generate_headerdoc: headerdoc2html not found" >&2
    exit 1
fi

if ! command -v gatherheaderdoc >/dev/null 2>&1; then
    echo "generate_headerdoc: gatherheaderdoc not found" >&2
    exit 1
fi

rm -rf "$OUT_DIR"
mkdir -p "$OUT_DIR"

for header in $HEADERS
do
    if [ ! -f "$header" ]; then
        echo "generate_headerdoc: missing header: $header" >&2
        exit 1
    fi

    echo "HeaderDoc: $header"
    headerdoc2html -o "$OUT_DIR" "$header"
done

gatherheaderdoc "$OUT_DIR"

echo "generate_headerdoc: generated documentation in $OUT_DIR"
