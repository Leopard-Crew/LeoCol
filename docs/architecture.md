# LeoCol Architecture

## Principle

LeoCol is built as small native Leopard bricks.

The collector, storage layer, resolver, and viewer are separate responsibilities.

No part should become a general-purpose system management framework.

## Components

```text
LeoColAgent
  Runs as a lightweight LaunchAgent.
  Periodically samples process state.
  Writes observations to LeoColStore.

LeoColStore
  Owns the persistent journal.
  Uses the system SQLite available on Leopard.
  Keeps schema conservative and explicit.

LeoColResolver
  Resolves process facts into Leopard concepts.
  Maps executables to bundles, paths, LaunchServices identity, and launchd hints.

LeoCol.app
  Native Cocoa viewer.
  Shows history, process details, classifications, and safe actions.
````

## Data flow

```text
Leopard system state
        |
        v
LeoColAgent
        |
        v
LeoColStore
        |
        v
LeoColResolver
        |
        v
LeoCol.app
```

## Native sources of truth

LeoCol should prefer Leopard-native mechanisms:

- POSIX process inspection where appropriate,
    
- sysctl where appropriate,
    
- launchd and launchctl-visible information,
    
- bundle Info.plist metadata,
    
- LaunchServices identity,
    
- Finder paths,
    
- Spotlight metadata only where useful and cheap,
    
- Apple Events for polite application quit,
    
- signals only as explicit fallback actions.
    

## Action doctrine

LeoCol actions must be conservative.

Preferred order for ending an application:

1. polite application quit where possible,
    
2. terminate process,
    
3. force kill only when explicitly requested.
    

LeoCol must never silently clean, kill, disable, quarantine, or modify system behavior.


