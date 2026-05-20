# LeoCol Menu Runtime Smoke Test

## Purpose

This document records the runtime smoke test for the Leopard menu conformance pass.

## Scope

The test verifies that LeoCol's programmatic menu structure behaves like a proper Mac OS X Leopard utility menu and does not crash on Mac OS X 10.5.8 PowerPC.

## Tested menu groups

```text
LeoCol
Ablage
Bearbeiten
Darstellung
Fenster
Hilfe
````

## Required checks

### LeoCol menu

- About opens.
    
- Hide LeoCol works.
    
- Hide Others works.
    
- Show All works.
    
- Quit LeoCol works.
    

### File menu

- Update Snapshot opens the operation panel and completes or reports warnings.
    
- Update Evidence opens the operation panel and completes or reports warnings.
    
- Export Report opens the save panel.
    
- Close closes the active window or panel where applicable.
    

### Edit menu

- Copy does not crash.
    
- Select All does not crash.
    
- Responder-chain behavior is acceptable for V1.
    

### View menu

- Show Toolbar toggles the toolbar where supported.
    
- Show Snapshot Overview opens the snapshot panel.
    
- Show Evidence Summary opens the evidence panel.
    

### Window menu

- Minimize works.
    
- Zoom works.
    
- Bring All to Front works.
    

### Help menu

- LeoCol Help opens the bundled local XHTML help.
    

## Leopard compatibility finding

The menu conformance pass must not call APIs that are unavailable on Mac OS X 10.5.8.

A previous attempt to call `setHelpMenu:` was rejected during real Leopard runtime testing and removed.

## Acceptance criteria

The menu runtime smoke test passes when:

- LeoCol starts without menu-related warnings or crashes,
    
- all menu groups are present,
    
- Help opens bundled local help,
    
- View commands open their panels,
    
- File commands remain explicit and read-only,
    
- no menu item implies cleanup, repair, or daemon behavior.  
    

