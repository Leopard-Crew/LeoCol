# LeoCol LRMRepository Refactor Findings

## Purpose

This document records the LeoCol store refactor that promoted LRMRepository from unused linked LeoRM component to active application storage helper.

## Background

LeoCol is the first real application-level consumer of LeoRM.

Before this refactor, LeoCol already used:

```text
LRMDatabase
LRMStatement
LRMResultSet
LRMRow
````

The app stores prepared statements directly through LRMDatabase.

That was valid LeoRM usage, but it did not exercise the repository helper path.

## Change

The Cocoa store classes now use LRMRepository for row-returning queries.

Affected stores:

```text
LCProcessStore
LCProvenanceStore
LCSnapshotStore
```

They still keep SQL visible.

They still perform explicit row-to-dictionary mapping in LeoCol.

No domain mapping was moved into LeoRM.

## Current store shape

The current storage path is:

```text
LCStoreSupport
  opens LRMDatabase

Store class
  creates LRMRepository
  asks for LRMResultSet
  maps LRMRow values into LeoCol dictionaries
```

## Why this is appropriate

LRMRepository is a minimal DAO-style helper.

It reduces prepare/bind/query boilerplate without hiding SQL and without becoming ActiveRecord.

This matches the LeoCol/LeoRM architecture rule:

```text
LeoRM handles storage mechanics.
LeoCol owns domain meaning.
SQL remains visible.
```

## What this validates in LeoRM

LeoCol now validates:

```text
LRMDatabase open/close
LRMRepository creation from open database
LRMRepository resultSetForSQL:arguments:error:
LRMResultSet iteration
LRMRow typed column access
NSError plumbing through the query path
manual retain/release integration in a real Cocoa app
```

## What remains intentionally unused

### Transactions

The Cocoa app layer remains read-oriented.

No app-side LRMTransaction usage is required for V1.

Probe tools perform database writes and remain outside LeoRM for now.

### Migrations

The app is not responsible for schema creation or schema migration in V1.

LRMMigrationRunner is therefore not a V1 release blocker.

### Metadata

LeoRM metadata is not required for V1.

It may become useful later for schema/version diagnostics.

## Boundary

The C/Objective-C probe tools may continue to use sqlite3 directly.

This is intentional.

The LeoRM consumer boundary is the Cocoa app layer, not every helper tool.

## Result

The refactor strengthens LeoCol as LeoRM's first real proving ground.

It confirms that LRMRepository is useful without inflating LeoRM into a heavy ORM.

## Follow-up candidates

Possible later improvements:

```text
shared read-only query helper
better NSError-to-status diagnostics
optional schema metadata display
small LeoRM integration smoke test in LeoCol docs
```

These are not immediate release blockers.

## Conclusion

The LRMRepository refactor is successful when:

- all three app stores still load correctly,
    
- SQL remains visible in the store classes,
    
- no raw sqlite3 is introduced into the app layer,
    
- no domain mapping is moved into LeoRM,
    
- LeoCol remains read-only and explicit.  
    

