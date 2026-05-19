# CUPS Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_cups_probe.m
````

## Purpose

The CUPS provenance probe inventories printer queues, device URIs, and PPD references as local provenance evidence.

It is read-only.

It does not add, remove, modify, pause, resume, or repair printer queues.

## Evidence target

The probe writes evidence into:

```text
provenance_evidence
```

with evidence type:

```text
cups
```

## Evidence sources

The probe uses local CUPS state:

```text
lpstat -p
lpstat -v
/etc/cups/ppd
/private/etc/cups/ppd
```

## Initial Leopard G5 result

On the iMac G5 test system, the probe inserted:

```text
1 CUPS queue record
0 orphan PPD records
```

Grouped result:

```text
printer-queue | resolved | 1
```

Detected printer queue:

```text
Jotunnheim
```

The queue resolved to:

```text
Device URI: mdns://Lexmark%20M1140%20%284%29._ipp._tcp.local.
PPD:        /etc/cups/ppd/Jotunnheim.ppd
State:      resolved
```

## Interpretation

The active printer configuration is visible and resolved.

No orphan PPD records were found in this run.

This means the CUPS queue/PPD layer currently does not show stale HP-style printer artifacts in the scanned locations.

It does not prove that the entire filesystem is free of printer-related artifacts.

It only proves that the active CUPS queue and PPD layer is currently clean for this probe.

## Boundary

The probe records evidence only.

It must not become a printer manager, cleaner, uninstaller, or repair tool.  

