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

## Viewer usability updates

After the initial Cocoa LeoRM viewer baseline, the viewer gained:

- manual reload,
- column sorting,
- numeric PID sorting,
- an in-memory filter field,
- and explicitly read-only table cells.

The table is intentionally not editable.

A double-click on a process row must not enter edit mode because LeoCol.app currently presents collected facts and does not modify journal data.

## Filter behavior

The filter field searches the currently loaded in-memory rows.

It matches across:

- process name,
- PID,
- bundle identifier,
- classification,
- confidence.

Example filters:

```text
apple
unknown
Terminal
com.apple
HP
path-app-contained
````

Filtering does not query the database again.

Reload reads the database again, then reapplies the current filter and sort state.  


## Last seen overview column

The viewer overview uses a localized `Last Seen` / `Zuletzt` column instead of a vague observed-state label.

The stored database value remains canonical and technical.

The table presents a compact localized date/time string for readability.

The full values remain available in the Process Details inspector:

- First Seen / Zuerst gesehen
- Last Seen / Zuletzt gesehen

This keeps the overview concrete while preserving the full technical detail in the inspector.

## Localized classification display

Classification values are stored as canonical technical values in the database.

The Cocoa viewer maps known canonical classification values to localized display strings.

Examples:

- Apple system component
- Apple application
- command-line tool
- user application
- developer tool
- MacPorts tool
- observed only

This keeps the database stable while allowing the UI to present system-appropriate wording in English and German.

## Executable wording

Executable state wording is presentation-level only.

Canonical internal values remain technical.

The UI presents them as:

- Present / Vorhanden
- Not present / Nicht vorhanden
- Not reported / Nicht gemeldet
- Directory / Ordner

The wording avoids vague states such as "unknown" in the user interface.

## Localized viewer state wording

The Cocoa viewer keeps canonical technical values in the database and maps them to localized presentation strings.

Classification values are displayed through `Localizable.strings`.

Known display values include:

- Apple system component
- Apple application
- command-line tool
- user application
- developer tool
- MacPorts tool
- observed only

Executable state values are also presentation-level only.

The UI presents them as:

- Present / Vorhanden
- Not present / Nicht vorhanden
- Not reported / Nicht gemeldet
- Directory / Ordner

The viewer avoids vague wording such as `unknown` in user-facing UI.

## Localization layout rule

LeoCol uses one viewer layout for all supported languages.

Localized strings must not introduce language-specific window sizes, column positions, or UI structure.

If a localized string does not fit, the default layout should be improved for all languages.

## Provenance evidence summary

The Cocoa viewer provides a read-only provenance evidence summary.

The summary is opened through the `Evidence` / `Belege` button.

It groups records from `provenance_evidence` by:

- evidence type,
- resolution state,
- count.

The summary is intentionally informational.

It does not expose actions such as delete, disable, unload, quarantine, or repair.

This keeps the viewer aligned with LeoCol's role as a process and provenance memory, not a task manager or cleaner.
