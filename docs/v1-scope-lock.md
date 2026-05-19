# LeoCol V1 Scope Lock

## Purpose

LeoCol V1 is a read-only process and provenance memory for Mac OS X Leopard.

It records, displays, and explains observed processes and local system provenance evidence.

LeoCol V1 is not a task manager, cleaner, uninstaller, repair tool, or malware scanner.

## Core V1 capabilities

### Process observations

LeoCol records process snapshots and stores lifecycle information:

- process name,
- PID,
- first seen timestamp,
- last seen timestamp,
- exit observation,
- executable path when available.

### Identity resolution

LeoCol resolves process identity using local evidence such as:

- executable path,
- bundle metadata,
- bundle identifier,
- known system path classification.

### Provenance evidence

LeoCol V1 records local provenance evidence from:

- LaunchAgents,
- LaunchDaemons,
- Login Items,
- StartupItems,
- loaded kernel extensions,
- CUPS printer configuration,
- package receipts and BOM summaries.

### Viewer

The Cocoa viewer provides:

- process table,
- filter field,
- sortable columns,
- fixed read-only process detail inspector,
- localized English and German UI strings,
- bottom status line,
- read-only provenance evidence summary.

## V1 non-goals

LeoCol V1 must not:

- kill processes,
- unload kexts,
- disable services,
- delete files,
- quarantine files automatically,
- remove login items,
- modify LaunchAgents or LaunchDaemons,
- repair CUPS configuration,
- uninstall packages,
- classify software as malware,
- use remote reputation databases.

## Evidence principle

LeoCol records evidence, not verdicts.

Examples:

```text
resolved
observed-only
unresolved
stale-reference
artifact
````

These are evidence states.

They are not automatic action recommendations.

## Cleanup boundary

Manual cleanup may be informed by LeoCol evidence.

But cleanup actions remain outside LeoCol V1.

LeoCol may help identify:

- stale references,
    
- inactive artifacts,
    
- unresolved evidence,
    
- package-owned files,
    
- active configuration sources.
    

LeoCol must not perform cleanup itself in V1.

## Localization boundary

LeoCol uses one layout for all supported languages.

Localized strings must not create language-specific layouts.

If a localized string does not fit, the default layout should be improved for all languages.

## Accepted current baseline

The current iMac G5 baseline includes:

- Jotunnheim / Lexmark as the active CUPS printer configuration,
    
- TunTap / tap / tun as accepted Tunnelblick-related legacy networking components,
    
- SpeechSynthesisServer as resolved login item,
    
- Brother printer receipts as receipt-level sediment,
    
- no active Toshiba printer stack after cleanup,
    
- no HP receipt or CUPS queue found in the reviewed layers.
    

## V1 acceptance checklist

LeoCol V1 is acceptable when:

- all probes are read-only,
    
- the viewer builds on Leopard 10.5.8 PowerPC,
    
- process table loads from the LeoRM-backed store,
    
- provenance summary opens from the viewer,
    
- English and German UI labels resolve correctly,
    
- no user-facing `unknown` wording appears where a more precise evidence state exists,
    
- documentation clearly distinguishes evidence from action.
    

## Guiding sentence

LeoCol V1 should answer:

```text
What is here, when was it seen, and what local evidence explains it?
```

It should not answer by itself:

```text
Should I delete this?
```

