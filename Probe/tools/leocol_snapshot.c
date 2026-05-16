/*
 * LeoCol process snapshot probe.
 *
 * This tool prints conservative process observations as tab-separated text.
 */

#include "leocol_process_snapshot.h"

#include <errno.h>
#include <stdio.h>
#include <string.h>

static int
leocol_print_tsv_row(const LeoColProcessSnapshotRow *row, void *context)
{
    FILE *stream;

    stream = (FILE *)context;

    if (row == NULL || stream == NULL) {
        errno = EINVAL;
        return -1;
    }

    fprintf(stream,
            "%s\t%d\t%d\t%u\t%s\t%s\n",
            row->observed_at,
            (int)row->pid,
            (int)row->ppid,
            (unsigned int)row->uid,
            row->process_name,
            row->executable_hint);

    return 0;
}

int
main(void)
{
    int result;

    printf("observed_at\tpid\tppid\tuid\tprocess_name\texecutable_hint\n");

    result = leocol_process_snapshot_each(leocol_print_tsv_row, stdout);

    if (result != 0) {
        fprintf(stderr,
                "leocol_snapshot: failed to read process snapshot: %s\n",
                strerror(errno));
        return 1;
    }

    return 0;
}
