# LeoCol Process Instance Status Plan

## Purpose

This document defines how LeoCol should present process lifecycle rows in the main viewer.

The goal is to avoid confusing historical process instances with currently observed process instances.

## Problem

LeoCol currently shows process lifecycle rows.

That means the main table can contain multiple rows with the same process name or bundle name.

This is not automatically wrong.

Examples:

- a service can run multiple instances at the same time,
- a process can restart with a new PID,
- old PIDs remain in the lifecycle history,
- helper tools may appear briefly during snapshot creation.

However, without an explicit instance status, these rows can look like accidental duplicates.

## Correct lifecycle semantics

A lifecycle row represents a technical process instance.

The PID is part of that instance identity.

`last_seen_at` means:

```text
last snapshot in which this PID was actually observed
````

`exit_observed = 1` means:

```text
this PID was absent from a later sampled snapshot
```

It does not mean the process was killed by LeoCol.

It does not mean danger.

It only means LeoCol observed that the PID disappeared from a later snapshot.

## Current versus historical instances

LeoCol should expose an instance status derived from lifecycle data.

Suggested states:

```text
current
historical
```

German:

```text
aktuell
historisch
```

More descriptive UI wording:

```text
Seen in latest snapshot
Historical / exited
```

German:

```text
In letzter Momentaufnahme gesehen
Historisch / beendet
```

## Main viewer implication

The main process table should eventually add an instance status column.

Possible column names:

English:

```text
Instance
```

German:

```text
Instanz
```

Possible values:

English:

```text
Current
Historical
```

German:

```text
Aktuell
Historisch
```

## Detail view implication

The read-only detail inspector should eventually show:

- First seen
    
- Last seen
    
- Instance status
    
- Exit observed
    

This makes process restarts understandable.

## Do not deduplicate automatically

LeoCol must not hide lifecycle rows just because names match.

Matching names can mean:

- real parallel service instances,
    
- parent and worker processes,
    
- SSH sessions,
    
- Samba workers,
    
- restarted applications,
    
- old historical instances.
    

Automatic deduplication would destroy evidence.

## Logical identity versus technical instance

LeoCol should distinguish:

```text
technical instance
  PID-based lifecycle row

logical identity
  name, executable path, bundle identifier, bundle name, classification
```

A later view may group technical instances by logical identity.

That grouping is outside this immediate plan.

## Self-noise

LeoCol's own helper tools may appear in snapshots.

Examples:

```text
leocol_journal_probe
leocol_lifecycle_probe
leocol_identity_probe
```

This is expected.

A future UI may mark LeoCol helper processes as self-observation noise.

They should not be deleted or hidden silently.

## V1 direction

For V1, the best next step is not grouping.

The best next step is a clear status column:

```text
Current / Historical
```

This preserves all evidence while making the table easier to understand.

## Acceptance criteria

The instance status feature is acceptable when:

- historical process instances are visibly marked,
    
- current process instances are visibly marked,
    
- Last seen remains truthful,
    
- duplicate-looking rows are no longer misleading,
    
- no lifecycle rows are deleted,
    
- no process-control actions are introduced,
    
- the exported report can eventually include the same status.
    

## Boundary

LeoCol remains read-only.

Instance status is explanatory metadata.

It is not a cleanup recommendation.  

