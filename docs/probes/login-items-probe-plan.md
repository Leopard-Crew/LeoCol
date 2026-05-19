# Login Items Provenance Probe Plan

## Purpose

The Login Items provenance probe records user login items as local provenance evidence.

It is read-only.

It must not add, remove, disable, or repair login items.

## Motivation

Login Items can become stale references.

Example:

```text
Login item exists,
but its target path is missing.
````

This should be reported as:

```text
stale-reference
```

not as unknown.

## Evidence type

```text
login-item
```

## Evidence source

```text
System Events login items
```

## Expected fields

Each discovered login item should record:

- login item name,
    
- login item path when available,
    
- evidence source,
    
- resolution state,
    
- created timestamp.
    

## Resolution states

```text
resolved
  Login item has a path and the target exists.

stale-reference
  Login item has a path but the target is not present.

observed-only
  Login item exists but no path was reported.

unresolved
  Login item could not be inspected sufficiently.
```

## Boundary

The probe records evidence only.

It must not:

- delete login items,
    
- modify login items,
    
- launch targets,
    
- classify software as malware,
    
- or clean the system.
    

## First implementation

The first implementation may use AppleScript through System Events because this is the native Leopard-era way to inspect Login Items.  

