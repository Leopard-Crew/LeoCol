# LeoCol Update Evidence UX Plan

## Purpose

This document defines the user experience requirements for running provenance probes from LeoCol.app.

## Problem found

The first app-triggered Update Evidence experiment proved that LeoCol can launch probes from the app.

However, the user experience is not acceptable for V1:

```text
File / Ablage
  Update Evidence / Belege aktualisieren
````

caused visible disk activity, but the application appeared blocked and gave no useful progress feedback.

A successful build is not sufficient.

A command that silently blocks the UI is not Cupertino-2009 quality.

## Decision

LeoCol must not run long probe work silently on the main interaction path.

Update Evidence must provide clear user feedback while it is running.

## Required user-facing behavior

When the user chooses:

```text
File / Ablage
  Update Evidence
```

LeoCol should show a visible status surface.

Minimum acceptable UI:

```text
Updating evidence...
Launch Sources
Login Items
StartupItems
Kexts
CUPS
Receipt/BOM
```

German:

```text
Belege werden aktualisiert...
Launch Sources
Anmeldeobjekte
StartupItems
Kernel Extensions
CUPS
Receipt/BOM
```

The user must see that LeoCol is working.

The app must not appear frozen.

## Preferred V1 UI

Use a small modal sheet or utility panel with:

- indeterminate progress indicator,
    
- current probe name,
    
- status log,
    
- final result summary.
    

Example:

```text
Updating evidence...

✓ Launch Sources
✓ Login Items
✓ StartupItems
✓ Kexts
✓ CUPS
✓ Receipt/BOM

Evidence update completed.
```

If warnings occur:

```text
Evidence update completed with warnings.
Some probes could not be run.
```

## Runtime model

The probes remain separate read-only helper tools.

LeoCol.app coordinates them.

The initial implementation may still run probes sequentially, but must not leave the user without visible feedback.

A later implementation may move execution to a worker thread or asynchronous task chain.

## Update Evidence versus Reload

These commands are distinct.

```text
Reload
```

only reloads existing database content into the viewer.

```text
Update Evidence
```

runs provenance probes and updates `provenance_evidence`.

It does not update process observations.

## Update Evidence versus Update Snapshot

These commands are also distinct.

```text
Update Evidence
```

updates local provenance evidence:

- LaunchAgents / LaunchDaemons,
    
- Login Items,
    
- StartupItems,
    
- Kexts,
    
- CUPS,
    
- Receipt / BOM inventory.
    

```text
Update Snapshot
```

updates process observations and lifecycle information.

It affects what `Last seen` means for process rows.

## Snapshot overview requirement

Because LeoCol is snapshot-based, V1 needs a snapshot overview.

The user should be able to inspect existing snapshots:

```text
Snapshot ID   Observed At              Source      Process Count
17            2026-05-17 14:33:12      manual      72
18            2026-05-20 08:42:03      manual      69
```

This makes LeoCol honest and deterministic.

It prevents the user from mistaking database memory for a live process list.

## Future UI commands

The File / Ablage menu should move toward:

```text
Update Snapshot
Update Evidence
Export Report...
```

German:

```text
Momentaufnahme aktualisieren
Belege aktualisieren
Bericht exportieren...
```

## Failure handling

A failed probe must not crash LeoCol.

A failed probe must be reported as a warning.

Failure means:

```text
evidence for this area could not be updated
```

It does not mean:

```text
system danger
```

## Read-only boundary

The UX must not introduce:

- cleanup buttons,
    
- delete actions,
    
- repair actions,
    
- automatic quarantine,
    
- process killing,
    
- kext unloading,
    
- printer modification,
    
- package removal.
    

## Acceptance criteria

Update Evidence is acceptable when:

- the menu item is enabled,
    
- the user sees that work is running,
    
- the app does not appear frozen,
    
- probe results are summarized,
    
- warnings are visible,
    
- the evidence panel can be refreshed after completion,
    
- Reload remains clearly separate,
    
- process snapshot age is not misrepresented.  


