# Rejected Patterns for LeoRM

This document records design patterns that LeoRM explicitly rejects.

The goal is not to be dogmatic. The goal is to keep LeoRM small, inspectable, Leopard-native, and useful as a system brick rather than letting it grow into a framework world.

Rejected patterns may still be useful in other projects or higher layers. They are rejected only for the LeoRM core.

## 1. Full ORM framework

LeoRM rejects the goal of becoming a full ORM framework.

Rejected:

- automatic object graph management,
- transparent relationship loading,
- object identity maps as a core requirement,
- hidden persistence magic,
- automatic dirty tracking as a V1 requirement,
- full query language abstraction,
- model classes that silently define database structure.

Reason:

LeoRM is a Repository/DAO layer inspired by ORM principles. It is not Hibernate, Rails ActiveRecord, EOF, or Core Data.

LeoRM should make SQLite easier to use, not disappear.

## 2. Core Data clone

LeoRM rejects becoming a Core Data clone.

Rejected:

- NSManagedObject replacement classes,
- managed object contexts as mandatory architecture,
- graphical model files,
- private persistent store formats,
- hidden schema generation,
- faulting as a core requirement,
- automatic undo / redo,
- Cocoa Bindings integration as a core feature.

Reason:

Core Data already exists on Leopard.

LeoRM exists for explicit SQLite schemas that remain open, inspectable, and controlled by the application or domain store.

Core Data is the conceptual benchmark, not the implementation target.

## 3. ActiveRecord-style model magic

LeoRM rejects ActiveRecord as the core pattern.

Rejected:

```objc
[Episode all];
[Episode where:@"title == 'Example'"];
[Episode create:@{ @"title": @"Example" }];
[episode save];
[episode delete];
```

Reason:

ActiveRecord couples model objects directly to persistence behavior.

LeoRM should keep persistence logic in repositories or DAO-style helpers, not in domain objects.

Domain objects should be allowed to remain plain Cocoa objects.

Preferred direction:

```objc
NSArray *episodes = [episodeRepository findWhere:@"title = ?"
                                       arguments:arguments
                                           error:&error];
```

## 4. Hidden SQL

LeoRM rejects hidden SQL as the default path.

Rejected:

- implicit SQL generation as the only access method,
- opaque query objects that cannot show their SQL,
- APIs that make indexes, joins, and constraints invisible,
- debugging paths that require understanding LeoRM internals before understanding the database.

Reason:

SQL is part of the contract.

LeoRM users should be able to understand performance, schema shape, and failure modes with normal SQLite knowledge and tools.

Helpers may exist, but SQL must remain visible and inspectable.

## 5. Domain models in the core

LeoRM rejects application-domain models in the core.

Rejected examples:

- media items,
- feeds,
- episodes,
- tracks,
- albums,
- artists,
- artwork,
- playback state,
- books,
- photos,
- documents,
- browser history,
- application preferences.

Reason:

LeoRM is a general storage brick.

Domain models belong in domain stores such as LeoMediaStore.

If a concept belongs to only one application family, it does not belong in LeoRM.

## 6. Framework sprawl

LeoRM rejects framework sprawl.

Rejected:

- plugin systems,
- extension marketplaces,
- runtime module discovery,
- broad service registries,
- a second persistence ecosystem around SQLite,
- generic abstractions for every possible storage backend.

Reason:

LeoRM should be small enough to understand and vendor if necessary.

Each added layer must justify itself on Leopard / PowerPC.

The storage backend is SQLite. LeoRM does not need a backend abstraction until there is a real Leopard-native reason.

## 7. Modern Apple package assumptions

LeoRM rejects modern package tooling as a requirement.

Rejected as requirements:

- CocoaPods,
- Carthage,
- Swift Package Manager,
- ARC,
- Swift,
- blocks,
- Grand Central Dispatch as mandatory architecture,
- modern Objective-C literals as required style.

Reason:

LeoRM targets Mac OS X 10.5.8 Leopard / PowerPC and Xcode 3.1.4.

Modern projects may be studied, but LeoRM must build and remain understandable in the Leopard toolchain.

## 8. Threading promises without proof

LeoRM rejects unproven concurrency promises.

Rejected:

- claiming full thread safety without tests,
- sharing mutable database objects freely across threads,
- hiding background writes inside innocent-looking calls,
- inventing complex queue behavior before V1 needs it.

Reason:

SQLite has clear concurrency rules, and Leopard-era threading must be treated conservatively.

LeoRM should document ownership and transaction boundaries before promising advanced concurrency.

## 9. Private store format

LeoRM rejects private database formats.

Rejected:

- undocumented internal schemas,
- binary blobs as the primary model representation,
- opaque generated table names,
- database files that cannot be inspected meaningfully with SQLite tools.

Reason:

LeoRM exists because explicit SQLite schemas are valuable.

A LeoRM database should remain understandable as SQLite.

LeoRM metadata may exist, but domain tables must remain domain-owned and readable.

## 10. Replacing SQLite features with Objective-C-only logic

LeoRM rejects replacing database features with weaker Objective-C-only behavior.

Rejected:

- Objective-C-only uniqueness checks instead of UNIQUE constraints,
- Objective-C-only required field checks instead of NOT NULL where appropriate,
- manual relationship checks where foreign keys or schema rules are available and verified,
- in-memory filtering where SQL filtering is appropriate.

Reason:

SQLite is the storage authority.

LeoRM should report and explain database constraints, not pretend they are unnecessary.

## 11. Premature query-builder world

LeoRM rejects a large query builder in V1.

Rejected for V1:

- full NSPredicate-to-SQL compiler,
- fluent query DSL,
- automatic join planner,
- generic expression tree engine,
- Rails-style finder methods.

Reason:

A query builder can become larger than the storage layer itself.

V1 should prefer explicit SQL with bindings.

A small query helper may be added later only if it remains transparent and can show the generated SQL.

## 12. Media-store creep

LeoRM rejects media-store creep.

Rejected:

- adding media tables to LeoRM,
- adding feed helpers to LeoRM,
- adding artwork cache behavior to LeoRM,
- adding playback-position helpers to LeoRM,
- making LeoRM decisions based on LeoCast, LeoRadio, or LeoLibrary alone.

Reason:

LeoMediaStore exists for that layer.

LeoRM must stay useful to non-media projects.

## Acceptance rule

A feature belongs in LeoRM only if it is useful for many SQLite-backed Leopard-Crew projects and does not require domain knowledge.

A feature belongs above LeoRM if it knows what the data means.

## Doctrine

LeoRM should be boring in the best possible way.

Small.

Explicit.

Inspectable.

Cocoa-shaped.

SQLite-honest.

Leopard-native.
