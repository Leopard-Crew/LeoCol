# LeoCol Provenance Model

## Purpose

LeoCol is not a task manager, cleaner, or malware scanner.

LeoCol records and explains process observations.

The provenance model describes how LeoCol should attach evidence to observed processes and files.

## Core idea

A process observation alone is not enough to explain origin.

LeoCol should distinguish between:

- what was observed,
- what can be resolved,
- what can be proven by local system evidence,
- and what remains unresolved.

## Terms

### Observation

A process was seen in a snapshot.

An observation can include:

- process name,
- PID,
- parent PID,
- UID,
- executable path when reported,
- first seen timestamp,
- last seen timestamp.

### Identity

The best known identity for an observed process.

Identity can come from:

- executable path,
- bundle metadata,
- bundle identifier,
- process name,
- known system path rules.

### Provenance

Evidence that explains why a process or file exists on the system.

Possible evidence sources:

- bundle metadata,
- installer receipts,
- receipt BOM files,
- LaunchAgents,
- LaunchDaemons,
- StartupItems,
- Login Items,
- kernel extensions,
- CUPS printer queues and printer stacks,
- known quarantine records,
- known accepted baseline records.

### Artifact

A file, bundle, framework, helper, login item, launch job, kext, or receipt that exists without a clearly active or accepted role.

An artifact is not automatically bad.

It means LeoCol needs more evidence or user decision.

### Stale reference

A configured system reference whose target is not present anymore.

Example:

- login item exists,
- target path is missing.

This should not be called unknown.

It should be reported as a stale reference.

### Unresolved

A process or file whose origin has not yet been resolved by LeoCol.

Unresolved does not mean suspicious.

It means the current evidence set is incomplete.

## Resolution states

LeoCol should eventually distinguish:

- observed only,
- resolved by bundle metadata,
- resolved by Apple system path,
- resolved by receipt BOM,
- resolved by launchd plist,
- resolved by StartupItem,
- resolved by Login Item,
- resolved by kext metadata,
- resolved by CUPS configuration,
- accepted baseline component,
- quarantined artifact,
- stale reference,
- unresolved.

## UI principle

The UI must avoid vague wording such as:

```text
unknown
````

Instead, it should describe the evidence state:

```text
Observed only
Not reported
Not present
Stale reference
No receipt match
No launch source found
```

## Non-goals

The provenance model must not:

- delete files,
    
- disable services,
    
- kill processes,
    
- classify software as malware,
    
- use remote reputation databases,
    
- imitate Windows task-name lookup sites.
    

LeoCol should provide local evidence, not verdicts.

## First implementation candidates

The first provenance probes should be read-only:

1. Receipt BOM resolver
    
2. LaunchAgent / LaunchDaemon resolver
    
3. StartupItem resolver
    
4. Login Item resolver
    
5. Kext resolver
    
6. CUPS printer stack resolver
    

Each resolver should produce evidence records, not actions.

## Guiding rule

Old software is not the enemy.

Artifacts are the enemy.

What stays should be named.

What is unclear should be evidenced.

What is stale should be visible.  

