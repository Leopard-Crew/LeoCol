# LeoCol App Icon and Release Package Plan

## Purpose

LeoCol should become a complete Leopard application bundle with a proper application icon and a simple release package.

## Motivation

LeoCol already has:

- stable bundle identifier,
- versioned Info.plist,
- localized About panel,
- localized report export,
- native toolbar,
- read-only provenance viewer.

The next product step is visible application identity and distributable packaging.

## App icon

LeoCol should have a Leopard-appropriate application icon.

The icon should communicate:

- collection,
- observation,
- provenance,
- system memory,
- read-only inspection.

It should not imply:

- cleaning,
- deletion,
- malware scanning,
- repair,
- aggressive system control.

## Icon format

The application bundle should use:

```text
LeoCol.icns
````

The Info.plist should reference:

```text
CFBundleIconFile = LeoCol.icns
```

## Icon tooling

Preferred Leopard-compatible tooling:

```text
Icon Composer.app
tiff2icns
sips
```

## Release package

The first release package should be simple.

Preferred initial formats:

```text
LeoCol.app
LeoCol-vX.Y.Z.zip
```

A DMG can follow later.

## Release contents

A release archive should include:

```text
LeoCol.app
README
LICENSE if present
release notes
```

## Non-goals

The release package must not include:

- installers,
    
- privileged helpers,
    
- launch daemons,
    
- automatic startup items,
    
- cleanup scripts,
    
- system modification tools.
    

## Boundary

LeoCol remains a read-only viewer and evidence tool.

The release package should make it easy to run LeoCol, not install system components.  

