# LeoCol Hardening Smoke Test Plan

## Purpose

This document defines the hardening smoke tests required before LeoCol V1 release.

LeoCol is read-only, but it still must behave predictably when files, helpers, databases, or bundle resources are missing.

## Scope

The hardening smoke test covers runtime failure behavior, not feature expansion.

## Core rule

LeoCol must fail visibly and calmly.

It must not crash, hang silently, modify system state, or pretend that incomplete data is complete.

## Test areas

### Missing database

Temporarily hide:

```text
Probe/results/leocol-v1.db
````

Expected result:

- app starts,
    
- fallback rows may appear where appropriate,
    
- status text reports missing database,
    
- no crash.
    

### Missing bundled help

Temporarily hide:

```text
LeoCol.app/Contents/Resources/LeoCol Help/
```

Expected result:

- app starts,
    
- Help menu command does not crash,
    
- status text reports that help was not found.
    

### Missing bundled probes

Temporarily hide one or more helper probes from:

```text
LeoCol.app/Contents/Resources/Probes/
```

Expected result:

- Update Snapshot or Update Evidence shows operation panel,
    
- missing helper is reported in the operation log,
    
- app remains usable.
    

### Missing development Probe/build

Temporarily hide:

```text
Probe/build
```

Expected result:

- bundled-probe app still works when helpers are present in the bundle,
    
- app reports missing helpers clearly when neither bundle nor development helpers exist.
    

### Corrupt database

Temporarily replace the database with a non-SQLite file.

Expected result:

- app does not crash,
    
- LeoRM/open/query error becomes a visible status,
    
- no write or repair attempt is made.
    

### Empty database

Use an empty SQLite database file with no LeoCol tables.

Expected result:

- app does not crash,
    
- query failure or empty data status is visible,
    
- no schema creation is attempted by the app.
    

### Operation panel behavior

For long operations:

- panel appears immediately,
    
- log updates during work,
    
- final status is visible,
    
- Done button is enabled at completion,
    
- main app remains responsive enough for V1.
    

### Menu safety

Menu commands must not imply or perform destructive behavior.

Specifically absent:

```text
Clean
Repair
Delete
Kill
Unload
Install
Enable daemon
Run in background
```

## Manual test checklist

```text
[ ] Missing database tested
[ ] Missing help tested
[ ] Missing bundled probe tested
[ ] Missing Probe/build fallback tested
[ ] Corrupt database tested
[ ] Empty database tested
[ ] Update Snapshot failure path tested
[ ] Update Evidence failure path tested
[ ] Help failure path tested
[ ] App still launches after all failure tests
```

## Acceptance criteria

Hardening passes when LeoCol:

- starts under expected missing-resource conditions,
    
- reports failures visibly,
    
- does not crash on missing help or helpers,
    
- does not silently hang during helper execution,
    
- does not create system services,
    
- does not alter system configuration,
    
- remains read-only.
    

## Non-goals

This pass must not add:

- automatic repair,
    
- database migration,
    
- cleanup behavior,
    
- daemon monitoring,
    
- privileged helper tools,
    
- background schedulers.  
    

