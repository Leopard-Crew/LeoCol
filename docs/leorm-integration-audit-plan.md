# LeoCol LeoRM Integration Audit Plan

## Purpose

LeoCol is the first real application-level consumer of LeoRM.

This document defines the audit needed before LeoCol V1 release.

The goal is to ensure that LeoCol does not merely compile against LeoRM, but uses LeoRM as a meaningful validation of the storage brick.

## Background

LeoRM is intended as a small Mac OS X 10.5.8 Leopard / PowerPC verified Repository/DAO layer for explicit SQLite-backed Cocoa objects.

Its design goals include:

- visible SQL,
- explicit database lifecycle,
- NSError mapping,
- prepared statements,
- result sets,
- row access,
- explicit transactions,
- metadata helpers,
- ordered migrations,
- minimal repository helpers.

LeoCol should act as LeoRM's first practical proving ground.

## Current state

LeoCol already uses LeoRM in the Cocoa app layer.

The process, provenance, and snapshot store classes read the SQLite database through LeoRM rather than directly through sqlite3.

This is good.

However, LeoCol has not yet been audited as a full LeoRM integration test.

## Boundary

The C probe tools may continue to use sqlite3 directly.

That is intentional.

The probes are small command-line data collectors and database updaters.

The Cocoa application layer should be the LeoRM consumer.

## Audit questions

### Store consistency

Check whether all Cocoa-side database reads go through LeoRM.

Expected store classes:

```text
LCProcessStore
LCProvenanceStore
LCSnapshotStore
````

No App-layer code should use raw sqlite3 directly unless explicitly justified.

### DB path ownership

Check whether database path logic is duplicated.

If multiple stores compute the same project-relative database path, consider extracting a shared helper.

Possible direction:

```text
LCDatabasePath
LCStoreSupport
LCLeoColStore
```

### Error reporting

Check whether LeoRM NSError values are surfaced properly.

The UI should not collapse all failures into generic messages when LeoRM provides more useful context.

### Row mapping

Check whether row dictionary construction is consistent.

If repeated patterns emerge, consider a small app-side helper, not a LeoRM core expansion.

### Transactions

Check whether the app layer performs writes.

If the app layer remains read-only, transactions may not be needed there.

Probe-side writes are outside LeoRM for now.

### Metadata and schema versioning

Check whether LeoCol should read LeoRM metadata or schema version information.

Possible use:

```text
database schema version
database provenance
last migration
LeoRM metadata sanity check
```

This must not become hidden magic.

### Migrations

Check whether LeoCol should use LRMMigrationRunner in the app layer.

For V1, schema creation and mutation may remain probe-owned.

If the app becomes responsible for database initialization later, MigrationRunner becomes relevant.

### Repository helper

Check whether LRMRepository would reduce duplication in store classes.

If it makes stores clearer, use it.

If it hides too much SQL, do not force it.

### LeoRM gaps discovered by LeoCol

Document every place where LeoCol needs awkward code because LeoRM lacks a small useful primitive.

Possible findings:

- repeated database opening pattern,
    
- repeated status mapping,
    
- repeated row dictionary mapping,
    
- missing convenience for scalar queries,
    
- missing helper for read-only query blocks.
    

Findings should feed back into LeoRM deliberately.

## Non-goals

This audit must not turn LeoRM into Core Data.

It must not hide SQL.

It must not create an ORM fantasy layer.

It must not move domain model decisions into LeoRM.

It must not force probes to use Objective-C.

## Acceptance criteria

The LeoRM integration audit is complete when:

- all Cocoa-side database access paths are listed,
    
- raw sqlite3 usage in the app layer is absent or justified,
    
- duplicated DB path logic is identified,
    
- error handling quality is assessed,
    
- use/non-use of transactions is justified,
    
- use/non-use of metadata and migrations is justified,
    
- at least one concrete LeoRM feedback list exists,
    
- release blockers are separated from future LeoRM improvements.
    

## Guiding rule

LeoCol should validate LeoRM by using it seriously.

LeoCol should not distort LeoRM into a large framework.


