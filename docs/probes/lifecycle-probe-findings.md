# Lifecycle Probe Findings

## Test system

The first lifecycle rebuild probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Result

The probe can rebuild approximate process lifecycle rows from recorded `snapshot_run` and `process_observation` data.

Confirmed behavior:

- multiple snapshot runs can be processed in order,
- active process lifecycles can be inserted,
- repeated observations update `last_seen_at`,
- processes missing from a later snapshot can be marked with `exit_observed = 1`,
- lifecycle data can be rebuilt deterministically from raw observations.

## Test sequence

The successful test used three snapshot runs:

1. baseline snapshot,
2. snapshot while `/bin/sleep 8` was running,
3. snapshot after `sleep` exited.

The lifecycle probe then rebuilt `process_lifecycle`.

## Observed successful test

```text
snapshot_run count: 3
process_lifecycle count: 67
active lifecycles: 64
exit observed lifecycles: 3
````

The test process was correctly represented:

```text
process_name: sleep
exit_observed: 1
```

## Interpretation

`first_seen_at` and `last_seen_at` are sampled observation times.

They are not exact process start or exit times.

`exit_observed = 1` means that a process was present in an earlier sampled snapshot and absent from a later sampled snapshot.

## Current limitation

The lifecycle probe currently groups active lifecycles primarily by PID.

PID reuse is not solved in this probe.

This is acceptable for the current V1 proof because the goal is to validate the sampled lifecycle model before adding stronger identity keys.

Future lifecycle logic should consider:

- pid,
    
- executable path,
    
- process name,
    
- parent pid,
    
- first observed snapshot,
    
- and later bundle identity.
    

## Phase 3 status

The lifecycle rebuild probe is successful.

LeoCol can now see, remember, and approximate process lifecycles on Leopard/PPC.  

