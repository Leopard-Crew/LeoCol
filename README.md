# LeoCol

**LeoCol** is a native Mac OS X Leopard PowerPC system observation tool.

It records explicit process and application lifecycle snapshots and keeps a
small historical memory of what Leopard normally exposes only live, separately,
or without long-term context.

> LeoCol is not a process monitor.
> LeoCol is a small system memory for Leopard.

## Target

```text
Mac OS X Leopard 10.5.8 PowerPC
```

The public release artifact is PowerPC-only. The release packaging path rejects  
accidental Intel/PowerPC universal binaries.

The first public package was verified as:

```text
ppc7400
```

This is accepted as a PowerPC-only Leopard release binary.

## Download

The first public release is available as:

```text
LeoCol-0.16.2-Leopard-PPC.dmg
LeoCol-0.16.2-Leopard-PPC.dmg.sha256
```

The `.sha256` sidecar file is part of the release and should be used to verify  
the downloaded DMG.

## Purpose

LeoCol connects observable knowledge from the Leopard system into a historical  
journal:

- which processes and applications were seen,
    
- when they appeared and disappeared,
    
- where they live on disk,
    
- which bundle or executable they likely belong to,
    
- whether they look like Apple system components, user applications, helper  
    tools, MacPorts tools, or unknown software,
    
- and how their observed state changed across snapshots.
    

LeoCol is not intended to replace Activity Monitor, Console, launchd, or System  
Profiler.

It exists to collect and relate what those tools expose only live, separately,  
or without long-term context.

## Current capabilities

The current V1 release provides:

- native Cocoa application,
    
- explicit manual snapshot recording,
    
- process lifecycle view,
    
- provenance and evidence overview,
    
- snapshot overview,
    
- plain text report export,
    
- localized English and German in-app help,
    
- bundled V1 probes,
    
- application icon,
    
- PPC-only release packaging,
    
- SHA256 sidecar generation for GitHub releases.
    

## Doctrine

LeoCol follows these rules:

- use native Mac OS X Leopard mechanisms first,
    
- target Leopard PowerPC directly,
    
- no kernel extensions for V1,
    
- no private APIs,
    
- no tuning-suite behavior,
    
- no Windows-style task-manager clone,
    
- no security theatre,
    
- no foreign UI toolkit,
    
- no monolith where small native bricks are enough.
    

LeoCol should feel like something Apple could plausibly have shipped for  
Leopard power users and developers.

## Release boundary

LeoCol remains:

- read-only,
    
- manually operated,
    
- non-daemonized,
    
- non-mutating,
    
- non-certifying.
    

LeoCol does not clean, repair, delete, kill, unload, install, or run as a  
daemon.

## Architecture

LeoCol is built from small native components:

```text
LeoCol.app
  Native Cocoa viewer and controller for collected history.

LeoColStore
  Conservative SQLite-backed journal.

LeoColResolver
  Maps processes to executables, bundles, LaunchServices identity, and launchd
  hints.

V1 probes
  Small bundled helper tools used for explicit observation.
```

## Documents

- [Scope](docs/scope.md)
- [Architecture](docs/architecture.md)
- [Collector Model](docs/collector-model.md)
- [Data Model](docs/data-model.md)
- [V1 Roadmap](docs/v1-roadmap.md)
- [Release Packaging Plan](docs/release-packaging-plan.md)
- [Release Package Findings](docs/release-package-findings.md)
- [Public Release Findings](docs/public-release-findings.md)
    

## Project namespace

LeoCol is published in the quietcode.org / quietcode-org project namespace.

The public repository origin is:

```text
https://github.com/quietcode-org/LeoCol.git
```

