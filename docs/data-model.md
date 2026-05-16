# LeoCol Data Model

## Storage principle

LeoCol uses a small explicit SQLite journal.

The schema should be boring, stable, and understandable.

No magic ORM is required for V1.

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
