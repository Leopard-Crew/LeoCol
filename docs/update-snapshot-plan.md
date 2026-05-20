# LeoCol Update Snapshot Plan

## Purpose

This document defines the planned Update Snapshot command for LeoCol V1.

LeoCol is snapshot-based.

The user must be able to explicitly create a new process snapshot from LeoCol.app without using Terminal.

## Decision

LeoCol V1 should provide an explicit on-demand command:

```text
File / Ablage
  Update Snapshot
````

German:

```text
Ablage
  Momentaufnahme aktualisieren
```

This command creates a new process snapshot and updates process lifecycle information.

## Relationship to Reload

Reload does not collect new data.

Reload only reloads existing database content into the viewer.

```text
Reload
  read database
  refresh table
  refresh inspector
```

## Relationship to Update Evidence

Update Evidence updates local provenance evidence:

- LaunchAgents / LaunchDaemons
    
- Login Items
    
- StartupItems
    
- Kexts
    
- CUPS
    
- Receipt / BOM inventory
    

Update Evidence does not create a process snapshot.

## Relationship to Update Snapshot

Update Snapshot updates process observation data:

- creates a new snapshot_run row
    
- records process_observation rows
    
- updates process_lifecycle rows
    
- updates first_seen_at and last_seen_at
    
- updates exit_observed where appropriate
    

Update Snapshot is what makes `Last seen` advance.

## User-facing meaning

`Last seen` means:

```text
last seen in a LeoCol process snapshot
```

It does not mean:

```text
currently running
```

## Preferred UI behavior

Update Snapshot must not silently block the application.

Minimum acceptable UI:

```text
Updating snapshot...
Reading process table...
Updating lifecycle data...
Snapshot completed.
```

German:

```text
Momentaufnahme wird aktualisiert...
Prozesstabelle wird gelesen...
Lebensläufe werden aktualisiert...
Momentaufnahme abgeschlossen.
```

## Snapshot Overview integration

After Update Snapshot completes, LeoCol should refresh:

- main process table
    
- status line
    
- Snapshot Overview panel if it is open
    
- exported report data on next export
    

The Snapshot Overview should then show the new snapshot.

## Snapshot identity

Snapshot ID is the primary identity of a snapshot.

Equal timestamps alone do not prove duplicate snapshots.

A future integrity pass may add snapshot fingerprints.

## Duplicate handling

V1 should not delete or merge snapshots automatically.

If duplicate-looking snapshots are detected, LeoCol may later report them as integrity warnings.

Automatic cleanup is outside V1.

## Probe/tool direction

The existing development workflow already has snapshot-related database structures.

Implementation should follow the same model as provenance probes:

- small read-only helper,
    
- explicit app invocation,
    
- persistent database update,
    
- viewer reload.
    

The likely helper name:

```text
leocol_snapshot_probe
```

or an equivalent existing process journal probe if already present.

## Permissions

Update Snapshot should avoid privileged operations.

No sudo helper belongs in V1.

If some information cannot be collected without elevated privileges, LeoCol should record what it can and report the limitation.

## Non-goals

Update Snapshot must not:

- kill processes
    
- inspect private user data beyond process metadata
    
- install background agents
    
- run continuously
    
- modify LaunchAgents or LaunchDaemons
    
- modify CUPS
    
- unload kexts
    
- delete files
    
- deduplicate old snapshots automatically
    

## Report integration

The exported report should eventually include:

- latest snapshot timestamp
    
- snapshot count
    
- current visible row count
    
- possibly a short snapshot summary
    

## Status line direction

The main status line should eventually distinguish:

```text
Showing 72 of 72 rows — Last snapshot: 2026-05-20 08:42
```

German:

```text
72 von 72 Zeilen — Letzte Momentaufnahme: 20.05.2026 08:42
```

## Acceptance criteria

Update Snapshot is acceptable when:

- the menu item is explicit
    
- the user sees that work is running
    
- LeoCol does not appear frozen
    
- a new snapshot_run row is created
    
- process_observation rows are created
    
- process_lifecycle is updated
    
- the main viewer refreshes
    
- Snapshot Overview shows the new snapshot
    
- Last seen semantics remain honest
    
- no cleanup or repair actions are introduced
    

## Guiding rule

Update Snapshot answers:

```text
What does LeoCol observe now?
```

It must not pretend to be continuous live monitoring.  

