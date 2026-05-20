# LeoCol Bundled Probe Smoke Test

## Purpose

This document records the smoke test for running LeoCol V1 helper probes from inside the app bundle.

## Goal

LeoCol.app must not depend on the loose development path:

```text
Probe/build
````

for release-style operation.

For V1, the app should first look for helpers in:

```text
LeoCol.app/Contents/Resources/Probes/
```

and only fall back to the development path during local builds.

## Test procedure

The V1 helper probes were built.

LeoCol.app was built using Xcode.

The V1 probes were copied into the app bundle using:

```text
App/copy_v1_probes_into_bundle.sh
```

The development helper directory was temporarily hidden:

```text
mv Probe/build Probe/build.devtest-hidden
```

LeoCol.app was then launched directly from:

```text
App/build/Debug/LeoCol.app/Contents/MacOS/LeoCol
```

The development helper directory was restored afterwards:

```text
mv Probe/build.devtest-hidden Probe/build
```

## Bundled helpers

The following helpers were present in:

```text
LeoCol.app/Contents/Resources/Probes/
```

```text
leocol_cups_probe
leocol_identity_probe
leocol_journal_probe
leocol_kext_probe
leocol_launch_sources_probe
leocol_lifecycle_probe
leocol_login_items_probe
leocol_receipt_bom_probe
leocol_startup_items_probe
```

## Expected app commands

The release-style bundle test covers:

```text
Ablage
  Momentaufnahme aktualisieren
  Belege aktualisieren
```

Both commands must run without relying on `Probe/build`.

## Boundary

This test does not install helpers into system paths.

It does not create LaunchAgents, LaunchDaemons, StartupItems, login items, or background services.

All helper execution remains explicit, on-demand, bundle-local, and read-only.

## Acceptance criteria

The bundled probe smoke test passes when:

- all V1 helper probes are present in `Contents/Resources/Probes`,
    
- Update Snapshot works without `Probe/build`,
    
- Update Evidence works without `Probe/build`,
    
- the operation progress panel reports completion or clear warnings,
    
- the development helper directory is restored after the test.  
    

