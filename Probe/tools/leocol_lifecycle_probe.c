/*
 * LeoCol lifecycle probe.
 *
 * This probe rebuilds approximate process lifecycle rows from recorded
 * snapshot_run and process_observation data.
 *
 * It is intentionally conservative:
 * - PID reuse is not solved in this probe.
 * - first_seen_at and last_seen_at are sampled observations, not exact times.
 * - exit_observed means "not present in a later sampled snapshot".
 */

#include <sqlite3.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifndef SQLITE_TRANSIENT
#define SQLITE_TRANSIENT ((sqlite3_destructor_type)-1)
#endif

typedef struct LeoColLifecycleContext {
    sqlite3 *db;
    int snapshots_processed;
    int lifecycles_inserted;
    int lifecycles_updated;
    int exits_marked;
} LeoColLifecycleContext;

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
                "leocol_lifecycle_probe: %s failed: %s\n",
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
leocol_find_active_lifecycle(sqlite3 *db, int pid, sqlite_int64 *lifecycle_id)
{
    sqlite3_stmt *stmt;
    int rc;

    if (db == NULL || lifecycle_id == NULL) {
        errno = EINVAL;
        return -1;
    }

    *lifecycle_id = 0;
    stmt = NULL;

    rc = sqlite3_prepare_v2(db,
                            "SELECT id "
                            "FROM process_lifecycle "
                            "WHERE pid = ? AND exit_observed = 0 "
                            "ORDER BY id DESC "
                            "LIMIT 1;",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare active lifecycle lookup failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_int(stmt, 1, pid);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: bind active lifecycle lookup failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc == SQLITE_ROW) {
        *lifecycle_id = sqlite3_column_int64(stmt, 0);
    } else if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: active lifecycle lookup failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);
    return 0;
}

static int
leocol_insert_lifecycle(sqlite3 *db,
                        int pid,
                        const char *observed_at,
                        const char *process_name,
                        const char *executable_path)
{
    sqlite3_stmt *stmt;
    int rc;

    stmt = NULL;

    rc = sqlite3_prepare_v2(db,
                            "INSERT INTO process_lifecycle ("
                            "    pid,"
                            "    first_seen_at,"
                            "    last_seen_at,"
                            "    executable_path,"
                            "    process_name,"
                            "    exit_observed"
                            ") VALUES (?, ?, ?, ?, ?, 0);",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare lifecycle insert failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_int(stmt, 1, pid);

    if (rc == SQLITE_OK) {
        rc = sqlite3_bind_text(stmt, 2, observed_at, -1, SQLITE_TRANSIENT);
    }

    if (rc == SQLITE_OK) {
        rc = sqlite3_bind_text(stmt, 3, observed_at, -1, SQLITE_TRANSIENT);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 4, executable_path);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 5, process_name);
    }

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: bind lifecycle insert failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: lifecycle insert failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);
    return 0;
}

static int
leocol_update_lifecycle(sqlite3 *db,
                        sqlite_int64 lifecycle_id,
                        const char *observed_at,
                        const char *process_name,
                        const char *executable_path)
{
    sqlite3_stmt *stmt;
    int rc;

    stmt = NULL;

    rc = sqlite3_prepare_v2(db,
                            "UPDATE process_lifecycle "
                            "SET last_seen_at = ?, "
                            "    executable_path = COALESCE(?, executable_path), "
                            "    process_name = COALESCE(?, process_name) "
                            "WHERE id = ?;",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare lifecycle update failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_text(stmt, 1, observed_at, -1, SQLITE_TRANSIENT);

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 2, executable_path);
    }

    if (rc == SQLITE_OK) {
        rc = leocol_bind_text_or_null(stmt, 3, process_name);
    }

    if (rc == SQLITE_OK) {
        rc = sqlite3_bind_int64(stmt, 4, lifecycle_id);
    }

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: bind lifecycle update failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: lifecycle update failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);
    return 0;
}

