# LeoCol Data Model

## Storage principle

LeoCol uses a small explicit SQLite journal. The journal may be accessed directly during early probes and through LeoRM once LeoColStore becomes a stable storage brick.

The schema should be boring, stable, and understandable.

No heavy ORM is required for V1. LeoRM may be used as a small Leopard-native Repository/DAO layer, but it must not own LeoCol's domain model or hide LeoCol's schema.

## LeoRM boundary

LeoRM is allowed below LeoColStore.

    LeoCol.app / LeoColAgent
      -> LeoColStore
        -> LeoRM
          -> SQLite / libsqlite3

LeoColStore remains responsible for:

- the LeoCol schema,
- lifecycle aggregation rules,
- process identity storage,
- launch hints,
- collector-specific integrity checks,
- and the meaning of stored observations.

LeoRM may provide:

- database open and close handling,
- prepared statements,
- Foundation value binding,
- result row access,
- explicit transactions,
- migration running,
- schema metadata helpers,
- and NSError-shaped SQLite failures.

LeoRM must not generate hidden LeoCol schemas, own LeoCol domain objects, or turn LeoCol into a generic database framework.

## Initial tables

### process_observation

One row per sampled process observation.

```sql
CREATE TABLE process_observation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    observed_at TEXT NOT NULL,
    pid INTEGER NOT NULL,
    ppid INTEGER,
    uid INTEGER,
    process_name TEXT,
    executable_path TEXT,
    command_line TEXT,
    cpu_percent REAL,
    resident_size INTEGER
);
```

### process_lifecycle

Aggregated lifecycle approximation.

```sql
CREATE TABLE process_lifecycle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pid INTEGER NOT NULL,
    first_seen_at TEXT NOT NULL,
    last_seen_at TEXT NOT NULL,
    executable_path TEXT,
    process_name TEXT,
    exit_observed INTEGER NOT NULL DEFAULT 0
);
```

### process_identity

Resolved identity information.

```sql
CREATE TABLE process_identity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lifecycle_id INTEGER NOT NULL,
    bundle_path TEXT,
    bundle_identifier TEXT,
    bundle_name TEXT,
    bundle_version TEXT,
    classification TEXT,
    confidence TEXT NOT NULL DEFAULT 'unknown',
    notes TEXT,
    FOREIGN KEY (lifecycle_id) REFERENCES process_lifecycle(id)
);
```

### launch_hint

Possible launchd or parent-process relationship hints.

```sql
CREATE TABLE launch_hint (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lifecycle_id INTEGER NOT NULL,
    hint_type TEXT NOT NULL,
    hint_value TEXT,
    confidence TEXT NOT NULL DEFAULT 'unknown',
    FOREIGN KEY (lifecycle_id) REFERENCES process_lifecycle(id)
);
```

## Leopard SQLite compatibility note

The first schema draft may declare relationships with `FOREIGN KEY` clauses for readability, but V1 must not rely on SQLite enforcing them on Mac OS X 10.5.8's system SQLite.

LeoColStore must preserve referential discipline explicitly in repository code and tests.

If a later build uses a newer SQLite, foreign key enforcement may be enabled and verified by LeoRM, but that must be treated as an optional strengthening, not as the V1 correctness foundation.

## Timestamp format

Use ISO-like textual timestamps for readability in early development.

Example:

```text
2026-05-10 15:10:00 +0200
```

## Schema rule

Every stored value must be either:

- directly observed,

- derived from a named resolver,

- or marked unknown.


LeoCol must not hide guesses inside authoritative-looking fields.
