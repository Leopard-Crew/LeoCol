# LeoRM-backed LeoColStore Probe Findings

## Test system

The first LeoRM-backed LeoColStore probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Purpose

This probe validates LeoRM as a first-party storage brick for LeoCol.

It does not replace the raw C probes.

Instead, it proves that the already established LeoCol database path can be consumed from an Objective-C / Foundation layer through LeoRM.

## Result

The probe successfully:

- built the embedded LeoRM static library,
- opened the existing LeoCol SQLite journal,
- queried `process_lifecycle` and `process_identity`,
- read rows through LeoRM result-set and row APIs,
- printed a small report suitable for a future Cocoa-facing store layer.

## Observed successful output

The probe printed 20 rows from:

```text
Probe/results/leocol-v1.db
````

Observed examples included:

```text
Dock      com.apple.dock      Dock      Apple system component
Finder    com.apple.finder    Finder    Apple system component
Terminal  com.apple.Terminal  Terminal  Apple application
Xcode     com.apple.Xcode     Xcode     developer tool
```

## Interpretation

This confirms that LeoRM can serve below a future `LeoColStore` layer.

The raw probes remain valuable because they prove Leopard system behavior directly.

LeoRM becomes useful above that baseline, where LeoCol needs a cleaner Objective-C storage surface for the future Cocoa application.

## Boundary

LeoRM does not own LeoCol's domain rules.

LeoCol remains responsible for:

- process observation meaning,
    
- snapshot runs,
    
- lifecycle aggregation,
    
- identity resolution,
    
- classification policy,
    
- and user-facing interpretation.
    

## Status

The LeoRM-backed store probe is successful.

LeoCol now has a proven path from raw Leopard process observation to Objective-C-accessible stored identity data.  

