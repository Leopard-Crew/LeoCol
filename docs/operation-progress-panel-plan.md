# LeoCol Operation Progress Panel Plan

## Purpose

LeoCol needs a common progress surface for explicit on-demand operations.

This applies to:

- Update Snapshot
- Update Evidence

Both operations may run helper tools and take noticeable time.

## Problem

A menu command that starts work but gives no visible feedback makes the app appear frozen.

This is not acceptable for a Cupertino-2009-style system tool.

## Decision

LeoCol should provide a small reusable operation progress panel.

The panel is not a daemon view.

It is only shown while the user explicitly runs an operation.

## Initial UI

The panel should show:

- operation title,
- current status,
- indeterminate progress indicator,
- read-only log area,
- close/done button after completion.

Example:

```text
Updating snapshot...

Journal probe...
Lifecycle probe...
Identity probe...

Snapshot update completed.
````

German:

```text
Momentaufnahme wird aktualisiert...

Journal-Probe...
Lifecycle-Probe...
Identity-Probe...

Momentaufnahme abgeschlossen.
```

## Behavior

While running:

- the panel is visible,
    
- the progress indicator animates,
    
- the current stage is logged,
    
- the app must not appear silently blocked.
    

After completion:

- the progress indicator stops,
    
- final status is shown,
    
- the user can close the panel,
    
- the main viewer refreshes.
    

## Use cases

### Update Snapshot

Expected stages:

```text
leocol_journal_probe
leocol_lifecycle_probe
leocol_identity_probe
```

### Update Evidence

Expected stages:

```text
leocol_launch_sources_probe
leocol_login_items_probe
leocol_startup_items_probe
leocol_kext_probe
leocol_cups_probe
leocol_receipt_bom_probe
```

## Execution model

The first implementation may run helpers sequentially.

However, visible UI feedback must be shown before work begins.

A later implementation may move the helper execution to a worker thread.

## Failure handling

If a helper fails, the panel should log the failure.

The operation should end with a warning state, not a crash.

Failure means:

```text
this evidence/snapshot stage could not be completed
```

It does not mean:

```text
system danger
```

## Read-only boundary

The operation panel must not introduce:

- cleanup actions,
    
- delete buttons,
    
- repair buttons,
    
- privilege escalation,
    
- automatic background scheduling.
    

## Acceptance criteria

The progress panel is acceptable when:

- it can be shown from the app,
    
- it can display status text,
    
- it can append log lines,
    
- it can show running/completed state,
    
- it can be reused by Update Snapshot and Update Evidence,
    
- it does not imply hidden background activity.  
    EOF
    

