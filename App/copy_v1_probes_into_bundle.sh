#!/bin/sh
#
# Copy LeoCol V1 probe helpers into the built LeoCol.app bundle.
#
# This script is intentionally simple:
# - no installation into system paths,
# - no LaunchAgent/LaunchDaemon,
# - no privilege escalation,
# - no background service.
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_BUNDLE="${1:-$ROOT_DIR/App/build/Debug/LeoCol.app}"
SOURCE_DIR="$ROOT_DIR/Probe/build"
TARGET_DIR="$APP_BUNDLE/Contents/Resources/Probes"

PROBES="
leocol_journal_probe
leocol_lifecycle_probe
leocol_identity_probe
leocol_launch_sources_probe
leocol_login_items_probe
leocol_startup_items_probe
leocol_kext_probe
leocol_cups_probe
leocol_receipt_bom_probe
"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "copy_v1_probes_into_bundle: app bundle not found: $APP_BUNDLE" >&2
    exit 1
fi

if [ ! -d "$SOURCE_DIR" ]; then
    echo "copy_v1_probes_into_bundle: probe build directory not found: $SOURCE_DIR" >&2
    exit 1
fi

mkdir -p "$TARGET_DIR"

for probe in $PROBES
do
    source_path="$SOURCE_DIR/$probe"
    target_path="$TARGET_DIR/$probe"

    if [ ! -x "$source_path" ]; then
        echo "copy_v1_probes_into_bundle: missing or non-executable probe: $source_path" >&2
        exit 1
    fi

    cp "$source_path" "$target_path"
    chmod 755 "$target_path"

    echo "copied $probe"
done

echo "copy_v1_probes_into_bundle: copied V1 probes into $TARGET_DIR"
