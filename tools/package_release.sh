#!/bin/sh
#
# Build and package a LeoCol release artifact for Mac OS X Leopard PowerPC.
#
# Output:
#   dist/LeoCol-<version>-Leopard-PPC.dmg
#   dist/LeoCol-<version>-Leopard-PPC.dmg.sha256
#
# The SHA256 sidecar file is mandatory for GitHub Releases.
#

set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_DIR="$ROOT_DIR/App"
BUILD_DIR="$APP_DIR/build/Release"
APP_BUNDLE="$BUILD_DIR/LeoCol.app"
DIST_DIR="$ROOT_DIR/dist"
STAGING_ROOT="$ROOT_DIR/build/release"
PLIST="$APP_DIR/Info.plist"

if [ ! -f "$PLIST" ]; then
    echo "package_release: Info.plist not found: $PLIST" >&2
    exit 1
fi

VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"

if [ -z "$VERSION" ]; then
    echo "package_release: empty version" >&2
    exit 1
fi

BASENAME="LeoCol-$VERSION-Leopard-PPC"
STAGING_DIR="$STAGING_ROOT/$BASENAME"
DMG_PATH="$DIST_DIR/$BASENAME.dmg"
SHA256_PATH="$DMG_PATH.sha256"

echo "package_release: building LeoCol $VERSION"

cd "$ROOT_DIR"

xcodebuild -project App/LeoCol.xcodeproj -configuration Release clean build ARCHS=ppc VALID_ARCHS=ppc ONLY_ACTIVE_ARCH=NO

App/copy_help_into_bundle.sh "$APP_BUNDLE"
App/copy_v1_probes_into_bundle.sh "$APP_BUNDLE"

echo "package_release: checking bundle contents"

test -f "$APP_BUNDLE/Contents/Info.plist"
test -x "$APP_BUNDLE/Contents/MacOS/LeoCol"

ARCH_INFO="$(/usr/bin/lipo -info "$APP_BUNDLE/Contents/MacOS/LeoCol")"
echo "package_release: binary architecture: $ARCH_INFO"

case "$ARCH_INFO" in
    *"Non-fat file:"*"architecture: ppc"*|*"Non-fat file:"*"architecture: ppc7400"*)
        ;;
    *"Architectures in the fat file:"*)
        echo "package_release: expected a PPC-only binary, got a fat binary" >&2
        exit 1
        ;;
    *)
        echo "package_release: expected a PPC-only binary" >&2
        exit 1
        ;;
esac
test -f "$APP_BUNDLE/Contents/Resources/LeoCol.icns"
test -f "$APP_BUNDLE/Contents/Resources/English.lproj/LeoCol Help/index.html"
test -f "$APP_BUNDLE/Contents/Resources/German.lproj/LeoCol Help/index.html"

for probe in \
    leocol_journal_probe \
    leocol_lifecycle_probe \
    leocol_identity_probe \
    leocol_launch_sources_probe \
    leocol_login_items_probe \
    leocol_startup_items_probe \
    leocol_kext_probe \
    leocol_cups_probe \
    leocol_receipt_bom_probe
do
    test -x "$APP_BUNDLE/Contents/Resources/Probes/$probe"
done

rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR"
mkdir -p "$DIST_DIR"

ditto "$APP_BUNDLE" "$STAGING_DIR/LeoCol.app"

cat > "$STAGING_DIR/README.txt" <<README
LeoCol $VERSION for Mac OS X Leopard PowerPC

LeoCol is a read-only system observation tool.

It can record explicit snapshots and display process lifecycle information,
provenance evidence, snapshot history, and plain text reports.

LeoCol does not clean, repair, delete, kill, unload, install, or run as a daemon.

Target:
Mac OS X Leopard 10.5.8 PowerPC

Included:
- LeoCol.app
- localized native in-app help
- bundled V1 probes
- application icon

Checksum:
The GitHub release includes an external SHA256 sidecar file for the DMG.
README

rm -f "$DMG_PATH" "$SHA256_PATH"

echo "package_release: creating DMG"

hdiutil create \
    -srcfolder "$STAGING_DIR" \
    -volname "LeoCol $VERSION" \
    -fs HFS+ \
    -format UDZO \
    "$DMG_PATH"

echo "package_release: creating SHA256 sidecar"

if command -v shasum >/dev/null 2>&1; then
    (
        cd "$DIST_DIR"
        shasum -a 256 "$(basename "$DMG_PATH")" > "$(basename "$SHA256_PATH")"
    )
elif command -v openssl >/dev/null 2>&1; then
    HASH="$(openssl dgst -sha256 "$DMG_PATH" | awk '{print $NF}')"
    printf "%s  %s\n" "$HASH" "$(basename "$DMG_PATH")" > "$SHA256_PATH"
else
    echo "package_release: no SHA256 tool found" >&2
    exit 1
fi

test -s "$DMG_PATH"
test -s "$SHA256_PATH"

echo "package_release: created $DMG_PATH"
echo "package_release: created $SHA256_PATH"
