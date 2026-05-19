# Launch Sources Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_launch_sources_probe.m
````

## Purpose

The launch sources provenance probe inventories LaunchAgents and LaunchDaemons as local evidence.

It is read-only.

It does not unload, disable, delete, quarantine, or repair anything.

## Scanned locations

The initial probe scans:

```text
/System/Library/LaunchAgents
/System/Library/LaunchDaemons
/Library/LaunchAgents
/Library/LaunchDaemons
~/Library/LaunchAgents
```

## Evidence target

The probe writes launch evidence into:

```text
provenance_evidence
```

with evidence types:

```text
launch-agent
launch-daemon
```

## Initial Leopard G5 result

On the iMac G5 test system, the probe inserted:

```text
186 launch provenance records
```

Grouped result:

```text
launch-agent   resolved   53
launch-daemon  resolved   133
```

No stale launch references were found in this run.

## Interpretation

This is a good baseline result.

It means the currently scanned LaunchAgent and LaunchDaemon plists refer to existing absolute program paths, where such paths were available.

This does not mean the whole system is artifact-free.

It only means this probe found no stale LaunchAgent or LaunchDaemon program references.

## Boundary

The probe records evidence only.

It must not become a cleaner, uninstaller, task manager, or malware scanner.

