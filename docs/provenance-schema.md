# LeoCol Provenance Schema

## Purpose

The provenance schema stores local evidence that helps explain observed processes and artifacts.

It does not store verdicts.

It stores evidence.

## provenance_evidence

Each row represents one local evidence item.

Examples:

- a bundle metadata match,
- a receipt BOM match,
- a LaunchDaemon plist,
- a LaunchAgent plist,
- a StartupItem,
- a Login Item,
- a loaded kext,
- a CUPS printer configuration,
- a quarantine record,
- an accepted baseline record.

## process_provenance

Links a process lifecycle to one or more evidence rows.

A lifecycle can have multiple evidence records.

For example, a process may be linked to:

- a bundle path,
- a bundle identifier,
- a LaunchAgent,
- and a receipt BOM.

## Field notes

### evidence_type

Describes the kind of evidence.

Expected values include:

```text
bundle
receipt-bom
launch-agent
launch-daemon
startup-item
login-item
kext
cups
quarantine
baseline
````

### evidence_source

Describes where the evidence came from.

Examples:

```text
CFBundle
/Library/Receipts
/Library/LaunchDaemons
~/Library/LaunchAgents
/Library/StartupItems
System Events login items
kextstat
CUPS
system-quarantine
system-baseline
```

### subject_kind

The kind of thing the evidence describes.

Examples:

```text
process
bundle
file
framework
kext
launch-job
login-item
printer
```

### resolution_state

Describes what the evidence currently means.

Examples:

```text
resolved
observed-only
stale-reference
artifact
accepted-baseline
quarantined
unresolved
```

## Boundary

The schema must not imply action.

It does not mean:

- delete,
    
- disable,
    
- quarantine,
    
- kill,
    
- repair,
    
- or classify as malware.
    

It only records evidence.

## First use

The first practical use should be a read-only probe that records LaunchAgent and LaunchDaemon plist evidence.

Launch sources are a good first target because they explain why processes may appear automatically.  

