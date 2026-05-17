#!/bin/sh
#
# build_headerdoc.sh
#
# Generate HeaderDoc API documentation for LeoRM.
#
# This script is intentionally Leopard-friendly and does not require modern
# package managers.

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$ROOT_DIR/Build/HeaderDoc"
RAW_DIR="$OUT_DIR/raw"
LOG_FILE="$OUT_DIR/headerdoc.log"

find_tool()
{
    name="$1"

    for candidate in \
        "/Developer/usr/bin/$name" \
        "/usr/bin/$name" \
        "/Developer/Tools/$name"
    do
        if [ -x "$candidate" ]; then
            echo "$candidate"
            return 0
        fi
    done

    if command -v "$name" >/dev/null 2>&1; then
        command -v "$name"
        return 0
    fi

    return 1
}

HEADERDOC2HTML="$(find_tool headerdoc2html || true)"
GATHERHEADERDOC="$(find_tool gatherheaderdoc || true)"

if [ -z "$HEADERDOC2HTML" ]; then
    echo "error: headerdoc2html not found." >&2
    echo "Install or locate Apple's HeaderDoc tools from the Leopard/Xcode toolchain." >&2
    exit 1
fi

rm -rf "$OUT_DIR"
mkdir -p "$RAW_DIR"

echo "LeoRM HeaderDoc build" | tee "$LOG_FILE"
echo "Root: $ROOT_DIR" | tee -a "$LOG_FILE"
echo "Output: $OUT_DIR" | tee -a "$LOG_FILE"
echo "Tool: $HEADERDOC2HTML" | tee -a "$LOG_FILE"

for header in "$ROOT_DIR"/Sources/*.h
do
    echo "Generating HeaderDoc for $(basename "$header")" | tee -a "$LOG_FILE"
    "$HEADERDOC2HTML" -o "$RAW_DIR" "$header" 2>&1 | tee -a "$LOG_FILE"
done

if [ -n "$GATHERHEADERDOC" ]; then
    echo "Gathering HeaderDoc index with $GATHERHEADERDOC" | tee -a "$LOG_FILE"
    "$GATHERHEADERDOC" "$RAW_DIR" 2>&1 | tee -a "$LOG_FILE"
else
    echo "warning: gatherheaderdoc not found; per-header documentation was generated without a gathered index." | tee -a "$LOG_FILE" >&2
fi

if egrep -i "warning:|WARNING:|No header or class discussion|Class braces do not match|Unable to find parser state|anonymous type" "$LOG_FILE" >/dev/null 2>&1; then
    echo "error: HeaderDoc completed with warnings. See $LOG_FILE" >&2
    exit 1
fi

echo "HeaderDoc output written to: $RAW_DIR" | tee -a "$LOG_FILE"
