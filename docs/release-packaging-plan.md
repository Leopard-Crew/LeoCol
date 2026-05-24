# LeoCol Release Packaging Plan

## Status

This document defines the first LeoCol release packaging pass after the V0.15
app product polish baseline.

## Goal

Prepare a reproducible Leopard PowerPC release package for LeoCol.

The release package must contain:

- LeoCol.app
- application icon
- localized in-app WebKit help
- bundled V1 probes
- versioned Info.plist metadata
- release notes
- checksum

## Non-goals

This pass does not introduce:

- installer package
- background daemon
- automatic updater
- privileged helper
- system modification
- cleanup or repair behavior

LeoCol remains a read-only observation tool.

## Target artifact

Preferred V1 artifact:

~~~text
LeoCol-<version>-Leopard-PPC.dmg
~~~

Fallback artifact:

~~~text
LeoCol-<version>-Leopard-PPC.tar.gz
~~~

The DMG is preferred because it matches the expected Mac application delivery
style.

## Build configuration

Use the Xcode Release configuration:

~~~text
xcodebuild -project App/LeoCol.xcodeproj -configuration Release clean build
~~~

After the build, copy required runtime resources into the app bundle:

~~~text
App/copy_help_into_bundle.sh App/build/Release/LeoCol.app
App/copy_v1_probes_into_bundle.sh App/build/Release/LeoCol.app
~~~

## Required bundle checks

The packaged app must contain:

~~~text
Contents/Info.plist
Contents/MacOS/LeoCol
Contents/Resources/LeoCol.icns
Contents/Resources/English.lproj/LeoCol Help/index.html
Contents/Resources/German.lproj/LeoCol Help/index.html
Contents/Resources/Probes/leocol_journal_probe
Contents/Resources/Probes/leocol_lifecycle_probe
Contents/Resources/Probes/leocol_identity_probe
Contents/Resources/Probes/leocol_launch_sources_probe
Contents/Resources/Probes/leocol_login_items_probe
Contents/Resources/Probes/leocol_startup_items_probe
Contents/Resources/Probes/leocol_kext_probe
Contents/Resources/Probes/leocol_cups_probe
Contents/Resources/Probes/leocol_receipt_bom_probe
~~~

## Runtime smoke test

Before packaging, run the Release app on Mac OS X Leopard PowerPC and verify:

- app launches
- icon appears in Finder
- Help opens localized LeoCol help
- Update Snapshot works
- Update Evidence reports missing helpers clearly if a helper is absent
- Export Report writes a text report
- About panel shows the expected version

## DMG layout

The DMG should contain:

~~~text
LeoCol.app
README.txt
CHECKSUMS.txt
~~~

Optional later polish:

~~~text
Applications symlink
custom volume icon
custom Finder background
~~~

These are not V1 blockers.

## Checksum

Generate SHA256 when available.

Fallback to SHA1 or MD5 only if the target Leopard system lacks SHA256 tooling.

## Release notes

Release notes should summarize:

- read-only system observation scope
- localized native help
- bundled probes
- process lifecycle and provenance evidence support
- no daemon, no cleanup, no repair behavior
- Leopard PowerPC target
