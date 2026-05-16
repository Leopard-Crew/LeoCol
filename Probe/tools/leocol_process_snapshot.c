/*
 * LeoCol process snapshot implementation.
 *
 * This module collects conservative process observations on Mac OS X Leopard.
 * It does not write to a database and does not resolve application identity.
 */

#include "leocol_process_snapshot.h"

#include <sys/types.h>
#include <sys/sysctl.h>
#include <sys/user.h>

#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <unistd.h>

#ifndef KERN_PROCARGS2
#define LEO_COL_HAS_PROCARGS2 0
#else
#define LEO_COL_HAS_PROCARGS2 1
#endif

static size_t
leocol_bounded_strlen(const char *text, size_t max_len)
{
    size_t i;

    if (text == NULL) {
        return 0;
    }

    for (i = 0; i < max_len; i++) {
        if (text[i] == '\0') {
            return i;
        }
    }

    return max_len;
}

static void
leocol_copy_string(char *dst, size_t dst_size, const char *src)
{
    size_t i;

    if (dst == NULL || dst_size == 0) {
        return;
    }

    dst[0] = '\0';

    if (src == NULL) {
        return;
    }

    for (i = 0; i + 1 < dst_size && src[i] != '\0'; i++) {
        dst[i] = src[i];
    }

    dst[i] = '\0';
}

static void
leocol_sanitize_tsv_field(char *text)
{
    size_t i;

    if (text == NULL) {
        return;
    }

    for (i = 0; text[i] != '\0'; i++) {
        if (text[i] == '\t' || text[i] == '\n' || text[i] == '\r') {
            text[i] = ' ';
        }
    }
}

static void
leocol_timestamp_now(char *buffer, size_t buffer_size)
{
    time_t now;
    struct tm *tm_now;

    if (buffer == NULL || buffer_size == 0) {
        return;
    }

    buffer[0] = '\0';

    now = time(NULL);
    tm_now = localtime(&now);

    if (tm_now == NULL) {
        leocol_copy_string(buffer, buffer_size, "unknown-time");
        return;
    }

    if (strftime(buffer, buffer_size, "%Y-%m-%d %H:%M:%S %z", tm_now) == 0) {
        leocol_copy_string(buffer, buffer_size, "unknown-time");
    }
}

static int
leocol_read_process_list(struct kinfo_proc **processes, size_t *process_count)
{
    int mib[3];
    size_t length;
    struct kinfo_proc *result;
    int retries;

    if (processes == NULL || process_count == NULL) {
        errno = EINVAL;
        return -1;
    }

    *processes = NULL;
    *process_count = 0;

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROC;
    mib[2] = KERN_PROC_ALL;

    length = 0;

    if (sysctl(mib, 3, NULL, &length, NULL, 0) != 0) {
        return -1;
    }

    for (retries = 0; retries < 3; retries++) {
        result = (struct kinfo_proc *)malloc(length);

        if (result == NULL) {
            return -1;
        }

        if (sysctl(mib, 3, result, &length, NULL, 0) == 0) {
            *processes = result;
            *process_count = length / sizeof(struct kinfo_proc);
            return 0;
        }

        free(result);

        if (errno != ENOMEM) {
            return -1;
        }

        length *= 2;
    }

    errno = ENOMEM;
    return -1;
}

static int
leocol_compare_process_pid(const void *left, const void *right)
{
    const struct kinfo_proc *a;
    const struct kinfo_proc *b;
    pid_t pid_a;
    pid_t pid_b;

    a = (const struct kinfo_proc *)left;
    b = (const struct kinfo_proc *)right;

    pid_a = a->kp_proc.p_pid;
    pid_b = b->kp_proc.p_pid;

    if (pid_a < pid_b) {
        return -1;
    }

    if (pid_a > pid_b) {
        return 1;
    }

    return 0;
}

static int
leocol_read_executable_hint(pid_t pid, char *buffer, size_t buffer_size)
{
#if LEO_COL_HAS_PROCARGS2
    int mib[3];
    size_t length;
    char *args;
    char *exec_path;
    size_t exec_path_max;
    size_t exec_path_len;
    long arg_max;

    if (buffer == NULL || buffer_size == 0) {
        errno = EINVAL;
        return -1;
    }

    buffer[0] = '\0';

    arg_max = sysconf(_SC_ARG_MAX);

    if (arg_max < 4096 || arg_max > 1024 * 1024) {
        arg_max = 262144;
    }

    length = (size_t)arg_max;
    args = (char *)calloc(1, length);

    if (args == NULL) {
        return -1;
    }

    mib[0] = CTL_KERN;
    mib[1] = KERN_PROCARGS2;
    mib[2] = pid;

    if (sysctl(mib, 3, args, &length, NULL, 0) != 0) {
        free(args);
        return -1;
    }

    if (length <= sizeof(int)) {
        free(args);
        errno = EINVAL;
        return -1;
    }

    exec_path = args + sizeof(int);
    exec_path_max = length - sizeof(int);
    exec_path_len = leocol_bounded_strlen(exec_path, exec_path_max);

    if (exec_path_len == 0) {
        free(args);
        errno = ENOENT;
        return -1;
    }

    leocol_copy_string(buffer, buffer_size, exec_path);
    leocol_sanitize_tsv_field(buffer);

    free(args);
    return 0;
#else
    (void)pid;
    (void)buffer;
    (void)buffer_size;

    errno = ENOTSUP;
    return -1;
#endif
}

int
leocol_process_snapshot_each(LeoColProcessSnapshotCallback callback, void *context)
{
    struct kinfo_proc *processes;
    size_t process_count;
    size_t i;
    char timestamp[LEO_COL_TIMESTAMP_SIZE];

    if (callback == NULL) {
        errno = EINVAL;
        return -1;
    }

    if (leocol_read_process_list(&processes, &process_count) != 0) {
        return -1;
    }

    qsort(processes, process_count, sizeof(struct kinfo_proc), leocol_compare_process_pid);

    leocol_timestamp_now(timestamp, sizeof(timestamp));

    for (i = 0; i < process_count; i++) {
        LeoColProcessSnapshotRow row;
        int callback_result;

        memset(&row, 0, sizeof(row));

        leocol_copy_string(row.observed_at, sizeof(row.observed_at), timestamp);

        row.pid = processes[i].kp_proc.p_pid;
        row.ppid = processes[i].kp_eproc.e_ppid;
        row.uid = processes[i].kp_eproc.e_ucred.cr_uid;

        leocol_copy_string(row.process_name,
                           sizeof(row.process_name),
                           processes[i].kp_proc.p_comm);
        leocol_sanitize_tsv_field(row.process_name);

        if (row.process_name[0] == '\0') {
            leocol_copy_string(row.process_name, sizeof(row.process_name), "-");
        }

        if (leocol_read_executable_hint(row.pid,
                                        row.executable_hint,
                                        sizeof(row.executable_hint)) != 0) {
            leocol_copy_string(row.executable_hint,
                               sizeof(row.executable_hint),
                               "-");
        }

        callback_result = callback(&row, context);

        if (callback_result != 0) {
            free(processes);
            return callback_result;
        }
    }

    free(processes);

    return 0;
}
