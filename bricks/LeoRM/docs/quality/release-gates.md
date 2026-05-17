# LeoRM Release Gates

LeoRM is a system brick.

A public LeoRM release must meet Cupertino-2009 quality expectations before it is advertised as suitable for use by other Leopard-Crew projects.

Version tags may mark internal milestones, but a release is not considered complete until the gates below are satisfied or explicitly marked as intentionally deferred.

## Release quality doctrine

LeoRM must be:

- deterministic,
- explicit,
- warning-free,
- documented,
- reproducible,
- tested on the target system,
- conservative in public API behavior,
- free of accidental domain logic,
- usable without guesswork.

Mac OS X 10.5.8 Leopard is frozen. Therefore LeoRM should prefer upfront correctness over repeated maintenance churn.

## Mandatory gates

### 1. Target-platform build

A release must build on:

- Mac OS X 10.5.8 Leopard,
- PowerPC,
- MacOSX10.5.sdk,
- Xcode 3.1.4-compatible toolchain,
- Foundation.framework,
- libsqlite3,
- manual retain/release.

Required command:

```sh
make clean
make
````

The build must be warning-free.

### 2. Smoke-test suite

A release must pass:

```sh
make smoke
```

Current smoke coverage must include:

- database open / close,
    
- NSError bridge,
    
- prepared statements,
    
- query result sets,
    
- row access,
    
- transactions,
    
- metadata,
    
- migrations,
    
- repository helper,
    
- neutral integration example.
    

### 3. Public API documentation

All public headers must contain HeaderDoc-style documentation.

Required command:

```sh
make apidocs
```

HeaderDoc warnings are release-blocking.

Generated HTML belongs in release artifacts, not in `main`.

### 4. Ownership documentation

Public API documentation must describe:

- returned object ownership,
    
- autoreleased vs owned results,
    
- explicit close/finalize behavior,
    
- defensive cleanup in dealloc,
    
- valid lifetime of rows and result sets,
    
- caller responsibilities.
    

### 5. Failure-path tests

A release must test expected failures, including:

- invalid database path or invalid path state,
    
- preparing invalid SQL,
    
- binding invalid argument indexes,
    
- binding unsupported object classes,
    
- executing finalized statements,
    
- using inactive transactions,
    
- missing migration steps,
    
- invalid schema versions,
    
- repository creation with a closed database.
    

Failure tests must verify that NSError is returned with useful context.

### 6. Constraint-error tests

A release must test SQLite constraint failures, including:

- NOT NULL violation,
    
- UNIQUE violation,
    
- PRIMARY KEY conflict where applicable.
    

Errors must surface through LRMErrorDomain and retain SQLite context.

### 7. Migration-failure rollback tests

A release must verify that failed migrations roll back their transaction.

Required proof:

- a migration step partially changes schema/data,
    
- a later statement in the same migration fails,
    
- the database remains at the previous schema version,
    
- partial migration side effects do not persist.
    

### 8. Edge-case binding and row tests

A release must test:

- nil binding,
    
- NSNull binding,
    
- NSData binding and reading,
    
- NSString UTF-8 text,
    
- NSNumber integer,
    
- NSNumber floating point,
    
- SQL NULL reading,
    
- missing column behavior,
    
- invalid column index behavior.
    

### 9. File-backed database example

The neutral example must not rely only on `:memory:`.

A release must include a file-backed database example or test that proves:

- file database creation,
    
- close and reopen,
    
- persisted schema version,
    
- persisted data,
    
- cleanup of test database files.
    

### 10. Memory / leak review on Leopard

A release must include a documented memory review on Leopard.

Preferred target:

```sh
leaks <process-name>
```

or an equivalent Leopard-available tool.

The release notes must record:

- tool used,
    
- command used,
    
- target executable,
    
- result,
    
- known limitations.
    

### 11. Reproducible release archive

A release must provide a reproducible archive path.

The archive should include:

- source snapshot,
    
- public headers,
    
- docs,
    
- examples,
    
- Makefile,
    
- Tools,
    
- generated HeaderDoc HTML,
    
- build notes,
    
- release manifest.
    

The archive should exclude:

- object files,
    
- local test databases,
    
- transient build logs unless deliberately included,
    
- user-local Xcode state,
    
- temporary cache files.
    

### 12. Release manifest

A release archive must include a manifest documenting:

- tag,
    
- commit,
    
- target platform,
    
- build command,
    
- smoke command,
    
- apidoc command,
    
- included artifacts,
    
- excluded artifacts,
    
- known limitations.
    

## Current status

`v0.1.0-storage-brick` proves the functional storage-brick foundation.

`v0.1.1-api-culture` proves public API documentation and a reproducible HeaderDoc build.

A future Cupertino-2009-quality public release must additionally satisfy the remaining gates in this document.

## Doctrine

A LeoRM release is not complete because code exists.

A LeoRM release is complete when a careful developer can build it, read it, test it, inspect it, document it, package it, and use it without guessing.  

