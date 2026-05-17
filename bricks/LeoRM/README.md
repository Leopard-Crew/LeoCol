# LeoRM

LeoRM is a Leopard-native Repository/DAO layer for explicit SQLite-backed Cocoa objects. Inspired by ORM principles.

It provides small, explicit Objective-C building blocks for schema management, transactions, prepared statements, migrations, and row-to-object mapping. 

**Domain-specific stores must live in separate layers built on top of LeoRM.** 

LeoRM is not a Core Data replacement and not a full ORM framework. It is a small Leopard-native Repository/DAO layer for explicit SQLite schemas. 

It borrows concepts from Core Data where they fit Leopard:

- unit-of-work thinking,
- validation boundaries,
- migration discipline,
- NSError integration,
- and object mapping

But it keeps SQL visible, schemas open, and domain models outside the core.

## Project rules

- Core Data is the conceptual benchmark.
- SQLite is the storage authority.
- Foundation is the object vocabulary.
- LeoRM is the thin Leopard-shaped bridge.

## Architecture notes

- [Scope lock](docs/scope-lock.md)
- [Class map](docs/class-map.md)
- [V1 roadmap](docs/v1-roadmap.md)
- [Core Data lessons](docs/design-notes/core-data-lessons.md)
- [SQLite boundaries](docs/design-notes/sqlite-boundaries.md)
- [Rejected patterns](docs/design-notes/rejected-patterns.md)

## Quality and positioning

- [LeoRM for the skeptical programmer](docs/positioning/skeptical-programmer.md)
- [Plain SQLite vs LeoRM](docs/positioning/plain-sqlite-vs-leorm.md)
- [Cupertino 2009 API culture](docs/quality/cupertino-2009-api-culture.md)
- [Release gates](docs/quality/release-gates.md)