static int
leocol_mark_missing_processes_exited(sqlite3 *db,
                                     sqlite_int64 snapshot_id,
                                     const char *observed_at,
                                     int *exits_marked)
{
    sqlite3_stmt *stmt;
    int rc;
    int changed;

    if (exits_marked == NULL) {
        errno = EINVAL;
        return -1;
    }

    *exits_marked = 0;
    stmt = NULL;

    (void)observed_at;

    rc = sqlite3_prepare_v2(db,
                            "UPDATE process_lifecycle "
                            "SET exit_observed = 1 "
                            "WHERE exit_observed = 0 "
                            "AND pid NOT IN ("
                            "    SELECT pid FROM process_observation WHERE snapshot_id = ?"
                            ");",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare exit marking failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_int64(stmt, 1, snapshot_id);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: bind exit marking failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    rc = sqlite3_step(stmt);

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: exit marking failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    changed = sqlite3_changes(db);

    if (changed > 0) {
        *exits_marked = changed;
    }

    sqlite3_finalize(stmt);
    return 0;
}

static int
leocol_process_snapshot(sqlite3 *db,
                        sqlite_int64 snapshot_id,
                        const char *observed_at,
                        LeoColLifecycleContext *context)
{
    sqlite3_stmt *stmt;
    int rc;

    stmt = NULL;

    rc = sqlite3_prepare_v2(db,
                            "SELECT pid, process_name, executable_path "
                            "FROM process_observation "
                            "WHERE snapshot_id = ? "
                            "ORDER BY pid;",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare observation scan failed: %s\n",
                sqlite3_errmsg(db));
        return -1;
    }

    rc = sqlite3_bind_int64(stmt, 1, snapshot_id);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: bind observation scan failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        int pid;
        const char *process_name;
        const char *executable_path;
        sqlite_int64 lifecycle_id;

        pid = sqlite3_column_int(stmt, 0);
        process_name = (const char *)sqlite3_column_text(stmt, 1);
        executable_path = (const char *)sqlite3_column_text(stmt, 2);

        if (leocol_find_active_lifecycle(db, pid, &lifecycle_id) != 0) {
            sqlite3_finalize(stmt);
            return -1;
        }

        if (lifecycle_id == 0) {
            if (leocol_insert_lifecycle(db,
                                        pid,
                                        observed_at,
                                        process_name,
                                        executable_path) != 0) {
                sqlite3_finalize(stmt);
                return -1;
            }

            context->lifecycles_inserted++;
        } else {
            if (leocol_update_lifecycle(db,
                                        lifecycle_id,
                                        observed_at,
                                        process_name,
                                        executable_path) != 0) {
                sqlite3_finalize(stmt);
                return -1;
            }

            context->lifecycles_updated++;
        }
    }

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: observation scan failed: %s\n",
                sqlite3_errmsg(db));
        sqlite3_finalize(stmt);
        return -1;
    }

    sqlite3_finalize(stmt);

    {
        int exits_marked;

        if (leocol_mark_missing_processes_exited(db,
                                                 snapshot_id,
                                                 observed_at,
                                                 &exits_marked) != 0) {
            return -1;
        }

        context->exits_marked += exits_marked;
    }

    context->snapshots_processed++;

    return 0;
}

static int
leocol_rebuild_lifecycles(LeoColLifecycleContext *context)
{
    sqlite3_stmt *stmt;
    int rc;

    if (context == NULL || context->db == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (leocol_exec_sql(context->db, "BEGIN TRANSACTION;", "begin transaction") != 0) {
        return -1;
    }

    if (leocol_exec_sql(context->db, "DELETE FROM process_lifecycle;", "clear lifecycle table") != 0) {
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    stmt = NULL;

    rc = sqlite3_prepare_v2(context->db,
                            "SELECT id, observed_at "
                            "FROM snapshot_run "
                            "ORDER BY id;",
                            -1,
                            &stmt,
                            NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: prepare snapshot scan failed: %s\n",
                sqlite3_errmsg(context->db));
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
        sqlite_int64 snapshot_id;
        const char *observed_at;

        snapshot_id = sqlite3_column_int64(stmt, 0);
        observed_at = (const char *)sqlite3_column_text(stmt, 1);

        if (observed_at == NULL) {
            observed_at = "unknown-time";
        }

        if (leocol_process_snapshot(context->db,
                                    snapshot_id,
                                    observed_at,
                                    context) != 0) {
            sqlite3_finalize(stmt);
            leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
            return -1;
        }
    }

    if (rc != SQLITE_DONE) {
        fprintf(stderr,
                "leocol_lifecycle_probe: snapshot scan failed: %s\n",
                sqlite3_errmsg(context->db));
        sqlite3_finalize(stmt);
        leocol_exec_sql(context->db, "ROLLBACK;", "rollback");
        return -1;
    }

    sqlite3_finalize(stmt);

    if (leocol_exec_sql(context->db, "COMMIT;", "commit") != 0) {
        return -1;
    }

    return 0;
}

int
main(int argc, char **argv)
{
    const char *db_path;
    LeoColLifecycleContext context;

    db_path = leocol_default_db_path();

    if (argc > 1) {
        db_path = argv[1];
    }

    memset(&context, 0, sizeof(context));

    if (sqlite3_open(db_path, &context.db) != SQLITE_OK) {
        fprintf(stderr,
                "leocol_lifecycle_probe: could not open database %s: %s\n",
                db_path,
                context.db != NULL ? sqlite3_errmsg(context.db) : "unknown error");

        if (context.db != NULL) {
            sqlite3_close(context.db);
        }

        return 1;
    }

    if (leocol_rebuild_lifecycles(&context) != 0) {
        sqlite3_close(context.db);
        return 1;
    }

    sqlite3_close(context.db);

    printf("leocol_lifecycle_probe: processed %d snapshots, inserted %d lifecycles, updated %d observations, marked %d exits\n",
           context.snapshots_processed,
           context.lifecycles_inserted,
           context.lifecycles_updated,
           context.exits_marked);

    return 0;
}
