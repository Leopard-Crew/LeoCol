# LeoCol HeaderDoc Audit Plan

## Purpose

This document defines the HeaderDoc audit required before LeoCol V1 release.

LeoCol should ship with clearly documented public Objective-C headers while avoiding fake API documentation for purely private implementation details.

## Scope

The audit covers LeoCol's application headers:

```text
LCAppDelegate.h
LCDateFormatting.h
LCOperationPanel.h
LCPresentation.h
LCProcessStore.h
LCProvenanceStore.h
LCSnapshotStore.h
LCStoreSupport.h
LCString.h
````

LeoRM headers are audited in the LeoRM brick itself and are not duplicated here.

## Goal

Each public header should answer:

```text
What does this class or function do?
What is its boundary?
What does the caller own?
What does the caller not own?
What is read-only?
What is Leopard-specific?
```

## Required HeaderDoc elements

### Class headers

Class headers should use:

```text
@class
@abstract
@discussion
```

### Method headers

Public methods should use:

```text
@method
@abstract
@param
@result
@discussion when needed
```

`@result` is required for methods that return meaningful values.

### Function headers

C functions should use:

```text
@function
@abstract
@param
@result
```

## What should not be over-documented

Do not expose private implementation structure as public API.

Avoid documenting:

```text
private ivar meaning beyond necessary class boundary
internal SQL details
temporary UI construction details
implementation-only helper behavior
```

## Special checks

### Read-only boundary

Headers involved in stores, probes, or reports must not imply cleanup or repair behavior.

### LeoRM boundary

Store headers should make clear that LeoCol uses LeoRM for app-side storage access while domain meaning remains in LeoCol.

### Help and menu boundary

AppDelegate documentation should not pretend to be a reusable framework API.

It is an app delegate.

### Manual memory management

Where ownership matters, documentation should remain compatible with manual retain/release Cocoa.

## Build output

A later implementation should generate HeaderDoc output into:

```text
Documentation/HeaderDoc/LeoCol/
```

or a similar release documentation path.

## Acceptance criteria

The HeaderDoc audit is complete when:

- every public LeoCol header has class/function documentation,
    
- every public method has at least an abstract,
    
- parameters are documented,
    
- return values are documented where applicable,
    
- read-only boundaries are clear,
    
- no fake public API is invented,
    
- HeaderDoc generation succeeds on Leopard or the limitation is documented.
    

## Non-goals

This audit must not:

- document every private method in `.m` files,
    
- turn LeoCol into a framework,
    
- expose internal SQL as public API,
    
- duplicate LeoRM API documentation,
    
- block release for non-public implementation helpers.  
    

