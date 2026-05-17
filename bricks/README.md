# LeoCol Bricks

This directory contains first-party Leopard-Crew / quietcode.org bricks that LeoCol may use.

`bricks/` is not `vendor/`.

## Meaning

- `vendor/` is reserved for third-party or upstream reference material.
- `bricks/` is reserved for related first-party building blocks that are intentionally part of the Leopard-Crew / quietcode architecture.

## Current bricks

### LeoRM

LeoRM is a small Leopard-native Repository/DAO-style helper around SQLite.

LeoCol may use LeoRM below `LeoColStore` for:

- database open and close handling,
- prepared statements,
- transactions,
- explicit migrations,
- SQLite error handling,
- and small repository helpers.

LeoRM must not own LeoCol's domain model.

LeoCol remains responsible for:

- process observation meaning,
- snapshot runs,
- lifecycle aggregation,
- identity resolution,
- classification rules,
- and user-facing interpretation.

## Rule

A brick may support LeoCol.

A brick must not turn LeoCol into a framework demo.

