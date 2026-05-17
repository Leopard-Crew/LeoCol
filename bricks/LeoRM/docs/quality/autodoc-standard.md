# LeoRM Autodoc Standard

LeoRM public headers are part of the product.

For a system brick, undocumented public API is not acceptable. LeoRM targets a frozen platform, Mac OS X 10.5.8 Leopard / PowerPC, so API ambiguity should be removed before release rather than patched through repeated maintenance updates.

## Goal

Every public LeoRM header must be readable as developer documentation.

The header should explain:

- purpose,
- responsibility,
- non-responsibility,
- ownership,
- lifecycle,
- error behavior,
- required preconditions,
- valid nil behavior,
- returned object lifetime,
- SQLite visibility,
- Leopard / manual memory management expectations.

## Style

LeoRM uses HeaderDoc-style comments for public API documentation.

The documentation should be plain, explicit, and boring.

Good documentation explains what the method does, what the caller owns, what can fail, and what remains plain, explicit, and boring.

Good documentation explains what the method does, what the caller owns, what can fail, and what remains visible.

Bad documentation repeats the method name without adding operational meaning.

## Required class documentation

Each public class header must document:

- what the class represents,
- which lower-level resource it wraps, if any,
- whether the class owns that resource,
- whether the class is domain-neutral,
- whether the class hides or exposes SQL,
- whether instances are reusable,
- whether instances require an open database,
- which lifecycle method ends the useful lifetime.

## Required method documentation

Each public method must document:

- parameters,
- return value,
- ownership of returned objects,
- whether the return is autoreleased,
- what happens on failure,
- whether NSError is filled on failure,
- whether nil is valid input,
- whether nil is a valid return value,
- whether the method requires an open database,
- whether the method changes database state,
- whether the method finalizes, closes, commits, or rolls back resources.

## Ownership language

Use explicit ownership language.

Examples:

- "Returns an autoreleased object."
- "The caller does not own the returned object."
- "The result remains valid only until the result set advances or closes."
- "Calling close ends the result set and finalizes the underlying statement."
- "dealloc performs defensive cleanup, but callers should close explicitly."

## Error language

Every fallible method should state its error behavior.

Examples:

- "Returns NO and stores an NSError in error when the operation fails."
- "Returns nil and stores an NSError in error when the statement cannot be prepared."
- "The NSError uses LRMErrorDomain."
- "SQLite failures are reported through LRMSQLiteErrorMake."

## SQLite visibility

Documentation must not pretend SQLite is hidden.

If a method accepts SQL, the documentation says so.

If a class wraps an SQLite connection, statement, or row, the documentation says so.

If an operation finalizes a sqlite3_stmt, the documentation says so.

## Manual memory management

LeoRM targets manual retain/release.

Public documentation must avoid ARC assumptions.

Factory methods return autoreleased objects.

Initializer methods return owned objects under normal Cocoa rules.

## Frozen-platform rule

Mac OS X 10.5.8 is frozen.

LeoRM should therefore prefer explicit API documentation over future corrective churn.

If behavior is unclear, document it before release or do not expose the API yet.

## Release gate

No LeoRM system-brick release should be tagged unless public headers are documented according to this standard or the release notes explicitly state which headers remain undocumented.
