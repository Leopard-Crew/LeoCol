# SQLite Boundaries for LeoRM

SQLite is the storage authority for LeoRM.

LeoRM exists to make SQLite safer, cleaner, and more Cocoa-friendly on Mac OS X 10.5.8 Leopard / PowerPC. It must not pretend that SQLite is not there.

SQL should remain visible, schemas should remain open, and database files should remain inspectable with normal SQLite tools.

## Core rule

LeoRM wraps SQLite pain points, not SQLite itself.

It may wrap:

- database opening and closing,
- prepared statement lifetime,
- parameter binding,
- result row access,
- transaction handling,
- schema version metadata,
- migrations,
- NSError mapping,
- common repository patterns.

It must not hide:

- table structure,
- SQL semantics,
- indexes,
- constraints,
- joins,
- transaction boundaries,
- migration history,
- database file location.

## Why SQLite stays visible

LeoRM is meant for explicit application-owned schemas.

A developer should be able to open a LeoRM-backed database in a normal SQLite tool and understand what is stored there.

This is especially important for Leopard-Crew projects because the database is not merely an implementation detail. It may become part of backup workflows, debugging, import/export, scripting, and interoperability between small native bricks.

## No private store format

LeoRM must not create a private, undocumented database format.

It may create small metadata tables for its own housekeeping, but all domain tables belong to the domain store or application.

Recommended LeoRM-owned metadata table:

```sql
CREATE TABLE IF NOT EXISTS lrm_metadata (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT
);
```

Optional future metadata may include:

- schema name,
- schema version,
- store UUID,
- creation date,
- last migration,
- LeoRM compatibility marker.

## SQL first, helpers second

LeoRM V1 should prefer explicit SQL with bindings.

Good:

```objc
[repository findWhere:@"kind = ?" arguments:arguments error:&error];
```

Good:

```objc
LRMStatement *statement = [db prepare:@"SELECT id, title FROM items WHERE kind = ?" error:&error];
[statement bindString:@"episode" atIndex:1 error:&error];
```

Not V1:

```objc
[Episode where:@{ @"kind": @"episode" }];
```

Not V1:

```objc
[Episode all];
```

Those higher-level conveniences may be studied later, but they must not become the foundation of LeoRM.

## Prepared statements

Prepared statements are a core LeoRM responsibility.

LeoRM should make the safe path easy:

- prepare once where useful,
- bind values explicitly,
- step rows predictably,
- finalize statements reliably,
- report SQLite errors through NSError.

The caller should not have to manually manage every sqlite3_stmt lifetime in normal use.

## Transactions

Transactions must be explicit.

LeoRM should provide small transaction helpers, but it should never hide transaction boundaries in surprising ways.

Preferred model:

```objc
LRMTransaction *transaction = [database beginTransaction:&error];

if (!error) {
    // Perform repository work.
    [transaction commit:&error];
}
```

Rollback must be visible and reliable.

Nested transaction behavior should not be invented casually. If needed later, it should be based on SQLite savepoints and documented clearly.

## Migrations

Migrations are part of the database contract.

LeoRM should provide a migration runner, but the migration SQL belongs to the owner of the schema.

For example:

- LeoRM may run migrations.
- LeoMediaStore defines media schema migrations.
- An application defines its own application schema migrations.

LeoRM should track which migrations have been applied and stop with a visible NSError if a migration fails.

## Concurrency

LeoRM should be conservative.

SQLite allows multiple readers but only one writer at a time. LeoRM should not promise a concurrency model beyond what it can implement and test on Leopard / PowerPC.

For V1:

- avoid shared mutable database objects across threads,
- document thread ownership clearly,
- prefer one connection per controlled access path,
- serialize writes where needed,
- keep main-thread UI responsiveness as an application concern.

A future queue or coordinator may be added only if it can be implemented cleanly on Leopard without modern runtime assumptions.

## Data types

LeoRM should map SQLite values to Foundation types predictably.

Recommended mapping:

- SQLITE_TEXT -> NSString
- SQLITE_INTEGER -> NSNumber
- SQLITE_FLOAT -> NSNumber
- SQLITE_BLOB -> NSData
- SQLITE_NULL -> NSNull or nil depending on API contract

Date handling must be explicit.

LeoRM should not silently invent one universal date format without documenting it. Domain stores may choose their own convention.

## Constraints and indexes

LeoRM should not replace SQLite constraints with Objective-C-only checks.

Database constraints are part of the schema contract.

Domain stores should use:

- PRIMARY KEY,
- NOT NULL,
- UNIQUE,
- FOREIGN KEY where appropriate,
- indexes for query performance.

LeoRM may help report constraint failures, but it should not hide them.

## Foreign keys

SQLite foreign key behavior depends on SQLite version and settings.

LeoRM must not assume foreign key enforcement is active unless it explicitly enables and verifies it.

If LeoRM adds foreign key support, it must document:

- whether PRAGMA foreign_keys is used,
- whether Leopard's system SQLite supports the required behavior,
- what happens on older SQLite versions,
- how errors are reported.

## Full text search

Full text search is useful, especially for media libraries and catalogs, but it should not be part of LeoRM V1.

FTS belongs either to:

- a later optional LeoRM helper,
- a domain store such as LeoMediaStore,
- or an application-specific schema.

LeoRM V1 should not require FTS.

## Doctrine

SQLite is not an implementation embarrassment.

SQLite is the storage contract.

LeoRM's job is to make that contract Leopard-native, explicit, inspectable, and safe.
