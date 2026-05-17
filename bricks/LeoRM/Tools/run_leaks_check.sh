#!/bin/sh
#
# run_leaks_check.sh
#
# Run a representative LeoRM scenario and inspect it with Leopard leaks(1).

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/Build"
LEAKS_DIR="$BUILD_DIR/Leaks"
LOG_FILE="$LEAKS_DIR/leaks.log"
TARGET="$BUILD_DIR/lrm-leaks-target"

find_tool()
{
    name="$1"

    for candidate in \
        "/usr/bin/$name" \
        "/Developer/usr/bin/$name" \
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

LEAKS="$(find_tool leaks || true)"

if [ -z "$LEAKS" ]; then
    echo "error: leaks tool not found." >&2
    exit 1
fi

mkdir -p "$LEAKS_DIR"

(
    cd "$ROOT_DIR"
    make "$TARGET"
)

rm -f "$LOG_FILE"

echo "LeoRM leaks check" | tee "$LOG_FILE"
echo "Root: $ROOT_DIR" | tee -a "$LOG_FILE"
echo "Tool: $LEAKS" | tee -a "$LOG_FILE"
echo "Target: $TARGET" | tee -a "$LOG_FILE"

"$TARGET" >> "$LOG_FILE" 2>&1 &
PID="$!"

echo "PID: $PID" | tee -a "$LOG_FILE"

sleep 3

echo "Running leaks..." | tee -a "$LOG_FILE"

set +e
"$LEAKS" -nocontext "$PID" >> "$LOG_FILE" 2>&1
LEAKS_STATUS="$?"
set -e

wait "$PID" || true

echo "leaks exit status: $LEAKS_STATUS" | tee -a "$LOG_FILE"

if grep -E " 0 leaks for 0 total leaked bytes|0 leaks for 0 total leaked bytes" "$LOG_FILE" >/dev/null 2>&1; then
    echo "LeoRM leaks check OK" | tee -a "$LOG_FILE"
    exit 0
fi

echo "error: leaks did not report a clean result. See $LOG_FILE" >&2
exit 1
