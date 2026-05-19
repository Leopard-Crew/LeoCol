# Kext Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_kext_probe.m
````

## Purpose

The kext provenance probe inventories currently loaded kernel extensions as local provenance evidence.

It is read-only.

It does not load, unload, disable, delete, quarantine, or repair kernel extensions.

## Evidence target

The probe writes evidence into:

```text
provenance_evidence
```

with evidence type:

```text
kext
```

## Evidence source

```text
kextstat
```

The probe also scans local kext bundles in:

```text
/System/Library/Extensions
/Library/Extensions
```

to resolve loaded bundle identifiers to bundle paths.

## Initial Leopard G5 result

After fixing kextstat parsing, the probe recorded:

```text
kext | observed-only | 43
kext | resolved      | 59
```

Important TunTap-related results:

```text
org.tntpsx.tap | /Library/Extensions/tap.kext | resolved
org.tntpsx.tun | /Library/Extensions/tun.kext | resolved
```

## Parser correction

The first parser version extracted the wrong part of the `kextstat` line.

It treated the version field inside parentheses as if it were the bundle identifier.

The parser was corrected to extract the bundle identifier immediately before the version parentheses.

## Query note

Searching for TunTap-related kexts with:

```sql
LIKE '%tap%'
```

can also match unrelated identifiers such as:

```text
IOATAPIProtocolTransport
```

because `ATAPI` contains a case-insensitive `tap` sequence.

For precise TunTap checks, use:

```sql
subject_identifier IN ('org.tntpsx.tap', 'org.tntpsx.tun')
```

## Interpretation

The TunTap kernel extension layer is now explicitly visible and resolved.

Together with the StartupItems probe, LeoCol can now show both sides of this legacy system component:

```text
/Library/StartupItems/tap  -> startup-item evidence
/Library/StartupItems/tun  -> startup-item evidence
org.tntpsx.tap             -> loaded kext evidence
org.tntpsx.tun             -> loaded kext evidence
```

This matches the accepted Tunnelblick / TunTapOSX / LeoTunnel-related baseline.

## Boundary

The probe records evidence only.

It must not become a kext manager, cleaner, repair tool, or malware scanner.  

