# Core Data Lessons for LeoRM

Core Data is the conceptual benchmark for LeoRM, but LeoRM is not a Core Data replacement.

LeoRM studies Core Data because Apple solved many hard data-layer problems there: object lifecycle, validation, change boundaries, migration discipline, and integration with Foundation and Cocoa conventions.

LeoRM must borrow the useful ideas without copying Core Data's architecture or hiding SQLite.

## What Core Data teaches LeoRM

### 1. A data layer needs clear change boundaries

Core Data uses managed object contexts as working areas for changes before they are committed or discarded.

LeoRM should learn from that idea, but keep the implementation smaller and more explicit.

For LeoRM this means:

- explicit transactions,
- optional unit-of-work helpers,
- clear commit and rollback paths,
- predictable validation points.

LeoRM V1 does not need a full managed object context.

### 2. Schema evolution must be planned early

Core Data treats model versioning and migration as part of the persistence story.

LeoRM should provide migration discipline from the beginning.

For LeoRM this means:

- a metadata table,
- schema version tracking,
- ordered migration steps,
- repeatable migration execution,
- visible errors when migration fails.

### 3. Validation belongs at explicit boundaries

Core Data validates objects before changes are saved.

LeoRM should not validate magically on every property assignment.

Instead, validation should happen at repository, transaction, or domain-store boundaries.

LeoRM may provide helper protocols or conventions, but domain rules belong above LeoRM.

### 4. Foundation is the object vocabulary

Core Data fits naturally into Cocoa because it speaks Foundation types.

LeoRM should do the same.

Preferred value vocabulary:

- NSString
- NSNumber
- NSDate
- NSData
- NSNull where needed
- NSError for failures
- NSArray and NSDictionary for simple structured helper APIs

LeoRM should not introduce a foreign runtime vocabulary.

### 5. Object mapping should be helpful, not magical

Core Data maps object models to persistent stores, but its SQLite store is private and must not be treated as a normal application schema.

LeoRM exists for the opposite case: open, explicit SQLite schemas.

Therefore LeoRM should provide row-to-object mapping helpers, but it must keep schemas and SQL visible.

## What LeoRM must not copy from Core Data

LeoRM must not implement:

- NSManagedObject replacement classes,
- a graphical object model editor,
- hidden persistent store formats,
- automatic object graph management,
- faulting as a V1 requirement,
- Cocoa Bindings integration as a core requirement,
- automatic undo and redo,
- transparent relationship magic,
- private SQLite schemas.

## Practical translation

Core Data concept:

- Managed Object Context

LeoRM translation:

- explicit transaction / optional unit-of-work helper

Core Data concept:

- Managed Object Model

LeoRM translation:

- explicit schema object and migration list

Core Data concept:

- Persistent Store

LeoRM translation:

- open SQLite database controlled by the application or domain store

Core Data concept:

- Fetch Request

LeoRM translation:

- explicit SQL query with bindings, later optionally a small query builder

Core Data concept:

- Validation

LeoRM translation:

- explicit validation boundary before insert, update, commit, or migration

## Doctrine

Core Data shows what a mature Cocoa data layer cares about.

SQLite defines what LeoRM stores.

Foundation defines what LeoRM returns.

LeoRM must remain smaller, more explicit, and more inspectable than Core Data.
