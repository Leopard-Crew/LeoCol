# LeoCol Menu Conformance Plan

## Purpose

This document defines the planned menu conformance pass for LeoCol V1.

The goal is to make LeoCol feel like a Mac OS X Leopard utility, not like a list of appended commands.

## Current problem

LeoCol already has useful menu commands:

```text
Update Snapshot
Update Evidence
Export Report
Show Snapshots
LeoCol Help
````

However, the menu structure is still mostly functional.

For a Cupertino-2009-style utility, menu placement and grouping should reflect user intent and platform convention.

## Design rule

Menus should answer:

```text
What kind of action is this?
```

not merely:

```text
Where was this command easiest to add?
```

## Target menu shape

### LeoCol menu

Expected commands:

```text
About LeoCol
-
Hide LeoCol
Hide Others
Show All
-
Quit LeoCol
```

German:

```text
Über LeoCol
-
LeoCol ausblenden
Andere ausblenden
Alle einblenden
-
LeoCol beenden
```

Notes:

- Preferences should not be added unless LeoCol has real preferences.
    
- Services may be added later if system integration requires it.
    

### File menu

Expected commands:

```text
Update Snapshot
Update Evidence
-
Export Report...
-
Close
```

German:

```text
Momentaufnahme aktualisieren
Belege aktualisieren
-
Bericht exportieren …
-
Schließen
```

Notes:

- Update commands are explicit data-acquisition commands.
    
- Export belongs here.
    
- Close should close the main window or active panel where appropriate.
    
- Export should use an ellipsis because it opens a save panel.
    

### Edit menu

Expected commands:

```text
Copy
Select All
```

German:

```text
Kopieren
Alles auswählen
```

Notes:

- LeoCol has text/table content.
    
- Copy should work for selected table/detail content later.
    
- Even if not fully wired at first, the menu shape should be prepared deliberately.
    

### View menu

Expected commands:

```text
Show Toolbar
-
Show Snapshot Overview
Show Evidence Summary
```

German:

```text
Symbolleiste einblenden
-
Momentaufnahmen anzeigen
Belegübersicht anzeigen
```

Notes:

- Snapshot Overview and Evidence Summary are views, not file operations.
    
- Toolbar visibility belongs to View.
    
- The existing toolbar should remain native.
    

### Window menu

Expected commands:

```text
Minimize
Zoom
-
Bring All to Front
```

German:

```text
Im Dock ablegen
Zoomen
-
Alle nach vorne bringen
```

Notes:

- This makes LeoCol feel more like a proper Cocoa app.
    
- Programmatic menus should still respect native selectors where possible.
    

### Help menu

Expected commands:

```text
LeoCol Help
```

German:

```text
LeoCol Hilfe
```

Notes:

- Help opens bundled local XHTML help.
    
- No internet dependency.
    

## Command naming

Use ellipsis for commands that open another dialog or require further input:

```text
Export Report...
```

German:

```text
Bericht exportieren …
```

Do not use ellipsis for immediate actions:

```text
Update Snapshot
Update Evidence
Show Snapshot Overview
Show Evidence Summary
```

## Keyboard shortcuts

Initial candidate shortcuts:

```text
Command-E    Export Report...
Command-R    Update Snapshot
Command-?    LeoCol Help
Command-Q    Quit LeoCol
Command-W    Close
```

Caution:

- Command-R may conflict with expected reload behavior.
    
- Final shortcut choices should be tested on Leopard.
    

## Acceptance criteria

The menu conformance pass is acceptable when:

- commands are grouped by intent,
    
- View contains view/panel commands,
    
- File contains update/export/close commands,
    
- Help contains LeoCol Help,
    
- About and Quit remain in the application menu,
    
- ellipses are used correctly,
    
- menu labels are localized,
    
- no fake Preferences menu is added,
    
- no hidden background/service behavior is implied.
    

## Non-goals

This pass must not introduce:

- Preferences without real preferences,
    
- Services integration,
    
- background scheduling,
    
- daemon controls,
    
- repair/cleanup commands,
    
- destructive actions.
    

## Guiding principle

LeoCol menus should make the app feel like a calm Leopard system utility.

They should not expose implementation structure.

