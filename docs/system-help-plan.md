# LeoCol System Help Plan

## Purpose

This document defines the planned user-facing help system for LeoCol V1.

LeoCol is a system observation tool with precise semantics.

It needs built-in help so users understand what the app shows and what it deliberately does not do.

## Decision

LeoCol V1 should include a bundled local help set and a Help menu item.

Initial menu:

```text
Help
  LeoCol Help
````

German:

```text
Hilfe
  LeoCol Hilfe
```

## Why help is required

LeoCol is not self-explanatory enough for a release.

Terms such as the following need explanation:

```text
Snapshot
Evidence
Current
Historical
Last seen
Observed only
Resolved
Instance
Report
```

Without help, users may misunderstand LeoCol as:

```text
live task manager
cleanup tool
repair tool
daemon monitor
security scanner
```

LeoCol is none of these.

## Help format

For V1, the preferred minimal format is bundled local HTML.

Initial location:

```text
LeoCol.app/Contents/Resources/LeoCol Help/
```

Initial files:

```text
index.html
concepts.html
snapshots.html
evidence.html
reports.html
read-only.html
```

A later pass may turn this into a fuller Apple Help Book style integration.

V1 should first prioritize clarity and local availability.

## Help menu behavior

The Help menu command should open the bundled help index.

Expected behavior:

```text
Help -> LeoCol Help
  opens bundled local help index
```

The help should not require internet access.

## Required help topics

### What is LeoCol?

Explain:

```text
LeoCol records and presents system observations from explicit snapshots.
```

Also explain:

```text
LeoCol is read-only.
LeoCol does not clean, repair, kill, unload, delete, or install.
```

### Snapshots

Explain:

```text
A snapshot is a sampled observation at one point in time.
```

Explain that LeoCol is not continuous monitoring.

### Current and Historical

Explain:

```text
Current
  seen in the newest process snapshot

Historical
  seen before, but absent from a later snapshot
```

### Last seen

Explain:

```text
Last seen means the last snapshot in which this PID was actually observed.
```

It does not mean:

```text
currently running right now
```

### Evidence

Explain that evidence is provenance information such as:

```text
LaunchAgents
LaunchDaemons
Login Items
StartupItems
Kernel extensions
CUPS queues
Receipt/BOM records
```

### Observed only and Resolved

Explain:

```text
Observed only
  LeoCol saw a reference but did not resolve it to a current filesystem object

Resolved
  LeoCol connected the observation to an existing source or path
```

### Reports

Explain that exported reports are read-only text summaries.

They are not repair scripts.

### Boundaries

Explicitly state that LeoCol does not:

```text
kill processes
delete files
clean the system
repair printers
unload kexts
modify LaunchAgents
modify Login Items
install background services
run as a daemon
```

## Tone

The help should be calm, clear, and system-tool-like.

It should not be playful or marketing-heavy.

It should feel like a small Mac OS X Leopard utility shipped with a serious purpose.

## Localization

V1 should include English and German help.

If full translation is too large for the first implementation, the help menu may initially open English help, but that is not ideal for release.

Preferred:

```text
English.lproj/LeoCol Help/
German.lproj/LeoCol Help/
```

or a simple bilingual initial help page.

## Relationship to UI

The Help menu is part of Cupertino-2009 product polish.

It should be introduced together with a menu conformance pass.

The app should not hide core concepts in documentation only; UI labels must remain honest.

## Acceptance criteria

The help system is acceptable when:

- a Help menu exists,
    
- LeoCol Help opens from the app,
    
- help is bundled locally,
    
- the help explains snapshots,
    
- the help explains current vs historical instances,
    
- the help explains Last seen,
    
- the help explains evidence states,
    
- the help states the read-only boundary,
    
- no internet connection is required.
    

## Non-goals

The help system must not:

- fetch remote documentation,
    
- depend on a website,
    
- add telemetry,
    
- add update checks,
    
- introduce a background service.
    

