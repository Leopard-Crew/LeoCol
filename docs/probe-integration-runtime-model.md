# LeoCol Probe Integration Runtime Model

## Purpose

This document defines how LeoCol V1 should integrate its read-only probes.

It answers the core runtime question:

```text
Is LeoCol a system service, a live monitor, or a snapshot-based tool?
````

## Decision

LeoCol V1 is not a system service.

LeoCol V1 is not a daemon.

LeoCol V1 is not a live task manager.

LeoCol V1 is a snapshot-based read-only system memory for Mac OS X Leopard.

It stores observations and provenance evidence in a persistent database and lets the user inspect that memory through a native Leopard Cocoa application.

## Runtime model

LeoCol V1 consists of three layers:

```text
LeoCol.app
  Native Cocoa viewer and user-facing commands.

Read-only probes
  Small helper tools that collect local evidence when explicitly invoked.

leocol-v1.db
  Persistent SQLite memory containing process observations and provenance evidence.
```

## On-demand collection

In V1, probes should run only when the user explicitly requests an update.

Expected user-facing commands:

```text
File / Ablage
  Update Snapshot
  Update Evidence
  Export Report...
```

German wording:

```text
Ablage
  Momentaufnahme aktualisieren
  Belege aktualisieren
  Bericht exportieren...
```

## No background service in V1

V1 must not install or run:

- LaunchDaemons,
    
- LaunchAgents,
    
- StartupItems,
    
- privileged helpers,
    
- login items,
    
- background watchers,
    
- automatic schedulers.
    

LeoCol must not create the very kind of unexplained persistent system activity it is designed to make visible.

## Probe execution

LeoCol.app may launch bundled read-only helper tools through standard Leopard mechanisms such as `NSTask`.

The probes remain separate small executables.

LeoCol.app coordinates them.

The probes collect evidence.

The database stores the result.

The viewer displays the result.

## Probe packaging direction

For development, probes may continue to live under:

```text
Probe/tools
Probe/build
```

For app integration, V1 should move toward bundled helper tools, for example:

```text
LeoCol.app/Contents/Resources/Probes/
```

or another Leopard-appropriate bundle-internal location.

The exact packaging path may be finalized during implementation.

## Probe set for Update Evidence

The initial Update Evidence command should run the existing read-only provenance probes:

- LaunchAgents / LaunchDaemons,
    
- Login Items,
    
- StartupItems,
    
- Kexts,
    
- CUPS,
    
- Receipt / BOM inventory.
    

Each probe should remain independently testable from Terminal.

## Update Snapshot

Update Snapshot is separate from Update Evidence.

It should update process observation state.

It should not be confused with live monitoring.

A snapshot records what LeoCol observes at a point in time.

`Last seen` means:

```text
last seen in a LeoCol snapshot
```

It does not automatically mean:

```text
currently running
```

## Status communication

LeoCol should make snapshot age visible.

Future UI status should distinguish:

```text
Last snapshot
Last evidence update
Database path
```

This prevents the user from mistaking persistent LeoCol memory for a live task list.

## Failure handling

If a probe fails, LeoCol should not crash.

It should report the failed probe in a user-facing status area or report.

A failed probe does not imply system danger.

It means the evidence for that area could not be updated.

## Permissions

V1 should avoid privileged operations.

If a probe cannot collect something without elevated privileges, it should report the limitation instead of requesting permanent privilege escalation.

No sudo helper belongs in V1.

## Read-only boundary

Probe integration must not add actions such as:

- kill process,
    
- unload kext,
    
- disable service,
    
- delete file,
    
- quarantine file,
    
- remove login item,
    
- repair printer configuration,
    
- uninstall package.
    

## Optional future agent

A future version may consider an optional user-controlled agent.

That is explicitly outside V1.

If ever implemented, it must be opt-in, visible, documented, and removable.

## Guiding rule

LeoCol should be explicit, calm, and deterministic.

It should answer:

```text
What did LeoCol observe, when did it observe it, and what local evidence explains it?
```

It should not behave like hidden system surveillance.  

