# LeoCol Probe Bundle Packaging Plan

## Purpose

This document defines how LeoCol should package its helper probes for a V1 app release.

## Problem

During development, LeoCol.app can run helper tools from:

```text
Probe/build
````

This is useful for local development.

However, a release app must not depend on a loose project directory layout.

## Decision

For packaged releases, LeoCol should bundle read-only helper probes inside the app bundle.

Preferred location:

```text
LeoCol.app/Contents/Resources/Probes/
```

## Existing app runner direction

LeoCol.app should keep the lookup order:

```text
1. Bundle Resources/Probes
2. Project-relative Probe/build
3. Report missing helper
```

This supports both release builds and developer builds.

## Helpers required for Update Snapshot

```text
leocol_journal_probe
leocol_lifecycle_probe
leocol_identity_probe
```

## Helpers required for Update Evidence

```text
leocol_launch_sources_probe
leocol_login_items_probe
leocol_startup_items_probe
leocol_kext_probe
leocol_cups_probe
leocol_receipt_bom_probe
```

## Not required for V1 runtime

These tools may remain development/probe tools unless later promoted:

```text
leocol_snapshot
leocol_store_probe
leocol_bundle_metadata_probe
```

## Packaging rules

Bundled helpers must be:

- executable,
    
- PowerPC compatible,
    
- built on Leopard,
    
- read-only in behavior,
    
- versioned together with LeoCol.app,
    
- not installed into system locations.
    

## Read-only boundary

Bundling helpers must not introduce:

- LaunchDaemons,
    
- LaunchAgents,
    
- privileged helpers,
    
- login items,
    
- StartupItems,
    
- background schedulers,
    
- automatic repair actions.
    

## Build direction

The first implementation may use a simple post-build copy step.

A later release process may use a dedicated packaging script.

Initial target path:

```text
App/build/Debug/LeoCol.app/Contents/Resources/Probes/
```

## Smoke test

A release-style test should verify:

```text
- LeoCol.app starts
- bundled probes are present
- Update Snapshot works without project-relative Probe/build
- Update Evidence works without project-relative Probe/build
- missing helper errors are reported clearly
- no helper is installed outside the bundle
```

## Acceptance criteria

Probe bundling is acceptable when LeoCol.app can run its V1 helper probes from inside its own app bundle while remaining read-only, explicit, and on-demand.  

