# LeoRM Brick Record

LeoRM is included in LeoCol as a first-party Leopard-Crew / quietcode.org brick.

## Role

LeoRM is intended to become the storage helper below LeoColStore.

It is not a third-party vendor snapshot and not an external framework requirement for the early C probes.

## Why LeoCol includes LeoRM

LeoCol is the first real consumer and proving ground for LeoRM.

The raw C probes intentionally proved the Leopard baseline first:

- process observation,
- SQLite persistence,
- snapshot runs,
- lifecycle rebuilds,
- identity resolution,
- CoreFoundation bundle metadata.

LeoRM integration should happen only after these baselines are understood.

## Integration boundary

LeoRM may support:

- SQLite open and close handling,
- prepared statements,
- transactions,
- migrations,
- result-row access,
- structured errors.

LeoRM must not own:

- LeoCol process semantics,
- snapshot-run meaning,
- lifecycle aggregation rules,
- identity resolver rules,
- classification policy,
- or user-facing interpretation.

## Current integration status

LeoRM is present as a brick, but the active probes still use raw C, sqlite3, and CoreFoundation directly.

This is intentional.

The next LeoRM step should be a small Objective-C `LeoColStore` experiment, not a rewrite of the existing probes.
