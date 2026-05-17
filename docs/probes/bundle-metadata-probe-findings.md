# Bundle Metadata Probe Findings

## Test system

The first bundle metadata probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Result

The probe can read basic `.app` bundle metadata through CoreFoundation.

Confirmed fields:

- bundle path,
- bundle identifier,
- bundle name,
- short version string,
- bundle version.

## Confirmed examples

### Finder

```text
bundle_path: /System/Library/CoreServices/Finder.app
bundle_identifier: com.apple.finder
bundle_name: Finder
bundle_short_version: 10.5.8
bundle_version: 10.5.8
````

### Dock

```text
bundle_path: /System/Library/CoreServices/Dock.app
bundle_identifier: com.apple.dock
bundle_name: Dock
bundle_short_version: 1.6.10
bundle_version: 614.11
```

### Xcode

```text
bundle_path: /Developer/Applications/Xcode.app
bundle_identifier: com.apple.Xcode
bundle_name: Xcode
bundle_short_version: 3.1.4
bundle_version: 1203
```

## Interpretation

CoreFoundation is sufficient for Phase 4b bundle metadata extraction.

The identity resolver can now be extended to fill:

- `bundle_identifier`,
    
- `bundle_name`,
    
- `bundle_version`.
    

## Boundary

Bundle metadata only strengthens identity for paths where a containing `.app` bundle was already derived.

It does not imply software safety, launch cause, user intent, or code signature status.

## Phase 4b status

The bundle metadata probe is successful.

LeoCol can now derive path-based identities and enrich `.app` identities with native Leopard bundle metadata.  

