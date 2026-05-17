# LeoRM V1 Roadmap

This roadmap defines the first useful LeoRM milestone.

V1 is not the complete LeoRM vision. V1 is the smallest coherent storage brick that proves the architecture on Mac OS X 10.5.8 Leopard / PowerPC.

## V1 goal

LeoRM V1 should allow a Leopard application or domain store to:

- open an SQLite database,
- execute prepared statements,
- bind Foundation values,
- read result rows,
- run explicit transactions,
- track schema version metadata,
- run ordered migrations,
- report errors through NSError,
- and implement small repository objects above that foundation.

## Non-goals for V1

V1 must not include:

- full ORM behavior,
- ActiveRecord-style model APIs,
- automatic schema generation,
- automatic relationship handling,
- object graph management,
- lazy faulting,
- NSPredicate-to-SQL compilation,
- hidden SQL generation,
- AppKit dependencies,
- Core Data dependencies,
- Swift / ARC / blocks requirements.

## Milestone 0: Project skeleton

Create the buildable Leopard-native project structure.

Expected output:

```text
LeoRM.xcodeproj
Sources/
  LRMError.h
  LRMError.m
Tests/
  ...
docs/
  ...
```

Requirements:

- Xcode 3.1.4 compatible,
- Mac OS X 10.5 SDK compatible,
- PowerPC compatible,
- manual retain/release,
- Foundation + libsqlite3 only.

## Milestone 1: Error foundation

Implement `LRMError`.

Expected output:

```text
LRMErrorDomain
LRMErrorMake()
LRMSQLiteErrorMake()
```

Requirements:

- consistent NSError domain,
- SQLite result code preservation,
- optional SQL string in userInfo,
- optional database path in userInfo,
- readable failure messages.

Success check:

A failing SQLite operation returns an NSError that contains enough information to debug the failure without stepping into LeoRM internals.

## Milestone 2: Database connection

Implement `LRMDatabase`.

Expected output:

```text
open
close
path
last error mapping
prepare statement
begin transaction
```

Requirements:

- explicit path ownership,
- no global singleton,
- deterministic close behavior,
- no hidden schema creation except optional LeoRM metadata helpers later.

Success check:

A small command-line test can open a database file, create a table through SQL, and close the database cleanly.

## Milestone 3: Prepared statements

Implement `LRMStatement`.

Expected output:

```text
prepare SQL
bind NSString
bind NSNumber
bind NSData
bind nil / NSNull
execute update
execute query
reset
finalize
```

Requirements:

- sqlite3_stmt lifetime handled safely,
- SQL remains visible,
- binding failures return NSError,
- finalization is deterministic.

Success check:

A test can create a table, insert rows using bound values, and report constraint errors correctly.

## Milestone 4: Result rows

Implement `LRMResultSet` and `LRMRow`.

Expected output:

```text
next
current row
object by index
object by column name
typed accessors
null detection
```

Requirements:

- predictable Foundation value mapping,
- no domain object mapping in the core row class,
- no storing all results by default,
- row lifetime documented.

Success check:

A test can insert rows and read them back as NSString, NSNumber, NSData, and null values.

## Milestone 5: Transactions

Implement `LRMTransaction`.

Expected output:

```text
begin
commit
rollback
active state
double-use protection
```

Requirements:

- explicit transaction boundaries,
- no hidden transaction starts,
- rollback remains available after failure where possible,
- nested transactions out of scope unless later implemented through savepoints.

Success check:

A test can insert rows inside a transaction, commit successfully, and verify persistence. Another test can rollback and verify that rows were not persisted.

## Milestone 6: Metadata and schema version

Implement minimal LeoRM metadata helpers.

Expected output:

```sql
CREATE TABLE IF NOT EXISTS lrm_metadata (
    key TEXT PRIMARY KEY NOT NULL,
    value TEXT
);
```

Expected helper behavior:

```text
read metadata value
write metadata value
read schema version
write schema version
```

Requirements:

- metadata table stays small,
- domain tables remain domain-owned,
- no private store format.

Success check:

A test can set and read schema version metadata from a normal SQLite database.

## Milestone 7: Migration runner

Implement `LRMSchema`, `LRMMigration`, and `LRMMigrationRunner`.

Expected output:

```text
schema name
target version
ordered migration steps
apply missing migrations
stop on error
update metadata after success
```

Requirements:

- migrations are explicit,
- failed migration stops immediately,
- version is updated only after successful migration,
- migration SQL is owned by the schema/domain layer.

Success check:

A test can migrate an empty database from version 0 to version 2 through two ordered steps.

## Milestone 8: Repository helper

Implement minimal `LRMRepository`.

Expected output:

```text
database reference
basic initialization
small helper for SQL execution
small helper for query + row mapping
```

Requirements:

- no ActiveRecord,
- no domain base class requirement,
- no automatic model magic,
- SQL remains visible.

Success check:

A test repository can insert and fetch simple plain Cocoa objects without requiring those objects to inherit from LeoRM classes.

## Milestone 9: First integration proof

Create a tiny example schema outside LeoRM core.

Possible example:

```text
Examples/NotesStore/
```

Purpose:

- prove LeoRM can support a domain store,
- avoid media-specific creep,
- keep example small and neutral.

Example domain object:

```text
Note
  id
  title
  body
  createdAt
```

Success check:

The example can create the schema, migrate it, insert a note, fetch notes, and run under Leopard.

## Testing doctrine

Tests should focus on:

- real SQLite behavior,
- real files where useful,
- error paths,
- transaction rollback,
- migration failure,
- null handling,
- manual memory management.

Do not test imagined ORM behavior that V1 does not promise.

## Completion definition

LeoRM V1 is complete when:

- the core classes build on Leopard,
- all V1 tests pass on PowerPC,
- the example store works,
- the README and docs match the actual API,
- no domain-specific media code exists in LeoRM.

## V1 release name

Suggested release tag:

```text
v0.1.0-storage-brick
```

This tag should mean:

LeoRM can be used as a small explicit SQLite Repository/DAO brick, but it is not yet a broad data framework.
