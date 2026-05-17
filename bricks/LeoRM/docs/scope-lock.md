# LeoRM Scope Lock

LeoRM is a small Leopard-native Repository/DAO layer for explicit SQLite-backed Cocoa objects.

It is inspired by ORM principles, but it is not a full ORM framework and it is not a Core Data replacement.

## Purpose

LeoRM exists to provide the shared storage brick that Leopard-Crew applications can build upon when they need open, explicit SQLite schemas and Cocoa-friendly data access.

Its job is to make SQLite pleasant and safe to use from Objective-C on Mac OS X 10.5.8 Leopard / PowerPC without hiding the database model from the developer.

## Core rule

Domain-specific stores must live above LeoRM.

LeoRM may know about databases, statements, transactions, migrations, rows, repositories, errors, and mappings.

LeoRM must not know about media, feeds, tracks, episodes, artwork, playback state, books, photos, podcasts, or any other application domain.

## Layer boundary

```text
Application UI / workflow
  -> Domain store, for example LeoMediaStore
    -> LeoRM
      -> SQLite / libsqlite3
        -> Mac OS X 10.5.8 / Foundation
````

LeoRM is the general storage brick.

LeoMediaStore and similar projects are domain bricks.

## In scope for LeoRM V1

- database open / close
    
- explicit SQLite path handling
    
- prepared statements
    
- value binding
    
- result row access
    
- explicit transactions
    
- migration runner
    
- schema version metadata
    
- repository base class or repository helpers
    
- row-to-object mapping helpers
    
- NSError-based error reporting
    
- manual memory management compatibility
    
- Mac OS X 10.5.8 / PowerPC compatibility
    

## Out of scope for LeoRM V1

- full object graph management
    
- ActiveRecord-style model magic
    
- hidden SQL generation as the default path
    
- automatic relationship resolution
    
- lazy faulting as a core requirement
    
- automatic model generation
    
- UI bindings
    
- application-specific schemas
    
- Core Data store manipulation
    
- Swift, ARC, blocks, CocoaPods, Carthage, or modern package managers as requirements
    

## Design doctrine

- Core Data is the conceptual benchmark.
    
- SQLite is the storage authority.
    
- Foundation is the object vocabulary.
    
- LeoRM is the thin Leopard-shaped bridge.
    

## Success criteria

LeoRM succeeds when a Leopard-Crew project can define its own open SQLite schema, migrate it safely, access rows through small repository objects, map results into Cocoa objects, and keep SQL visible enough to debug and reason about.

LeoRM fails if it becomes a generic framework world, a Core Data clone, a Rails-style ORM, or a media-store project in disguise.  

