# StartupItems Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_startup_items_probe.m
````

## Purpose

The StartupItems provenance probe inventories Leopard StartupItems as local provenance evidence.

It is read-only.

It does not start, stop, disable, delete, quarantine, or repair StartupItems.

## Scanned locations

```text
/Library/StartupItems
/System/Library/StartupItems
```

## Evidence target

The probe writes evidence into:

```text
provenance_evidence
```

with evidence type:

```text
startup-item
```

## Initial Leopard G5 result

On the iMac G5 test system, the probe recorded:

```text
startup-item | resolved | 2
```

Detected StartupItems:

```text
tap | /Library/StartupItems/tap | resolved
tun | /Library/StartupItems/tun | resolved
```

Both records used their corresponding `StartupParameters.plist` files as evidence paths.

## Interpretation

This matches the accepted Tunnelblick / TunTapOSX / LeoTunnel-related baseline.

The StartupItems are not automatically suspicious.

They are system-level legacy startup components that are now explicitly visible and named.

## Boundary

The probe records evidence only.

It must not become a StartupItems editor, cleaner, or repair tool.

## Build note

This probe is Mac OS X / Leopard-only because it links against Foundation using:

```text
-framework Foundation
```

It must be built and run on the iMac, not on NozzlePoint/Linux.  

