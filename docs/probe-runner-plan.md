# LeoCol Probe Runner Plan

## Purpose

This document defines the first implementation plan for running LeoCol read-only probes from LeoCol.app.

It follows the runtime model defined in:

```text
docs/probe-integration-runtime-model.md
````

## Decision

LeoCol V1 should run probes on demand.

The user explicitly chooses:

```text
File / Ablage
  Update Evidence
```

LeoCol then runs the read-only provenance probes and refreshes the viewer state.

## Non-daemon rule

The probe runner must not turn LeoCol into a background service.

It must not install:

- LaunchDaemons
    
- LaunchAgents
    
- Login Items
    
- StartupItems
    
- privileged helpers
    
- schedulers
    
- background watchers
    

Probe execution is user-initiated.

## Initial user-facing command

English:

```text
Update Evidence
```

German:

```text
Belege aktualisieren
```

This command should be placed in the File / Ablage menu.

## Probe execution mechanism

LeoCol.app should use `NSTask` to run probe executables.

This is Leopard-native and explicit.

Each probe remains a separate command-line helper.

The app coordinates execution.

The helpers collect evidence.

The database stores the result.

The viewer reloads the result.

## Initial probe order

The first integrated runner should execute:

```text
leocol_launch_sources_probe
leocol_login_items_probe
leocol_startup_items_probe
leocol_kext_probe
leocol_cups_probe
leocol_receipt_bom_probe
```

The order is intentionally stable and deterministic.

## Development path

During development, probes may be found under:

```text
Probe/build
```

This keeps the current workflow working.

## Bundle path direction

For packaged app releases, probes should move toward a bundle-internal location such as:

```text
LeoCol.app/Contents/Resources/Probes/
```

The runner should be written so this later transition is straightforward.

## Path resolution strategy

The V1 runner may use this lookup order:

```text
1. Bundle Resources/Probes
2. Project-relative Probe/build
3. Report missing probe
```

This supports both packaged and development builds.

## Failure handling

A failed probe must not crash LeoCol.

The runner should collect:

- probe name
    
- exit status
    
- whether it launched
    
- whether it completed
    
- short output or error text when available
    

Failure means evidence could not be updated.

Failure does not mean danger.

## UI feedback

The first implementation may use a simple modal progress/status path.

Minimum acceptable feedback:

```text
Updating evidence...
Evidence update completed.
Evidence update completed with warnings.
Evidence update failed.
```

Later versions may use a panel or status log.

## Database refresh

After the probe runner completes, LeoCol should:

```text
reload process rows
reload evidence summary rows
refresh visible tables
update status line
```

## Read-only boundary

The probe runner must not add:

- delete actions
    
- repair actions
    
- quarantine actions
    
- kext unload actions
    
- process kill actions
    
- printer modification actions
    
- package uninstall actions
    

## Permissions

No sudo helper belongs in V1.

If a probe cannot collect evidence without elevated privileges, it should report the limitation.

## Runtime smoke test

After implementing the runner, test from Terminal:

```text
App/build/Debug/LeoCol.app/Contents/MacOS/LeoCol
```

Then verify:

- app starts
    
- Update Evidence menu item is enabled
    
- probes run
    
- evidence summary changes or reloads
    
- failures are reported without crashing
    
- export still works
    
- About still works
    

## V1 acceptance

Probe integration is acceptable when LeoCol can update its provenance evidence without manual Terminal commands while remaining read-only and on-demand.

