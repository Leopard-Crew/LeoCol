# LeoCol LeoRM Integration Audit Findings

## Purpose

This document records the first LeoRM integration audit for LeoCol.

LeoCol is the first real application-level consumer of LeoRM and should serve as a practical validation of the LeoRM storage brick.

## Summary

LeoCol's Cocoa application layer already uses LeoRM for database reads.

The current store classes are:

```text
LCProcessStore
LCProvenanceStore
LCSnapshotStore
````

They use:

```text
LRMDatabase
LRMStatement
LRMResultSet
LRMRow
```

This confirms that the app layer is not using raw sqlite3 directly for viewer reads.

## Raw sqlite3 boundary

The grep audit showed sqlite3 references in several places.

Important distinction:

### Acceptable sqlite3 use

The following are acceptable:

```text
bricks/LeoRM/Sources
bricks/LeoRM/Tests
bricks/LeoRM/Documentation
Probe/tools
```

Reason:

- LeoRM itself must use sqlite3 internally.
    
- LeoRM tests may exercise sqlite3 directly.
    
- Probe tools are small C/Objective-C helper tools and intentionally use sqlite3 directly.
    
- Probe tools are outside the Cocoa app storage layer.
    

### App-layer sqlite3 use

No intentional raw sqlite3 use was found in App source store code.

Observed App-side sqlite3 matches were build artifacts, linked binaries, object files, Xcode index files, and `OTHER_LDFLAGS = -lsqlite3`.

This is acceptable.

## Current LeoRM usage quality

LeoCol currently validates the core LeoRM path:

```text
open database
prepare visible SQL
execute query
iterate result set
read typed row values
close result set
close database
map rows to app dictionaries
```

This is a meaningful first integration.

## Remaining weakness: duplicated database path logic

The database path calculation is duplicated across store-related code.

This should be consolidated before V1 release.

Possible direction:

```text
LCStoreSupport
LCDatabasePath
LCLeoColStore
```

The goal is not to hide the database location.

The goal is to avoid three or more slightly different copies of the same path logic.

## Remaining weakness: repeated query boilerplate

The store classes repeat the same pattern:

```text
open database
prepare statement
execute query
iterate result set
close result set
close database
status string fallback
```

This repetition is not catastrophic, but it is the first sign that LeoCol could use LeoRM more idiomatically.

## LRMRepository opportunity

LeoRM provides `LRMRepository` as a minimal DAO-style helper.

It keeps SQL visible and does not perform ActiveRecord-style mapping.

LeoCol should evaluate whether its store classes should wrap or subclass LRMRepository.

Potential benefits:

- less repeated prepare/bind/result-set boilerplate,
    
- better test of LeoRM's repository helper,
    
- clearer separation between storage mechanics and row mapping,
    
- stronger LeoRM Nagelprobe.
    

Potential risk:

- forcing LRMRepository where it does not improve clarity.
    

Decision should be evidence-based after a small refactor probe.

## Metadata and migrations

LeoRM supports metadata and migration helpers.

LeoCol does not need to force these into V1 unless the app becomes responsible for schema creation or schema upgrades.

For now:

```text
Schema/database creation remains probe-owned.
Cocoa app remains read-oriented.
MigrationRunner is not a V1 release blocker.
```

## Transactions

The Cocoa app layer currently performs no domain writes.

Therefore app-level LRMTransaction usage is not required for V1.

Probe-side writes remain outside LeoRM for now.

## Error handling

LeoCol currently maps many database errors to user-facing status strings.

This is acceptable but not ideal.

Future hardening should preserve more LeoRM NSError detail internally or in diagnostics.

## LeoRM feedback candidates

The audit suggests possible LeoRM improvements:

```text
read-only query convenience
scalar query helper
repository-backed row iteration helper
standard NSError-to-status mapping pattern
documented app-store integration example
```

These are feedback candidates, not immediate LeoRM requirements.

## Release blocker assessment

### Not blockers

```text
Probes using sqlite3 directly
App linking libsqlite3 through LeoRM
No MigrationRunner use in V1
No Transaction use in read-only app layer
```

### Should be addressed before V1 release

```text
Document the LeoRM integration boundary
Consolidate database path logic
Decide whether LRMRepository should be used by store classes
Document any decision not to use LRMRepository
```

## Conclusion

LeoCol is already a valid first LeoRM consumer.

However, before V1 release it should become a stronger LeoRM proving ground by reducing duplicated store boilerplate and evaluating LRMRepository in the Cocoa app layer.

The guiding rule remains:

```text
Use LeoRM seriously.
Do not inflate LeoRM into Core Data.
Keep SQL visible.
Keep domain meaning in LeoCol.
```

