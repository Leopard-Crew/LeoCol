# LeoCol Update Snapshot Pipeline Plan

## Purpose

This document defines the concrete probe pipeline for the future `Update Snapshot` command in LeoCol.app.

## Decision

LeoCol does not need a new snapshot helper for V1.

The required snapshot pipeline already exists as separate read-only probe tools.

## V1 pipeline

The app-level `Update Snapshot` command should run the following tools in this order:

```text
leocol_journal_probe
leocol_lifecycle_probe
leocol_identity_probe
````

## Responsibilities

### leocol_journal_probe

Creates a new process snapshot in the SQLite journal.

Expected responsibility:

```text
snapshot_run
process_observation
```

This is the command that makes a new snapshot visible in the Snapshot Overview.

### leocol_lifecycle_probe

Rebuilds or updates lifecycle state from recorded snapshots.

Expected responsibility:

```text
process_lifecycle
```

This is the command that updates first-seen, last-seen, and exit-observed state.

### leocol_identity_probe

Rebuilds conservative identity rows from lifecycle data.

Expected responsibility:

```text
process_identity
```

This is the command that updates bundle identity, classification, and confidence data used by the viewer.

## Not part of V1 Update Snapshot

### leocol_snapshot

`leocol_snapshot` prints a raw process snapshot as tab-separated text.

It is useful for diagnostics, but it does not update the LeoCol database.

It should not be used as the app-level Update Snapshot command.

### leocol_bundle_metadata_probe

`leocol_bundle_metadata_probe` is a single-bundle metadata proof tool.

It is useful for resolver development, but it is not yet the integrated V1 identity pipeline.

It should not be part of Update Snapshot unless the identity resolver is later redesigned to use it directly.

## UI implications

`Update Snapshot` must not silently block the app.

It should show visible progress, ideally:

```text
Updating snapshot...
Journal probe...
Lifecycle probe...
Identity probe...
Snapshot update completed.
```

German:

```text
Momentaufnahme wird aktualisiert...
Journal-Probe...
Lifecycle-Probe...
Identity-Probe...
Momentaufnahme abgeschlossen.
```

## Refresh requirements

After the pipeline completes, LeoCol.app should refresh:

- main process table,
    
- process detail inspector,
    
- Snapshot Overview panel if open,
    
- status line.
    

The exported report should naturally reflect the new database state on next export.

## Failure handling

If one stage fails, later stages should normally not run unless explicitly safe.

Recommended behavior:

```text
journal failed
  stop pipeline

lifecycle failed
  stop pipeline

identity failed
  warn, but process snapshot still exists
```

Failure must be reported as a warning, not as a system danger.

## Read-only boundary

The pipeline must not introduce:

- process killing,
    
- cleanup,
    
- deletion,
    
- quarantine,
    
- privilege escalation,
    
- background scheduling,
    
- LaunchAgent installation.
    

## Acceptance criteria

The future app command is acceptable when:

- it runs the three-stage pipeline on demand,
    
- the user sees visible progress,
    
- a new snapshot appears in Snapshot Overview,
    
- the main table reloads,
    
- Last seen advances where appropriate,
    
- warnings are shown without crashing,
    
- LeoCol remains read-only and explicit.  
    

