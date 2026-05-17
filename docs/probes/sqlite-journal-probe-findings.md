# SQLite Journal Probe Findings

## Test system

The first SQLite journal probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Result

The probe can collect process observations through the reusable snapshot module and persist them into a SQLite database.

Confirmed behavior:

- `leocol_process_snapshot_each()` can feed a second tool besides the TSV snapshot probe.
- The Leopard system SQLite library can be linked successfully.
- A local LeoCol database can be created.
- `process_observation` rows can be inserted inside a transaction.
- The resulting database can be inspected with the Leopard `sqlite3` command-line tool.

## Observed sample

The first successful run inserted 63 process observations into:

```text
Probe/results/leocol-v1.db
````

A direct count query returned:

```text
63
```

The database contained executable paths for common Leopard user-session processes, including:

- loginwindow,
    
- launchd,
    
- sshd,
    
- sftp-server,
    
- AirPort Base Station Agent,
    
- ARDAgent,
    
- Spotlight,
    
- UserEventAgent,
    
- pboard,
    
- Dock.
    

## Important confirmation

LeoCol's split between snapshot collection and storage is now proven.

The same process observation module can support:

```text
leocol_snapshot
  TSV output

leocol_journal_probe
  SQLite persistence

LeoColAgent
  later periodic collection
```

## Current boundary

The journal probe only writes raw process observations.

It does not yet perform:

- lifecycle aggregation,
    
- identity resolution,
    
- bundle lookup,
    
- LaunchServices lookup,
    
- launchd relationship analysis,
    
- resource sampling,
    
- or Cocoa presentation.
    

## Phase 2 status

The SQLite journal probe is successful.

LeoCol can now collect and persist process observations on Leopard/PPC.  

