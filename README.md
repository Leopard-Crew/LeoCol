# LeoCol

**LeoCol** is a native Mac OS X 10.5.8 Leopard system collector.

It records process and application lifecycle observations that Leopard normally exposes only temporarily or spreads across separate tools.

> LeoCol is not a process monitor.  
> LeoCol is a small system memory for Leopard.

## Purpose

LeoCol connects observable knowledge from the Leopard system into a historical journal:

- which processes and applications were seen,
- when they appeared and disappeared,
- where they live on disk,
- which bundle or executable they likely belong to,
- whether they look like Apple system components, user applications, helper tools, MacPorts tools, or unknown software,
- and how their resource usage behaved over time.

LeoCol is not intended to replace Activity Monitor, Console, launchd, or System Profiler.

It exists to collect and relate what those tools expose only live, separately, or without long-term context.

## Doctrine

LeoCol follows the Leopard-Crew / quietcode.org "Cupertino 2009" rule:

- use native Mac OS X Leopard mechanisms first,
- no kernel extensions for V1,
- no private APIs,
- no tuning-suite behavior,
- no Windows-style task-manager clone,
- no security theatre,
- no foreign UI toolkit,
- no monolith where small native bricks are enough.

LeoCol should feel like something Apple could plausibly have shipped for Leopard power users and developers.

## Initial bricks

```text
LeoColAgent
  Lightweight LaunchAgent sampler.

LeoColStore
  Conservative SQLite-backed journal.

LeoColResolver
  Maps processes to executables, bundles, LaunchServices identity, and launchd hints.

LeoCol.app
  Native Cocoa viewer and controller for collected history.
````

## Current status

This repository currently defines the concept and scope before code is added.

The first implementation target is a small, reliable V1 that records process lifecycle observations and shows them in a native Cocoa history view.

## Documents

- Scope
    
- Architecture
    
- Collector Model
    
- Data Model  
    

