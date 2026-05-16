/*
 * LeoCol process snapshot interface.
 *
 * This small interface exposes conservative process observations for probes,
 * later journal writers, and eventually LeoColAgent.
 */

#ifndef LEO_COL_PROCESS_SNAPSHOT_H
#define LEO_COL_PROCESS_SNAPSHOT_H

#include <sys/types.h>

#define LEO_COL_TIMESTAMP_SIZE 64
#define LEO_COL_PROCESS_NAME_SIZE 64
#define LEO_COL_EXECUTABLE_HINT_SIZE 1024

typedef struct LeoColProcessSnapshotRow {
    char observed_at[LEO_COL_TIMESTAMP_SIZE];
    pid_t pid;
    pid_t ppid;
    uid_t uid;
    char process_name[LEO_COL_PROCESS_NAME_SIZE];
    char executable_hint[LEO_COL_EXECUTABLE_HINT_SIZE];
} LeoColProcessSnapshotRow;

typedef int (*LeoColProcessSnapshotCallback)(const LeoColProcessSnapshotRow *row,
                                             void *context);

int leocol_process_snapshot_each(LeoColProcessSnapshotCallback callback,
                                 void *context);

#endif
