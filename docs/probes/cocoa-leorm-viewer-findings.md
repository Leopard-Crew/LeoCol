# Cocoa LeoRM Viewer Findings

## Test system

The first Cocoa LeoRM-backed LeoCol viewer was built successfully on Mac OS X 10.5.8 PowerPC.

## Result

The LeoCol Cocoa application can now build as a native Leopard app and read real LeoCol journal data through LeoRM.

Confirmed behavior:

- Xcode 3.1.4 builds the app target,
- the app target compiles LeoRM sources directly,
- the app links against `libsqlite3`,
- the app opens a native Cocoa window,
- the app uses `NSTableView`,
- the app loads process lifecycle and identity rows from `Probe/results/leocol-v1.db`,
- fallback rows remain available when the database is missing.

## Boundary

This is a viewer milestone.

It does not yet include:

- background collection,
- LaunchAgent integration,
- live refresh,
- process control actions,
- filtering,
- search,
- sorting,
- or user preferences.

## Interpretation

LeoCol now has a visible native Leopard UI over the proven data path:

```text
Leopard process table
  -> process observations
  -> SQLite journal
  -> lifecycle approximation
  -> identity enrichment
  -> LeoRM-backed Cocoa viewer
````

## Status

The Cocoa LeoRM viewer baseline is successful.  

