# LeoRM for the Skeptical Programmer

LeoRM is not presented as a universal database framework.

LeoRM is a small Mac OS X 10.5.8 Leopard / PowerPC verified SQLite Repository/DAO brick for Objective-C projects that need open, explicit SQLite schemas and Cocoa-shaped access without Core Data, AppKit, Swift, ARC, blocks, CocoaPods, Carthage, or modern package assumptions.

## What LeoRM is

LeoRM is:

- a small Repository/DAO helper layer,
- built on top of SQLite,
- shaped for Foundation and NSError,
- verified on Leopard / PowerPC,
- explicit about SQL,
- explicit about schema ownership,
- explicit about transactions,
- explicit about migrations,
- domain-neutral.

LeoRM exists to remove repeated SQLite boilerplate without hiding SQLite.

## What LeoRM is not

LeoRM is not:

- a Core Data replacement,
- a full ORM framework,
- an ActiveRecord clone,
- a hidden SQL generator,
- a model-object runtime,
- a persistence framework world,
- a media-store project in disguise.

LeoRM is intentionally smaller than those things.

## Why not Core Data?

Core Data is the native Apple object graph and persistence framework.

It is excellent when the application wants Core Data's object lifecycle model, managed object contexts, faulting, validation, undo/redo integration, and Cocoa ecosystem behavior.

LeoRM is for a different case:

- the schema should be open,
- the database should be inspectable with SQLite tools,
- SQL should remain visible,
- the application or domain store owns the schema,
- direct SQLite interoperability matters.

Core Data is the conceptual benchmark.

SQLite is the storage authority.

## Why not raw SQLite?

Raw SQLite provides maximum control, but it pushes repeated error-prone work into every application:

- open / close handling,
- prepared statement lifetime,
- binding,
- stepping,
- finalization,
- row conversion,
- transaction boundaries,
- NSError mapping,
- schema metadata,
- migration discipline.

LeoRM standardizes those edges while keeping SQL visible.

## Why not FMDB?

FMDB is a mature Objective-C SQLite wrapper and is a valid comparison point.

LeoRM has different priorities:

- Leopard / PowerPC first,
- Xcode 3.1.4 and GCC 4.0 compatibility,
- manual retain/release,
- Foundation + libsqlite3 only,
- no modern package manager requirement,
- Repository/DAO and migration discipline built into the project shape,
- Leopard-Crew house style and Cupertino-2009 API culture.

FMDB is a better choice for broad Apple-platform SQLite wrapping.

LeoRM is a better fit when the project specifically needs a small Leopard-native storage brick with strict domain neutrality and explicit schema ownership.

## What LeoRM 0.1 proves

LeoRM 0.1 proves the storage-brick foundation:

- SQLite errors are mapped to NSError.
- Databases can be opened and closed explicitly.
- Prepared statements support bound values.
- Query rows can be read as Foundation values.
- Transactions support commit, rollback, and active-state checks.
- Metadata and schema versions are stored in `lrm_metadata`.
- Ordered migrations can be applied safely.
- Repository helpers support DAO-style access.
- A neutral NotesStore example can be built above LeoRM without adding domain logic to LeoRM itself.
- The full smoke suite builds and runs warning-free on Mac OS X 10.5.8 / PowerPC.

## The honest pitch

LeoRM is not mature because it is large.

LeoRM is useful because it is small, explicit, target-verified, and inspectable.

A skeptical professional programmer should not trust LeoRM because of claims.

They should trust it only to the degree that the code, tests, documentation, target-system builds, and release discipline justify that trust.

## Current positioning

LeoRM 0.1 is a verified foundation release.

It is not yet a broad mature database framework.

The next releases should increase confidence through:

- more failure-path tests,
- leak checks on Leopard,
- public header documentation,
- explicit ownership rules,
- file-backed database examples,
- constraint-error tests,
- migration-failure rollback tests,
- edge-case tests for nil, NSNull, NSData, NSNumber, and NSString,
- reproducible release artifacts.

This work is not optional polish.

For a system brick, it is part of the product.
