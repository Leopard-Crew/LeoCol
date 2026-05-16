# LeoCol Scope

## One-line definition

LeoCol is a native Mac OS X Leopard system collector that records process and application lifecycle observations into a small historical journal.

## What LeoCol is

LeoCol is a system memory layer for Leopard.

It collects facts that are normally visible only for a short time or only through separate tools:

- process appearance,
- process disappearance,
- executable path,
- parent process,
- user,
- observed resource usage,
- application bundle identity,
- launchd relationship hints,
- and basic classification.

LeoCol does not try to decide whether software is good, bad, safe, or unsafe.

It records and explains observable system behavior.

## What LeoCol is not

LeoCol is not:

- an Activity Monitor clone,
- an iStat clone,
- a Little Snitch clone,
- an antivirus tool,
- a malware scanner,
- a firewall,
- a system cleaner,
- a task killer,
- a tuning suite,
- a modern privacy permission simulator,
- or a Windows AppControl port.

## V1 target

V1 records a conservative process history:

- process ID,
- parent process ID,
- executable name,
- executable path when available,
- first seen timestamp,
- last seen timestamp,
- exit observation when detectable,
- user ID,
- lightweight CPU and memory samples,
- simple bundle resolution,
- and basic origin classification.

V1 provides a native Cocoa viewer for this history.

## V1 non-goals

V1 deliberately excludes:

- kernel extensions,
- private APIs,
- DTrace dependency,
- webcam and microphone access detection,
- network firewalling,
- code signing policy enforcement,
- automatic cleanup,
- automatic blocking,
- malware scoring,
- and deep forensic claims.

## Design rule

LeoCol must be useful even when it only tells the truth it can actually observe.

Unknown is an acceptable result.

Guessing is not.
