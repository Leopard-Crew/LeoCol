# Plain SQLite vs LeoRM

LeoRM does not replace SQLite.

LeoRM does not hide SQL.

LeoRM exists to remove repeated SQLite lifecycle and error-handling boilerplate from Leopard / PowerPC Objective-C projects while keeping schemas open, SQL visible, and database files inspectable with normal SQLite tools.

## The honest baseline

Plain SQLite is excellent.

It provides:

- maximum control,
- direct C-level access,
- no abstraction overhead,
- stable file format,
- wide tooling support,
- complete schema ownership.

LeoRM is not better than SQLite as a database engine.

SQLite remains the storage authority.

## The problem LeoRM solves

Plain SQLite in Objective-C repeatedly requires the same operational code in every project:

- `sqlite3_open`,
- `sqlite3_prepare_v2`,
- `sqlite3_bind_*`,
- `sqlite3_step`,
- `sqlite3_column_*`,
- `sqlite3_finalize`,
- `sqlite3_close`,
- `sqlite3_errmsg`,
- manual transaction boundaries,
- manual schema-version storage,
- manual migration discipline,
- manual NSString / NSNumber / NSData conversion,
- manual NSError bridging.

None of that is domain logic.

It is storage plumbing.

LeoRM moves that repeated plumbing into a small, tested, Leopard-native storage brick.

## Before: plain SQLite

```objc
sqlite3 *db = NULL;
sqlite3_stmt *stmt = NULL;
int rc = SQLITE_OK;

rc = sqlite3_open("/tmp/plain-notes.sqlite", &db);
if (rc != SQLITE_OK) {
    fprintf(stderr, "open failed: %s\n", sqlite3_errmsg(db));
    if (db != NULL) {
        sqlite3_close(db);
    }
    return 1;
}

rc = sqlite3_prepare_v2(db,
                        "INSERT INTO notes (title) VALUES (?)",
                        -1,
                        &stmt,
                        NULL);
if (rc != SQLITE_OK) {
    fprintf(stderr, "prepare failed: %s\n", sqlite3_errmsg(db));
    sqlite3_close(db);
    return 1;
}

rc = sqlite3_bind_text(stmt, 1, "Plain SQLite note", -1, SQLITE_TRANSIENT);
if (rc != SQLITE_OK) {
    fprintf(stderr, "bind failed: %s\n", sqlite3_errmsg(db));
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    return 1;
}

rc = sqlite3_step(stmt);
if (rc != SQLITE_DONE) {
    fprintf(stderr, "insert failed: %s\n", sqlite3_errmsg(db));
    sqlite3_finalize(stmt);
    sqlite3_close(db);
    return 1;
}

sqlite3_finalize(stmt);
sqlite3_close(db);
````

This is honest SQLite code.

But every application has to repeat the same lifecycle and error-handling discipline.

## After: LeoRM

```objc
NSError *error = nil;

LRMDatabase *database = [LRMDatabase databaseWithPath:@"/tmp/leorm-notes.sqlite"
                                                error:&error];

if (database == nil || ![database open:&error]) {
    fprintf(stderr, "open failed: %s\n",
            [[[error localizedDescription] description] UTF8String]);
    return 1;
}

LRMRepository *repository = [[[LRMRepository alloc] initWithDatabase:database
                                                              error:&error] autorelease];

if (![repository executeSQL:@"INSERT INTO notes (title) VALUES (?)"
                  arguments:[NSArray arrayWithObject:@"LeoRM note"]
                      error:&error]) {
    fprintf(stderr, "insert failed: %s\n",
            [[[error localizedDescription] description] UTF8String]);
    return 1;
}

[database close];
```

SQL is still visible.

The schema is still owned by the application or domain store.

The database is still SQLite.

LeoRM only standardizes the repeated error, binding, lifecycle, row, transaction, and migration mechanics.

## What LeoRM standardizes

|Plain SQLite concern|LeoRM surface|
|---|---|
|`sqlite3_open` / `sqlite3_close`|`LRMDatabase`|
|`sqlite3_prepare_v2`|`LRMStatement`|
|`sqlite3_bind_*`|`bindObject:atIndex:error:` / repository arguments|
|`sqlite3_step`|`executeUpdate:` / `LRMResultSet next:`|
|`sqlite3_column_*`|`LRMRow`|
|`sqlite3_finalize`|`finalizeStatement` / `LRMResultSet close`|
|`sqlite3_errmsg`|`NSError` with `LRMErrorDomain`|
|`BEGIN` / `COMMIT` / `ROLLBACK`|`LRMTransaction`|
|schema-version table|LeoRM metadata helpers|
|ordered migration loop|`LRMMigrationRunner`|
|DAO helper pattern|`LRMRepository`|

## What LeoRM deliberately does not do

LeoRM does not:

- generate hidden SQL,
    
- own domain objects,
    
- require ActiveRecord-style inheritance,
    
- replace Core Data,
    
- hide the SQLite file,
    
- invent schemas,
    
- perform schema diffing,
    
- add media-specific logic,
    
- depend on AppKit,
    
- require ARC, Swift, blocks, or modern package managers.
    

If a feature knows what the data means, it belongs above LeoRM.

## Why this matters on Leopard / PowerPC

Leopard / PowerPC projects should avoid unnecessary dependency weight and modern runtime assumptions.

LeoRM is shaped for:

- Mac OS X 10.5.8 Leopard,
    
- PowerPC,
    
- Objective-C,
    
- Foundation,
    
- libsqlite3,
    
- manual retain/release,
    
- Xcode 3.1.4-era tooling.
    

It is small enough to audit and explicit enough to debug.

## The value proposition

Plain SQLite gives maximum control.

LeoRM keeps that control while reducing repeated boilerplate and failure-prone lifecycle code.

The practical benefit is:

- less duplicated storage code,
    
- fewer forgotten finalizers,
    
- fewer inconsistent error paths,
    
- fewer ad-hoc migration systems,
    
- fewer transaction mistakes,
    
- more consistent Foundation value conversion,
    
- more reusable storage discipline across Leopard-Crew projects.
    

## The short pitch

Plain SQLite remains the truth.

LeoRM is the Leopard-native discipline layer around it.  

