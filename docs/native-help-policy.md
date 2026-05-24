# Leopard-Crew Native Help Policy

## Status

This document records the LeoCol V0.14.8 help-system finding and defines the
recommended V1 help pattern for Leopard-Crew Cocoa GUI applications.

## Rule

Leopard-Crew V1 Cocoa applications should use a native in-app WebKit help
window for local project help.

Apple Help Viewer, Help Book registration, NSHelpManager, and Carbon Help
Manager are not the default V1 help path.

## Reason

During LeoCol hardening, the Help Viewer path repeatedly opened generic Mac
Help instead of the LeoCol help content. A generic Mac Help window is misleading
and therefore worse than no project help.

The accepted V1 path is:

- local XHTML help files
- localized Help source trees
- localized Help bundle resources
- native Cocoa NSWindow
- WebKit WebView
- project-specific menu action selector

## Source layout

~~~text
App/Help/English.lproj/<AppName> Help/
App/Help/German.lproj/<AppName> Help/
~~~

Each localized help folder should contain:

~~~text
index.html
help.css
topic pages as needed
~~~

## Bundle layout

~~~text
Contents/Resources/English.lproj/<AppName> Help/
Contents/Resources/German.lproj/<AppName> Help/
~~~

## Menu action rule

Do not use a project help action named:

~~~objc
showHelp:
~~~

Use an app-specific selector instead, for example:

~~~objc
openLeoColHelp:
openLeoClipHelp:
openLeoTransferHelp:
~~~

This avoids accidental interaction with the system Help mechanism.

## Runtime rule

The help command must never silently open generic Mac Help.

Acceptable V1 outcomes:

- localized in-app help window opens
- explicit local-file fallback opens
- visible error/status message if help files are missing

Unacceptable outcome:

- generic Mac Help opens for a project help command

## Test rule

When manually testing menu items, ensure the target application is active.

Launching a GUI app from Terminal by running:

~~~text
Contents/MacOS/AppName
~~~

may leave Terminal or Finder active for menu purposes.

Prefer:

~~~text
open App/build/Debug/AppName.app
~~~

for menu smoke tests.

Before choosing a menu item, verify that the menu bar belongs to the target app,
not Finder or Terminal.

## V2 option

A real Apple Help Book may be added later only after a dedicated minimal probe
proves reliable project-specific opening on Mac OS X 10.5.8 PowerPC.

It is not a V1 release blocker.
