# LeoCol Cocoa App Structure

## Purpose

The Cocoa viewer is intentionally split into small, focused units.

The goal is to keep `main.m` from becoming a combined UI, storage, localization, and presentation layer.

## Current files

### main.m

Owns the current programmatic Cocoa UI:

- application startup
- window construction
- table view
- filter field
- reload action
- sorting
- selection handling
- process detail inspector

### LCString

Small localization helper.

Resolves user-facing strings through:

```text
Localizable.strings
````

### LCPresentation

Maps canonical technical values to localized presentation strings.

Examples:

- internal `unknown` classification -> localized observed-only wording
    
- executable state values -> localized viewer wording
    
- canonical classification values -> localized display values
    

The database values remain canonical and technical.

### LCProcessStore

Owns process-row loading from the LeoCol database.

Responsibilities:

- derive the current debug database path
    
- open the LeoRM-backed SQLite store
    
- query lifecycle and identity rows
    
- build row dictionaries for the viewer
    
- provide fallback rows when needed
    
- check executable path presence with Foundation
    

## Boundary

`main.m` should not directly know how LeoRM queries are built.

`LCProcessStore` should not know about AppKit widgets.

`LCPresentation` should not change stored data.

`LCString` should remain a small localization helper.

## Status

This structure is the v0.8 app cleanup baseline.  


## v0.8.2 App delegate extraction

The Cocoa application delegate has been moved out of `main.m`.

`main.m` is now only responsible for:

- creating the autorelease pool,
- creating the shared NSApplication,
- creating the LeoCol app delegate,
- assigning the delegate,
- running the application.

`LCAppDelegate` owns the current programmatic Cocoa UI:

- window construction,
- reload button,
- filter field,
- process table,
- process detail inspector,
- status bar,
- sorting,
- selection handling.

This keeps startup separate from the viewer implementation.
