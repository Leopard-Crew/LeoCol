# Identity Resolver Probe Findings

## Test system

The first path-based identity resolver probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Result

The probe can rebuild conservative `process_identity` rows from recorded `process_lifecycle` data.

Confirmed behavior:

- every lifecycle can receive one identity row,
- executable paths can be classified by prefix,
- `.app` bundle containment can be derived from executable paths,
- unknown remains a valid result,
- no LaunchServices, Spotlight, code signing, or live process state is required for Phase 4a.

## Observed successful test

The successful test processed:

```text
lifecycles processed: 67
identities inserted: 67
````

The resulting `process_identity` table contained:

```text
process_identity rows: 67
```

## Observed classification distribution

```text
Apple system component / path-app-contained   9
Apple system component / path-prefix          4
command-line tool / path-cli                  9
developer build / path-app-contained          1
unknown / path-app-contained                  1
unknown / unknown                            42
user application / path-app-contained         1
```

## Confirmed bundle examples

The resolver correctly derived `.app` bundle paths for common Leopard components:

- loginwindow,
    
- AirPort Base Station Agent,
    
- ARDAgent,
    
- Spotlight,
    
- Dock,
    
- SystemUIServer,
    
- Finder,
    
- SpeechSynthesisServer,
    
- Xcode.
    

Example:

```text
/System/Library/CoreServices/Dock.app/Contents/MacOS/Dock
```

was resolved to:

```text
/System/Library/CoreServices/Dock.app
```

with:

```text
classification: Apple system component
confidence: path-app-contained
```

## Important interpretation

`path-app-contained` means that the resolver found an enclosing `.app` bundle path.

It does not imply vendor certainty, safety, launch cause, or user intent.

## Current limitation

The resolver is path-only.

It does not yet read Info.plist metadata, bundle identifiers, bundle versions, LaunchServices records, Spotlight metadata, or code signatures.

The current `developer build` classification is based only on `/Developer/` path prefix and may later be renamed or refined to distinguish developer tools from project build products.

## Phase 4a status

The path-based identity resolver probe is successful.

LeoCol can now see, remember, approximate lifecycles, and assign conservative path-based identities on Leopard/PPC.  


## Bundle metadata integration

A later identity probe update integrated the CoreFoundation bundle metadata path.

Confirmed behavior:

- bundle identifiers are read from `.app` bundles,
- bundle names are read from bundle Info.plist metadata,
- bundle versions are read from `CFBundleShortVersionString` with fallback to `CFBundleVersion`,
- the identity resolver still remains conservative and path-based for classification.

Observed examples:

```text
Finder    -> com.apple.finder    -> Finder    -> 10.5.8
Dock      -> com.apple.dock      -> Dock      -> 1.6.10
Terminal  -> com.apple.Terminal  -> Terminal  -> 2.0.2
Xcode     -> com.apple.Xcode     -> Xcode     -> 3.1.4
````

The test also confirmed that third-party bundled helpers can expose useful metadata, for example HP IO Classic Proxy with an HP bundle identifier.

## Updated Phase 4b status

The identity resolver can now enrich `.app`-contained process identities with native Leopard/CoreFoundation bundle metadata.  

