# LeoCol V1 Roadmap

## Goal

LeoCol V1 proves that Mac OS X 10.5.8 Leopard can keep a small, useful process history without private APIs, kernel extensions, or heavy monitoring infrastructure.

V1 should answer one core question:

> What ran on this Leopard system, when was it seen, where did it live, and what did it likely belong to?

## V1 principle

V1 prefers boring correctness over cleverness.

A sampled observation is acceptable.
A false claim is not.

LeoCol must clearly distinguish:

- observed facts,
- derived identities,
- weak hints,
- and unknowns.

## Phase 1: Process snapshot probe

Create a small command-line probe that prints a process snapshot.

Required fields:

- pid,
- ppid,
- uid,
- process name,
- executable path when available,
- sampled timestamp.

The probe may initially use POSIX / sysctl mechanisms available on Leopard.

No database yet.
No GUI yet.
No launchd integration yet.

Success condition:

- the probe builds on Mac OS X 10.5.8 PowerPC,
- runs without special privileges,
- prints a stable text snapshot,
- and does not crash when process details are unavailable.

## Phase 2: SQLite journal prototype

Store sampled process observations in a SQLite journal.

Required behavior:

- open or create a LeoCol database,
- create schema if missing,
- insert process observations,
- keep timestamps readable,
- report SQLite errors explicitly.

LeoRM may be used below LeoColStore if its integration keeps the code smaller and clearer.

Success condition:

- running the probe twice creates persistent observations,
- the database can be inspected with the Leopard sqlite3 tool,
- and missing optional fields do not break inserts.

## Phase 3: Lifecycle aggregation

Add approximate lifecycle tracking.

Required behavior:

- detect first-seen processes between samples,
- update last-seen timestamps,
- mark disappeared processes as exit-observed when possible,
- avoid claiming exact start or exit times.

Success condition:

- short-lived test processes appear in the journal,
- long-running processes get updated instead of duplicated incorrectly,
- and lifecycle rows remain explainable.

## Phase 4: Identity resolver

Resolve process observations into Leopard identities.

Initial identity sources:

- executable path,
- .app bundle containment,
- Info.plist metadata,
- bundle identifier,
- known Apple system paths,
- known user application paths,
- known MacPorts paths,
- developer build paths.

Initial classifications:

- Apple system component,
- Apple application,
- user application,
- helper tool,
- command-line tool,
- MacPorts tool,
- developer build,
- unknown.

Success condition:

- common Leopard processes receive useful classifications,
- unknown remains a normal result,
- and resolver confidence is stored explicitly.

## Phase 5: LaunchAgent sampler

Wrap the collector as a lightweight LaunchAgent.

Required behavior:

- run at a conservative interval,
- write to the user-level LeoCol journal,
- avoid excessive disk writes,
- stop cleanly,
- log errors plainly.

Success condition:

- LeoCol can collect observations over time without a manually open Terminal session.

## Phase 6: Native Cocoa viewer

Create LeoCol.app as a native Leopard Cocoa viewer.

Initial views:

- daily process history,
- process detail,
- identity explanation,
- raw observations,
- simple filtering by classification.

Initial actions:

- reveal executable in Finder,
- reveal bundle in Finder,
- copy process details,
- polite quit where applicable,
- terminate only as explicit user action.

Success condition:

- LeoCol.app helps the user understand system history better than Activity Monitor alone.

## Explicit V1 non-goals

V1 does not include:

- private APIs,
- kernel extensions,
- DTrace dependency,
- network firewalling,
- malware scoring,
- webcam or microphone monitoring,
- automatic blocking,
- automatic cleanup,
- automatic launchd modification,
- system optimization claims,
- or real-time enforcement.

## V1 done means

LeoCol V1 is done when it can run quietly on Leopard, collect process history, classify common processes, and present the result in a small native Cocoa application.

It does not need to be impressive.

It needs to be trustworthy.
