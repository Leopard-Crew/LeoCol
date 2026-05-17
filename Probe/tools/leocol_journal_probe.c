/*
 * LeoCol SQLite journal probe.
 *
 * This probe writes conservative process observations into a SQLite journal.
 * It intentionally does not perform lifecycle aggregation or identity resolving yet.
 */

#include "leocol_process_snapshot.h"

#include <sqlite3.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef SQLITE_TRANSIENT
#define SQLITE_TRANSIENT ((sqlite3_destructor_type)-1)
#endif

typedef struct LeoColJournalContext {
    sqlite3 *db;
    sqlite3_stmt *insert_stmt;
    sqlite_int64 snapshot_id;
    int inserted_rows;
} LeoColJournalContext;

static const char *
leocol_default_db_path(void)
{
    return "Probe/results/leocol-v1.db";
}

static int
leocol_exec_sql(sqlite3 *db, const char *sql, const char *label)
{
    char *error_message;
    int rc;

    error_message = NULL;

    rc = sqlite3_exec(db, sql, NULL, NULL, &error_message);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_journal_probe: %s failed: %s\n",
                label,
                error_message != NULL ? error_message : sqlite3_errmsg(db));

        if (error_message != NULL) {
            sqlite3_free(error_message);
        }

        return -1;
    }

    return 0;
}

static int
leocol_bind_text_or_null(sqlite3_stmt *stmt, int index, const char *text)
{
    if (text == NULL || text[0] == '\0' || strcmp(text, "-") == 0) {
        return sqlite3_bind_null(stmt, index);
    }

    return sqlite3_bind_text(stmt, index, text, -1, SQLITE_TRANSIENT);
}

static int
leocol_create_schema(sqlite3 *db)
{
    if (leocol_exec_sql(db,
                        "CREATE TABLE IF NOT EXISTS snapshot_run ("
                        "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
                        "    observed_at TEXT NOT NULL,"
                        "    source TEXT NOT NULL"
                        ");",
                        "snapshot_run schema creation") != 0) {
        return -1;
    }

    if (leocol_exec_sql(db,
                        "CREATE TABLE IF NOT EXISTS process_observation ("
                        "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
                        "    snapshot_id INTEGER,"
                        "    observed_at TEXT NOT NULL,"
                        "    pid INTEGER NOT NULL,"
                        "    ppid INTEGER,"
                        "    uid INTEGER,"
                        "    process_name TEXT,"
                        "    executable_path TEXT,"
                        "    command_line TEXT,"
                        "    cpu_percent REAL,"
                        "    resident_size INTEGER"
                        ");",
                        "process_observation schema creation") != 0) {
        return -1;
    }

    if (leocol_exec_sql(db,
                        "CREATE TABLE IF NOT EXISTS process_lifecycle ("
                        "    id INTEGER PRIMARY KEY AUTOINCREMENT,"
                        "    pid INTEGER NOT NULL,"
                        "    first_seen_at TEXT NOT NULL,"
                        "    last_seen_at TEXT NOT NULL,"
                        "    executable_path TEXT,"
                        "    process_name TEXT,"
                        "    exit_observed INTEGER NOT NULL DEFAULT 0"
                        ");",
                        "process_lifecycle schema creation") != 0) {
        return -1;
    }

    return 0;
}

