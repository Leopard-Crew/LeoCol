# Process Snapshot Probe

## Purpose

This probe is the first LeoCol V1 implementation step.

It prints a conservative process snapshot on Mac OS X Leopard without using SQLite, LeoRM, Cocoa, launchd, private APIs, or kernel extensions.

## Output

The probe prints tab-separated text:

```text
observed_at    pid    ppid    uid    process_name    executable_hint
````

## Field meaning

### observed_at

Timestamp of the snapshot.

This is the time the snapshot was printed, not the exact process start time.

### pid

Observed process ID.

### ppid

Observed parent process ID.

### uid

Observed user ID.

### process_name

Kernel process name from the process table.

This name may be truncated by the system.

### executable_hint

Best-effort executable path from `KERN_PROCARGS2` when available.

This field is a hint, not a guaranteed identity.

A value of `-` means LeoCol could not read it safely.

## Boundaries

The probe does not claim exact process start time, exact exit time, bundle identity, or launch cause.

It only records what can be observed safely from user space.

Unknown is an acceptable result.

## Build

```sh
Probe/tools/build_leocol_snapshot.sh
```

## Run

```sh
Probe/build/leocol_snapshot
```

## Save a sample

```sh
Probe/build/leocol_snapshot > Probe/results/process-snapshot-sample.tsv
```


