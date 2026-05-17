#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
BUILD_DIR="$ROOT_DIR/Probe/build"

SRC_MAIN="$ROOT_DIR/Probe/tools/leocol_bundle_metadata_probe.c"
OUT="$BUILD_DIR/leocol_bundle_metadata_probe"

mkdir -p "$BUILD_DIR"

if [ "${CC:-}" = "" ]; then
    if [ -x /usr/bin/gcc-4.0 ]; then
        CC=/usr/bin/gcc-4.0
    else
        CC=cc
    fi
fi

"$CC" -Wall -Wextra -std=c99 -pedantic -o "$OUT" "$SRC_MAIN" -framework CoreFoundation

echo "Built $OUT"
