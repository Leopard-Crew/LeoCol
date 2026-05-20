# LeoCol Snapshot Overview Plan

## Purpose

LeoCol is snapshot-based.

This document defines the planned Snapshot Overview feature for LeoCol V1.

The goal is to make existing process snapshots visible and understandable.

## Problem

LeoCol currently shows process lifecycle rows with values such as:

- first seen,
- last seen,
- observed,
- executable state.

However, the user cannot yet see which process snapshots exist in the database.

This can make `Last seen` look like a live state, although it means:

    last seen in a LeoCol process snapshot

It does not mean:

    currently running

## Decision

LeoCol V1 needs a Snapshot Overview.

The overview should show available snapshot runs from the database.

## Data source

The initial overview should read from:

- snapshot_run
- process_observation

The schema already has the required base tables:

- snapshot_run.id
- snapshot_run.observed_at
- snapshot_run.source
- process_observation.snapshot_id

## Initial columns

The first Snapshot Overview should show:

- Snapshot ID
- Observed At
- Source
- Process Count

Example:

    Snapshot ID   Observed At              Source      Process Count
    17            2026-05-17 14:33:12      manual      72
    18            2026-05-20 08:42:03      manual      69

## User-facing command

English:

    View
      Show Snapshots

German:

    Darstellung
      Momentaufnahmen anzeigen

Alternatively, the first implementation may place it under File / Ablage if no View menu exists yet.

## Preferred V1 UI

Use a small read-only NSPanel with an NSTableView.

This follows the same direction as the Provenance Evidence Summary panel.

The panel must be read-only.

No delete, merge, repair, or cleanup actions.

## Relationship to Reload

Reload only reloads the current database view.

Reload does not create a new snapshot.

Reload does not update evidence.

Reload does not change the database.

## Relationship to Update Snapshot

Update Snapshot is a future command.

It should create a new process snapshot and update process lifecycle data.

After Update Snapshot, the Snapshot Overview should show the new snapshot.

## Relationship to Update Evidence

Update Evidence updates provenance evidence.

It does not create process snapshots.

Snapshot Overview should not be changed by Update Evidence unless a future implementation explicitly records evidence update runs separately.

## Status communication

The main viewer should eventually expose the latest snapshot timestamp.

Possible status text:

    Showing 72 of 72 rows — Last snapshot: 2026-05-20 08:42

German:

    72 von 72 Zeilen — Letzte Momentaufnahme: 20.05.2026 08:42

## Report integration

The exported report should eventually include:

- latest snapshot timestamp,
- snapshot count,
- optionally a snapshot summary section.

This will make exported reports more honest and easier to compare.

## Non-goals

Snapshot Overview must not:

- delete snapshots,
- edit snapshots,
- merge snapshots,
- hide snapshots,
- classify snapshots as good or bad,
- imply live process monitoring.

## V1 acceptance criteria

Snapshot Overview is acceptable when:

- it opens from the app,
- it reads snapshot_run from the database,
- it shows process counts per snapshot,
- it is read-only,
- it makes snapshot-based semantics clearer,
- it does not imply that LeoCol is a live task manager.

## Guiding rule

LeoCol should clearly distinguish:

    database memory

from:

    live system state
