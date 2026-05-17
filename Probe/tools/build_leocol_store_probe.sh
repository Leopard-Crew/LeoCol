#!/bin/sh
set -eu

ROOT_DIR=$(cd "$(dirname "$0")/../.." && pwd)
BUILD_DIR="$ROOT_DIR/Probe/build"
LEORM_DIR="$ROOT_DIR/bricks/LeoRM"

SRC_MAIN="$ROOT_DIR/Probe/tools/leocol_store_probe.m"
OUT="$BUILD_DIR/leocol_store_probe"

mkdir -p "$BUILD_DIR"

if [ "${CC:-}" = "" ]; then
    if [ -x /usr/bin/gcc-4.0 ]; then
        CC=/usr/bin/gcc-4.0
    else
        CC=cc
    fi
fi

( cd "$LEORM_DIR" && make Build/libLeoRM.a )

"$CC" \
    -isysroot /Developer/SDKs/MacOSX10.5.sdk \
    -mmacosx-version-min=10.5 \
    -arch ppc \
    -Wall -Wextra \
    -I"$LEORM_DIR/Sources" \
    "$SRC_MAIN" \
    "$LEORM_DIR/Build/libLeoRM.a" \
    -framework Foundation \
    -lsqlite3 \
    -o "$OUT"

echo "Built $OUT"
