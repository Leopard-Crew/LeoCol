# LeoRM Class Map

This document maps the first LeoRM building blocks before implementation starts.

The goal is to keep the V1 API small, explicit, Leopard-native, and SQLite-honest.

LeoRM is not a full ORM framework. These classes are storage helpers, not a new object world.

## Layer overview

```text
Domain Store / Application
  -> LRMRepository
    -> LRMDatabase
      -> LRMStatement / LRMResultSet / LRMRow
        -> sqlite3 / sqlite3_stmt
```

## Core classes

### LRMDatabase

Responsible for owning an SQLite database connection.

Responsibilities:

- open database at path,
- close database safely,
- expose database path,
- create prepared statements,
- begin transactions,
- report SQLite errors as NSError,
- provide low-level access only where explicitly needed.

Does not:

- define schemas,
- know domain objects,
- hide SQL,
- act as a global singleton.

Likely wraps:

```c
sqlite3 *
```

Possible API shape:

```objc
+ (id)databaseWithPath:(NSString *)path error:(NSError **)error;
- (id)initWithPath:(NSString *)path error:(NSError **)error;

- (BOOL)open:(NSError **)error;
- (void)close;

- (LRMStatement *)prepareStatement:(NSString *)sql error:(NSError **)error;
- (LRMTransaction *)beginTransaction:(NSError **)error;
```

### LRMStatement

Responsible for owning a prepared SQLite statement.

Responsibilities:

- prepare SQL,
- bind values,
- step through execution,
- reset statement,
- finalize statement,
- expose SQL for debugging.

Does not:

- generate SQL,
- map rows into domain objects,
- own transactions.

Likely wraps:

```c
sqlite3_stmt *
```

Possible API shape:

```objc
- (BOOL)bindObject:(id)value atIndex:(NSInteger)index error:(NSError **)error;
- (BOOL)execute:(NSError **)error;
- (LRMResultSet *)executeQuery:(NSError **)error;
- (void)reset;
- (void)finalizeStatement;
```

### LRMResultSet

Responsible for iterating over rows returned by a query.

Responsibilities:

- advance to next row,
- provide the current row,
- close/finalize when finished,
- report step errors.

Does not:

- store all rows by default,
- map objects automatically,
- hide column names or indexes.

Possible API shape:

```objc
- (BOOL)next:(NSError **)error;
- (LRMRow *)currentRow;
- (void)close;
```

### LRMRow

Responsible for reading typed values from the current SQLite row.

Responsibilities:

- read values by column index,
- read values by column name where available,
- convert SQLite values to Foundation values,
- expose null handling clearly.

Does not:

- know domain classes,
- validate domain rules,
- retain statement lifetime beyond its valid scope.

Possible API shape:

```objc
- (id)objectForColumn:(NSString *)name;
- (id)objectAtIndex:(NSInteger)index;

- (NSString *)stringForColumn:(NSString *)name;
- (NSNumber *)numberForColumn:(NSString *)name;
- (NSData *)dataForColumn:(NSString *)name;
- (BOOL)isNullForColumn:(NSString *)name;
```

### LRMTransaction

Responsible for explicit transaction boundaries.

Responsibilities:

- begin transaction,
- commit transaction,
- rollback transaction,
- report errors,
- prevent double commit / rollback where possible.

Does not:

- silently start transactions,
- hide write boundaries,
- implement nested transactions in V1.

Possible API shape:

```objc
- (BOOL)commit:(NSError **)error;
- (BOOL)rollback:(NSError **)error;
- (BOOL)isActive;
```

Nested transaction behavior is out of scope for V1 unless implemented through documented SQLite savepoints.

### LRMSchema

Responsible for describing schema metadata.

Responsibilities:

- expose schema name,
- expose target version,
- provide migration list,
- identify LeoRM metadata keys.

Does not:

- define domain schemas inside LeoRM,
- generate application tables automatically.

Possible API shape:

```objc
- (NSString *)schemaName;
- (NSInteger)targetVersion;
- (NSArray *)migrations;
```

### LRMMigration

Responsible for one explicit schema migration step.

Responsibilities:

- define source version,
- define target version,
- execute migration SQL or callback,
- report failure through NSError.

Does not:

- infer migrations automatically,
- hide destructive changes,
- know application semantics beyond the migration owner.

Possible API shape:

```objc
- (NSInteger)fromVersion;
- (NSInteger)toVersion;
- (BOOL)applyToDatabase:(LRMDatabase *)database error:(NSError **)error;
```

### LRMMigrationRunner

Responsible for applying migrations in order.

Responsibilities:

- read current schema version,
- compare against target version,
- run missing migrations,
- update metadata after successful migration,
- stop on first failure.

Does not:

- invent migrations,
- skip failed migrations,
- modify domain tables except through supplied migration steps.

Possible API shape:

```objc
- (BOOL)migrateDatabase:(LRMDatabase *)database
                 schema:(LRMSchema *)schema
                  error:(NSError **)error;
```

### LRMRepository

Base class or helper for DAO-style access.

Responsibilities:

- hold database reference,
- centralize SQL for one table or aggregate,
- provide small query/update methods,
- map rows to domain objects through explicit code.

Does not:

- become ActiveRecord,
- require domain objects to inherit from LeoRM classes,
- hide SQL as the default model.

Possible API shape:

```objc
- (id)initWithDatabase:(LRMDatabase *)database;
- (NSArray *)findWhere:(NSString *)whereSQL
             arguments:(NSArray *)arguments
                 error:(NSError **)error;
```

Subclasses or domain repositories should implement object mapping.

### LRMError

Responsible for consistent error reporting.

Responsibilities:

- define LeoRM error domain,
- map SQLite result codes,
- include SQL and database path where useful,
- preserve underlying SQLite message.

Possible API shape:

```objc
extern NSString * const LRMErrorDomain;

NSError *LRMErrorMake(NSInteger code, NSString *message);
NSError *LRMSQLiteErrorMake(sqlite3 *db, NSString *sql);
```

## Foundation value mapping

Recommended V1 mapping:

```text
SQLITE_TEXT    -> NSString
SQLITE_INTEGER -> NSNumber
SQLITE_FLOAT   -> NSNumber
SQLITE_BLOB    -> NSData
SQLITE_NULL    -> nil or NSNull, depending on method contract
```

Date handling is explicit and not magical in V1.

## V1 dependency rule

LeoRM V1 should depend on:

- Foundation.framework,
- libsqlite3,
- Objective-C runtime available on Leopard.

LeoRM V1 should not require:

- AppKit,
- Core Data,
- Cocoa Bindings,
- Swift,
- ARC,
- blocks,
- Grand Central Dispatch,
- modern package managers.

## Naming rule

Public classes use the `LRM` prefix.

Internal helper functions may use the `LRM` prefix as well.

No domain-specific prefix belongs in LeoRM.

## Implementation order

Recommended implementation order:

1. LRMError
2. LRMDatabase
3. LRMStatement
4. LRMResultSet
5. LRMRow
6. LRMTransaction
7. LRMSchema / LRMMigration
8. LRMMigrationRunner
9. LRMRepository

This order keeps the low-level SQLite bridge testable before repository helpers are added.
