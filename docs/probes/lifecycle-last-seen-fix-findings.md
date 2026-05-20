# LeoCol Lifecycle Last Seen Fix Findings

## Finding

The lifecycle probe incorrectly updated `last_seen_at` when marking missing processes as exited.

This made old process instances appear as if they had been seen in the newest snapshot.

## Symptom

Restarted-looking processes such as Finder, Dock, Spotlight, AirPort Base Station Agent, and similar system components appeared twice in the viewer with the same latest `Last seen` timestamp.

One row represented the current process instance.

The other row represented an older PID that had already exited.

## Root cause

`leocol_lifecycle_probe` marked missing processes as exited and also overwrote `last_seen_at` with the current snapshot timestamp.

That was wrong.

A missing process was not observed in the current snapshot.

## Fix

When marking a process lifecycle as exited, the probe now only sets:

```text
exit_observed = 1
````

It preserves the existing `last_seen_at`.

## Correct semantics

`last_seen_at` means:

```text
last snapshot in which this PID was actually observed
```

`exit_observed = 1` means:

```text
this PID was absent from a later sampled snapshot
```

## Verification

After rebuilding and rerunning the lifecycle probe, the following query returned no rows:

```sql
WITH latest AS (
  SELECT observed_at
  FROM snapshot_run
  ORDER BY observed_at DESC, id DESC
  LIMIT 1
)
SELECT
  process_name,
  pid,
  executable_path,
  first_seen_at,
  last_seen_at,
  exit_observed
FROM process_lifecycle
WHERE exit_observed = 1
  AND last_seen_at = (SELECT observed_at FROM latest)
ORDER BY process_name, pid;
```

## Boundary

This fix does not deduplicate processes.

It only corrects lifecycle timestamp semantics.

Multiple PIDs may still be valid when multiple process instances are actually observed.  

