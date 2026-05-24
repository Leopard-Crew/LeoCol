# LeoCol App Product Polish Findings

## Status

This document records the V0.15 app product polish findings.

## Summary

LeoCol now has a visible application identity suitable for the next release
preparation pass.

The V0.15 pass confirmed:

- localized native in-app help window
- visible application icon
- icon asset baseline in the repository
- icon integrated into the application bundle
- versioned bundle identity

## Application icon

The LeoCol icon assets are stored under:

~~~text
assets/images/
~~~

The final application icon is:

~~~text
assets/images/LeoCol.icns
~~~

The Xcode project copies the icon into the built application bundle, and
Info.plist declares:

~~~text
CFBundleIconFile = LeoCol.icns
~~~

## Runtime finding

The icon appears for the built LeoCol application in Finder.

## Help finding

LeoCol uses the native localized WebKit help window defined during the V0.14
hardening pass.

The accepted help path remains:

~~~text
native in-app WebKit help window
~~~

not Apple Help Viewer.

## Release impact

This pass improves product presentation but does not change LeoCol's operating
boundary.

LeoCol remains:

- read-only
- manually operated
- non-daemonized
- non-mutating
- non-certifying

## Next release preparation

The next suitable block is release packaging:

- Release build
- bundled probes
- bundled localized help
- bundled application icon
- version check
- DMG or archive preparation
- checksum generation
