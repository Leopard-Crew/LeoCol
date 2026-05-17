# LeoCol Cocoa Viewer

## Purpose

The LeoCol Cocoa viewer is the first native Mac OS X 10.5.8 Leopard UI for the LeoCol process journal.

It is currently a read-only viewer.

It does not collect process data itself.

## Current capability

The viewer can:

- open a native Cocoa window,
- show process lifecycle and identity rows in an `NSTableView`,
- read LeoCol data through LeoRM,
- reload the database manually,
- sort columns by clicking table headers,
- sort PID values numerically,
- show fallback rows when the database is unavailable.

## Current data source

The viewer currently reads:

```text
Probe/results/leocol-v1.db
````

For Debug builds, the application derives the project root from:

```text
App/build/Debug/LeoCol.app
```

and then resolves:

```text
Probe/results/leocol-v1.db
```

## Build

On Mac OS X 10.5.8 PowerPC:

```sh
xcodebuild -project App/LeoCol.xcodeproj -configuration Debug clean build
```

Run:

```sh
open App/build/Debug/LeoCol.app
```

## Refresh workflow

The viewer does not yet run a background collector.

To refresh data, run the probe chain externally:

```sh
Probe/build/leocol_journal_probe
Probe/build/leocol_lifecycle_probe
Probe/build/leocol_identity_probe
```

Then click:

```text
Reload
```

inside LeoCol.app.

## Columns

Current columns:

- Process
    
- PID
    
- Bundle Identifier
    
- Classification
    
- Confidence
    

## Sorting

Clicking column headers sorts the in-memory rows.

PID sorting is handled explicitly as a numeric comparison.

Other columns use case-insensitive string comparison.

## Current non-goals

The viewer does not yet include:

- LaunchAgent integration,
    
- automatic refresh,
    
- live sampling,
    
- filtering,
    
- search,
    
- process details,
    
- process control,
    
- killing or terminating processes,
    
- launchd editing,
    
- preferences,
    
- or packaging.
    

## Boundary

LeoCol.app is currently a viewer for already collected data.

It must not become a process-control tool before the journal, lifecycle, and identity model are more mature.

## Status

The Cocoa viewer can display real LeoCol data through LeoRM and can be manually refreshed after external probe runs.  