static int
leocol_prepare_insert(sqlite3 *db, sqlite3_stmt **stmt)
{
    const char *insert_sql =
        "INSERT INTO process_observation ("
        "    snapshot_id,"
        "    observed_at,"
        "    pid,"
        "    ppid,"
        "    uid,"
        "    process_name,"
        "    executable_path,"
        "    command_line,"
        "    cpu_percent,"
        "    resident_size"
        ") VALUES (?, ?, ?, ?, ?, ?, ?, NULL, NULL, NULL);";

    if (stmt == NULL) {
        errno = EINVAL;
        return -1;
    }

    *stmt = NULL;

    if (sqlite3_prepare_v2(db, insert_sql, -1, stmt, NULL) != SQLITE_OK) {
        fprintf(stderr,
                "leocol_journal_probe: prepare insert failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    return 0;
}

static int
leocol_ensure_snapshot_run(LeoColJournalContext *journal, const char *observed_at)
{
    sqlite3_stmt *stmt;
    int rc;

    if (journal == NULL || journal->db == NULL || observed_at == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (journal->snapshot_id != 0) {
        return 0;
    }

    stmt = NULL;

    rc = sqlite3_prepare_v2(journal->db,
                            "INSERT INTO snapshot_run (observed_at, source) VALUES (?, ?);",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_journal_probe: prepare snapshot_run failed: %s\n",
                sqlite3_errmsg(journal->db));
        return -1;
    }

    rc = sqlite3_bind_text(stmt, 1, observed_at, -1, SQLITE_TRANSIENT);

    if (rc == SQLITE_OK) {
        rc = sqlite3_bind_text(stmt, 2, "leocol_journal_probe", -1, SQLITE_TRANSIENT);
    }

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_journal_probe: bind snapshot_run failed: %s\n",
                sqlite3_errmsg(journal->db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_journal_probe: insert snapshot_run failed: %s\n",
                sqlite3_errmsg(journal->db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);

    journal->snapshot_id = sqlite3_last_insert_rowid(journal->db);

    return 0;
}

static int
leocol_insert_snapshot_row(const LeoColProcessSnapshotRow *row, void *context)
{
    LeoColJournalContext *journal;
    int rc;

    journal = (LeoColJournalContext *)context;

    if (row == NULL || journal == NULL || journal->insert_stmt == NULL) {
        errno = EINVAL;
        return -1;
    }

    sqlite3_reset(journal->insert_stmt);
    sqlite3_clear_bindings(journal->insert_stmt);

    if (leocol_ensure_snapshot_run(journal, row->observed_at) != 0) {
        return -1;
    }

    rc = sqlite3_bind_int64(journal->insert_stmt, 1, journal->snapshot_id);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = sqlite3_bind_text(journal->insert_stmt, 2, row->observed_at, -1, SQLITE_TRANSIENT);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = sqlite3_bind_int(journal->insert_stmt, 3, (int)row->pid);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = sqlite3_bind_int(journal->insert_stmt, 4, (int)row->ppid);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = sqlite3_bind_int(journal->insert_stmt, 5, (int)row->uid);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = leocol_bind_text_or_null(journal->insert_stmt, 6, row->process_name);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = leocol_bind_text_or_null(journal->insert_stmt, 7, row->executable_hint);
    if (rc != SQLITE_OK) {
        goto bind_failed;
    }

    rc = sqlite3_step(journal->insert_stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_journal_probe: insert failed: %s\n",
                sqlite3_errmsg(journal->db));
        return -1;
    }

    journal->inserted_rows++;

    return 0;

bind_failed:
    fprintf(stderr,
            "leocol_journal_probe: bind failed: %s\n",
            sqlite3_errmsg(journal->db));
    return -1;
}

int
main(int argc, char **argv)
{
    const char *db_path;
    LeoColJournalContext journal;
    int result;

    db_path = leocol_default_db_path();

    if (argc > 1) {
        db_path = argv[1];
    }

    memset(&journal, 0, sizeof(journal));

    if (sqlite3_open(db_path, &journal.db) != SQLITE_OK) {
        fprintf(stderr,
                "leocol_journal_probe: could not open database %s: %s\n",
                db_path,
                journal.db != NULL ? sqlite3_errmsg(journal.db) : "unknown error");

        if (journal.db != NULL) {
            sqlite3_close(journal.db);
        }

        return 1;
    }

    if (leocol_create_schema(journal.db) != 0) {
        sqlite3_close(journal.db);
        return 1;
    }

    if (leocol_prepare_insert(journal.db, &journal.insert_stmt) != 0) {
        sqlite3_close(journal.db);
        return 1;
    }

    if (leocol_exec_sql(journal.db, "BEGIN TRANSACTION;", "begin transaction") != 0) {
        sqlite3_finalize(journal.insert_stmt);
        sqlite3_close(journal.db);
        return 1;
    }

    result = leocol_process_snapshot_each(leocol_insert_snapshot_row, &journal);

    if (result != 0) {
        leocol_exec_sql(journal.db, "ROLLBACK;", "rollback");
        sqlite3_finalize(journal.insert_stmt);
        sqlite3_close(journal.db);
        return 1;
    }

    if (leocol_exec_sql(journal.db, "COMMIT;", "commit") != 0) {
        sqlite3_finalize(journal.insert_stmt);
        sqlite3_close(journal.db);
        return 1;
    }

    sqlite3_finalize(journal.insert_stmt);
    sqlite3_close(journal.db);

    printf("leocol_journal_probe: inserted %d process observations into %s\n",
           journal.inserted_rows,
           db_path);

    return 0;
}
