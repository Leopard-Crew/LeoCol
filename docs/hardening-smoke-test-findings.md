# LeoCol Hardening Smoke Test Findings

## Status

This document records the LeoCol V0.14 hardening smoke test findings after the
V0.14.7 hardening smoke test plan.

## Summary

The hardening pass found one successful failure-mode test and one real help
integration issue.

The missing helper path behaved correctly.

The Apple Help Viewer path did not behave correctly enough for LeoCol V1 and was
replaced with a native in-app WebKit help window.

## Missing helper test

### Scenario

The bundled CUPS evidence helper was temporarily hidden while the development
fallback directory was also unavailable.

### Result

LeoCol reported:

~~~text
Hilfsprogramm fehlt: leocol_cups_probe
~~~

### Finding

Pass.

The app stayed usable and reported the missing helper explicitly.

This confirms the intended V1 failure mode for missing bundled probes:

- no crash
- no silent failure
- visible missing-helper status
- operation remains controlled

## Help command test

### Scenario

The Help menu command was tested under several implementations:

- direct local file opening
- Apple Help Book registration
- NSHelpManager
- Carbon Help Manager
- native WebKit help window

### Finding

The Apple Help Viewer path was not accepted for V1.

During testing, the Help Viewer repeatedly opened generic Mac Help instead of
LeoCol project help. A generic Mac Help window is misleading and therefore worse
than no project help.

A separate tester error also clarified the manual smoke-test rule: the target
application must be active before testing menu commands. Opening the LeoCol
window from Terminal does not by itself guarantee that the menu bar belongs to
LeoCol.

### Accepted V1 solution

LeoCol now uses a native in-app WebKit help window.

The accepted implementation uses:

- localized XHTML help sources
- localized bundle resources
- an app-owned NSWindow
- WebKit WebView
- an app-specific help action
- no Apple Help Viewer dependency
- no Carbon Help Manager dependency

### Result

Pass.

The Help menu opens localized LeoCol help in a LeoCol-owned native window.

## Policy outcome

The result was generalized into:

~~~text
docs/native-help-policy.md
~~~

For Leopard-Crew V1 GUI applications, the recommended default is now:

~~~text
native in-app WebKit help window
~~~

not:

~~~text
Apple Help Viewer / NSHelpManager / Carbon Help Manager
~~~

## Manual menu test rule

When testing menu items, ensure the target application is active.

Preferred launch command for menu smoke tests:

~~~text
open App/build/Debug/LeoCol.app
~~~

Before selecting a menu item, verify that the menu bar belongs to LeoCol and not
Finder or Terminal.

## Release impact

The hardening findings do not block V1.

They improve V1 reliability by replacing a misleading Help Viewer route with a
deterministic native local help window.

## Remaining non-goals

This hardening pass does not introduce:

- daemon behavior
- background mutation
- automatic repair
- automatic cleanup
- security certification
- Apple Help Book support as a release blocker
