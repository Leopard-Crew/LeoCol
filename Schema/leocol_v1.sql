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

CREATE TABLE IF NOT EXISTS provenance_evidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    evidence_type TEXT NOT NULL,
    evidence_source TEXT NOT NULL,

    subject_kind TEXT,
    subject_name TEXT,
    subject_path TEXT,
    subject_identifier TEXT,

    evidence_path TEXT,
    evidence_value TEXT,

    resolution_state TEXT NOT NULL,
    confidence TEXT,

    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS process_provenance (
    id INTEGER PRIMARY KEY AUTOINCREMENT,

    lifecycle_id INTEGER NOT NULL,
    evidence_id INTEGER NOT NULL,

    relationship TEXT NOT NULL,
    created_at TEXT NOT NULL,

    FOREIGN KEY(lifecycle_id) REFERENCES process_lifecycle(id),
    FOREIGN KEY(evidence_id) REFERENCES provenance_evidence(id)
);
