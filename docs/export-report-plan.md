# LeoCol Export Report Plan

## Purpose

LeoCol should provide a simple read-only export report.

The report is meant for documentation, comparison, and manual review.

It must not modify the system.

## Motivation

LeoCol is a process and provenance memory.

A user should be able to preserve the current visible state as a report.

Useful cases:

- before/after cleanup documentation,
- system inventory snapshots,
- provenance review,
- support/debugging notes,
- comparing Leopard installations.

## Initial export scope

The first export should be plain text.

It should include:

- LeoCol version,
- export timestamp,
- process row count,
- visible process rows,
- provenance evidence summary,
- database path if available.

## Initial UI

Add a File menu item:

```text
Export Report…
````

The item should open a save panel.

Default filename:

```text
LeoCol-Report.txt
```

## Format

The first format is plain text.

No PDF.

No RTF.

No custom package.

Plain text is stable, scriptable, readable, and Leopard-appropriate.

## Non-goals

The export must not:

- delete anything,
    
- quarantine anything,
    
- repair anything,
    
- hide evidence,
    
- create a cleanup recommendation,
    
- depend on network services.
    

## Later formats

Later versions may add:

- CSV process export,
    
- CSV evidence summary export,
    
- HTML report,
    
- printable report.
    

## V1 boundary

For V1, plain text export is enough.

LeoCol should export what it knows.

It should not decide what the user should do.  


## v0.11.2 implementation note

The initial export action was present in the File / Ablage menu but disabled because the menu item target did not yet have the concrete `exportReport:` implementation at runtime.

`v0.11.2-report-export-action-fix` adds the concrete export action and report generation path.

The export remains read-only.

The generated plain text report includes:

- LeoCol version,
- export timestamp,
- active filter,
- visible process rows,
- provenance evidence summary,
- read-only boundary statement.

The export action must be runtime-tested through the File / Ablage menu before tagging future export changes.
