CREATE TABLE IF NOT EXISTS snapshot_run (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    observed_at TEXT NOT NULL,
    source TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS process_observation (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    snapshot_id INTEGER,
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

CREATE TABLE IF NOT EXISTS process_lifecycle (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    pid INTEGER NOT NULL,
    first_seen_at TEXT NOT NULL,
    last_seen_at TEXT NOT NULL,
    executable_path TEXT,
    process_name TEXT,
    exit_observed INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS process_identity (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    lifecycle_id INTEGER NOT NULL,
    bundle_path TEXT,
    bundle_identifier TEXT,
    bundle_name TEXT,
    bundle_version TEXT,
    classification TEXT,
    confidence TEXT NOT NULL DEFAULT 'unknown',
    notes TEXT
);
