# LeoCol App Product Polish Plan

## Purpose

This document lists the remaining product-level work needed to make LeoCol feel like a complete Cupertino-2009 Leopard tool.

LeoCol already has process observation, provenance probes, localization, HeaderDoc comments, and a working Cocoa viewer.

The next work is app completeness.

## Product polish targets

### App identity

LeoCol should have:

- stable bundle identifier,
- stable version string,
- localized InfoPlist metadata,
- application icon,
- readable About panel.

### Menu structure

LeoCol should provide a Leopard-appropriate menu structure:

```text
LeoCol
  About LeoCol
  Preferences…
  Quit LeoCol

File
  Update Snapshot
  Update Evidence
  Export Report…

View
  Reload
  Show Evidence Summary
  Clear Filter

Help
  LeoCol Help
````

Initial menu items may be disabled or documented placeholders if the backing behavior is not implemented yet.

### About panel

The About panel should clearly state:

```text
LeoCol
Read-only process and provenance memory for Mac OS X Leopard
```

It should not present LeoCol as a task manager, cleaner, uninstaller, repair tool, or malware scanner.

### Preferences

V1 preferences should remain minimal.

Possible initial preferences:

- database path display,
    
- read-only mode indicator,
    
- language follows system,
    
- evidence update policy.
    

Preferences should not introduce cleanup actions.

### Evidence UI

The current Evidence / Belege alert works as a validation step.

For product polish, it should eventually become a read-only NSPanel or utility window with a table.

Columns:

- Evidence Type
    
- Resolution State
    
- Count
    

### Export

V1 should eventually provide a simple report export.

Initial formats:

- plain text
    
- CSV
    

Export is read-only and should not alter system state.

### Help

LeoCol should eventually include a small Help Book or help document explaining:

- process observations,
    
- provenance evidence,
    
- resolution states,
    
- what LeoCol does not do,
    
- how to interpret stale references and artifacts.
    

## Non-goals

Product polish must not add:

- process killing,
    
- file deletion,
    
- automatic quarantine,
    
- remote reputation lookup,
    
- malware verdicts,
    
- cleanup recommendations disguised as evidence.
    

## Guiding product rule

LeoCol should feel like a careful Leopard system utility:

```text
calm
read-only
localized
explanatory
deterministic
native
```


