# Identity Resolver Plan

## Purpose

The identity resolver turns raw process lifecycle rows into Leopard-readable process identities.

It answers one question:

> What does this observed process likely belong to?

## Phase 4a scope

Phase 4a resolves identity from executable paths only.

It does not yet use LaunchServices, Spotlight, Apple Events, or live process state.

## Inputs

The resolver reads from `process_lifecycle`:

- pid,
- process_name,
- executable_path,
- first_seen_at,
- last_seen_at,
- exit_observed.

## Outputs

The resolver writes to `process_identity`:

- lifecycle_id,
- bundle_path,
- bundle_identifier,
- bundle_name,
- bundle_version,
- classification,
- confidence,
- notes.

## Initial bundle detection

If an executable path contains:

```text
.app/Contents/MacOS/
````

then the resolver may derive the containing `.app` bundle path.

Example:

```text
/System/Library/CoreServices/Finder.app/Contents/MacOS/Finder
```

becomes:

```text
/System/Library/CoreServices/Finder.app
```

## Initial classifications

Phase 4a may classify by path:

### Apple system component

Paths below:

```text
/System/Library/
```

### Apple application

Paths below:

```text
/Applications/
```

where the bundle or executable is likely Apple-provided.

This must remain conservative until stronger metadata exists.

### User application

Paths below:

```text
/Users/
```

or non-system application folders.

### MacPorts tool

Paths below:

```text
/opt/local/
```

### Command-line tool

Paths below:

```text
/bin/
/sbin/
/usr/bin/
/usr/sbin/
/usr/libexec/
```

without an enclosing `.app` bundle.

### Developer tool

Paths below:

```text
/Developer/
```

or known project/build directories.

### Unknown

Anything not confidently classified.

## Confidence values

Initial confidence values:

- `path-app-contained`
    
- `path-prefix`
    
- `path-cli`
    
- `unknown`
    

## Non-goals

Phase 4a does not claim:

- software safety,
    
- malware status,
    
- exact launch cause,
    
- code signature status,
    
- vendor certainty,
    
- or user intent.
    

## Rule

The resolver must prefer a humble `unknown` over a confident lie.  

