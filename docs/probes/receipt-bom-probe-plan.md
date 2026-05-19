# Receipt BOM Provenance Probe Plan

## Purpose

The Receipt BOM provenance probe should map installed-package receipts to filesystem paths.

It is read-only.

It must not uninstall, delete, repair, quarantine, or modify anything.

## Motivation

Launch, login, startup, kext, and CUPS probes explain active or configured system behavior.

Receipt BOM provenance answers a different question:

```text
Which installed package originally claimed this file?
````

This is useful for distinguishing:

- package-owned files,
    
- application support files,
    
- vendor stacks,
    
- orphaned files,
    
- manually copied files,
    
- and cleanup leftovers.
    

## Leopard receipt model

Mac OS X Leopard commonly stores installer receipts in:

```text
/Library/Receipts
```

Many receipts are package bundles such as:

```text
Something.pkg
```

Inside package receipts, Bill of Materials files may appear as:

```text
Contents/Archive.bom
```

The native Leopard tool for inspecting BOM files is:

```text
/usr/bin/lsbom
```

## Evidence type

```text
receipt-bom
```

## Evidence source

Examples:

```text
/Library/Receipts
/Library/Receipts/*.pkg/Contents/Archive.bom
/usr/bin/lsbom
```

## First implementation scope

The first probe should not index the whole filesystem.

It should only inventory receipt BOMs and store package evidence.

Recommended first step:

1. enumerate `/Library/Receipts/*.pkg`,
    
2. find `Contents/Archive.bom`,
    
3. run `lsbom`,
    
4. count contained paths,
    
5. store one evidence row per receipt,
    
6. store summary evidence, not every path yet.
    

## First stored evidence

Each receipt evidence row should include:

- receipt name,
    
- receipt path,
    
- BOM path,
    
- number of BOM paths,
    
- package identifier if discoverable,
    
- package version if discoverable,
    
- created timestamp.
    

## Resolution states

```text
resolved
  Receipt exists and BOM can be read.

observed-only
  Receipt exists but no BOM is present.

unresolved
  Receipt exists but BOM parsing failed.

artifact
  Receipt appears malformed or disconnected from expected structure.
```

## Not in first implementation

The first implementation should not yet:

- store every BOM path,
    
- join BOM paths to process paths,
    
- judge files as orphaned,
    
- scan the whole filesystem,
    
- delete anything,
    
- or produce cleanup recommendations.
    

## Later implementation

A later resolver can map specific observed paths to receipt owners.

Example:

```text
/Library/Printers/hp/...
  -> HP installer receipt
```

or:

```text
/Library/StartupItems/tap
  -> TunTapOSX receipt
```

## Boundary

Receipt provenance is evidence, not verdict.

A file without a receipt match is not automatically bad.

A receipt match proves package ownership, not current usefulness.

## Guiding rule

First inventory receipts.

Then resolve specific paths.

Do not build a global filesystem cleaner.  

