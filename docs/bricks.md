# LeoCol Brick Boundary

LeoCol may use first-party Leopard-Crew / quietcode.org bricks when they reduce boilerplate without changing LeoCol's responsibility.

## LeoRM boundary

LeoRM is allowed below LeoColStore.

```text
LeoCol.app / LeoColAgent / probes
  -> LeoColStore
    -> LeoRM
      -> SQLite / libsqlite3
````

LeoRM may provide SQLite mechanics.

LeoColStore must keep the LeoCol-specific meaning.

## Current decision

The current probes intentionally use raw SQLite first.

This proves the Leopard baseline before LeoRM is introduced.

LeoRM integration should happen only after the raw probes have established:

- process observation storage,
    
- snapshot runs,
    
- lifecycle rebuilds,
    
- and identity enrichment.
    

## Non-goal

LeoRM must not become a hidden domain layer for LeoCol.  

