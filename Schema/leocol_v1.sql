CREATE TABLE IF NOT EXISTS process_observation (
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
