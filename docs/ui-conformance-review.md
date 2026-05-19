# LeoCol UI Conformance Review

## Purpose

This document reviews the LeoCol Cocoa viewer against the intended Cupertino-2009 Leopard application style.

The goal is not to invent a custom layout.

The goal is to move LeoCol toward native Leopard conventions.

## Current state

LeoCol currently uses a programmatic Cocoa window with:

- process table,
- search field,
- reload button,
- evidence button,
- fixed process detail inspector,
- bottom status line.

The viewer is functional, but the top control row is still laid out manually inside the content view.

## Findings

### Search field placement

The search field is currently placed in the content view.

For a Leopard-style system utility, the search field should live in the window toolbar, aligned to the right.

Expected direction:

```text
NSToolbar:
  Reload
  Evidence Summary
  Flexible Space
  Search Field
````

### Toolbar/titlebar integration

The current viewer does not use a native NSToolbar.

This creates a visual separation between the titlebar and the manually placed top controls.

The correct fix is not custom color drawing.

The correct fix is to use NSWindow with NSToolbar and let Leopard draw the unified toolbar/titlebar appearance.

### Fonts

Normal UI controls should use system defaults.

The process detail inspector may use a fixed-pitch font because it presents aligned technical key/value detail text.

### Spacing

Manual x/y placement in the top row should be reduced.

Toolbar items should own top-level actions.

The content view should primarily contain the table, detail inspector, and status line.

### Table

The process table is acceptable for V1, but should be reviewed for:

- avoiding unnecessary horizontal scrolling,
    
- better use of remaining width,
    
- stable column widths across English and German,
    
- keeping dashboard-like readability.
    

### Detail inspector

The fixed detail inspector is acceptable for V1.

It should remain read-only.

A splitter is not required for V1.

### Status line

The bottom status line is appropriate and matches the pattern of development/system tools.

## Required UI direction

LeoCol should move from:

```text
manual top controls in content view
```

to:

```text
native toolbar controls
```

## Non-goals

The UI conformance pass must not introduce:

- custom painted toolbar colors,
    
- language-specific layouts,
    
- animated dashboard effects,
    
- non-native control styles,
    
- cleanup/action buttons.
    

## Next implementation step

The next UI implementation step should be:

```text
Native NSToolbar layout
```

with:

- Reload toolbar item,
    
- Evidence Summary toolbar item,
    
- flexible spacer,
    
- right-aligned NSSearchField toolbar item.
    

