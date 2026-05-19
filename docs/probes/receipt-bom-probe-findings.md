# Receipt BOM Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_receipt_bom_probe.m
````

## Purpose

The Receipt BOM provenance probe inventories package receipts and their BOM summaries as local provenance evidence.

It is read-only.

It does not uninstall, delete, repair, quarantine, or modify receipts or files.

## Evidence target

The probe writes evidence into:

```text
provenance_evidence
```

with evidence type:

```text
receipt-bom
```

## Evidence source

```text
/Library/Receipts
/usr/bin/lsbom
```

## Initial result

On the iMac G5 test system, the probe initially inserted:

```text
169 receipt BOM provenance records
```

The initial result showed:

```text
observed-only  1
resolved       168
```

## Printer receipt review

The initial printer-related receipt review showed:

```text
BrotherPPD5                        observed-only
BrotherPPD6                        resolved
BrotherSTM5                        resolved
Toshiba e-Studio 280:283 Series    resolved
tap                                resolved
tap-1                              resolved
tun                                resolved
tun-1                              resolved
```

The Toshiba receipt pointed to live Toshiba printer files under `/Library/Printers`.

That printer stack was not part of the accepted active CUPS configuration.

## Toshiba cleanup validation

After quarantining the Toshiba printer stack, the CUPS and Receipt BOM probes were rerun.

The CUPS layer showed:

```text
printer-queue  Jotunnheim  resolved
```

The Receipt BOM state became:

```text
observed-only  1
resolved       167
```

The follow-up printer/TunTap receipt review showed:

```text
BrotherPPD5   observed-only
BrotherPPD6   resolved
BrotherSTM5   resolved
tap           resolved
tap-1         resolved
tun           resolved
tun-1         resolved
```

No Toshiba receipt remained in the reviewed receipt set.

No HP receipt appeared in the reviewed receipt set.

## Interpretation

The Toshiba printer stack was a valid inactive-printer artifact and has been removed from the active system tree.

The active CUPS layer remains resolved through:

```text
Jotunnheim / Lexmark
```

The remaining Brother entries are currently receipt-level sediment.

They are not shown by the CUPS probe as active printer queues or orphan PPD files.

The TunTap receipts are accepted because they correspond to the accepted Tunnelblick / TunTapOSX / LeoTunnel-related baseline.

## Boundary

The probe records receipt evidence only.

A receipt match proves package provenance.

It does not prove current usefulness.

A missing or incomplete BOM does not automatically mean malware or danger.


