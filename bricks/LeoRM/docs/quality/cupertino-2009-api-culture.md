# Cupertino 2009 API Culture for LeoRM

LeoRM is a system brick.

Therefore LeoRM must follow a higher standard than a quick helper library or application-local utility.

Cupertino-2009 quality means that the public API is treated as a product surface: named carefully, documented clearly, tested on the target system, and designed to feel native to Mac OS X 10.5.8 Leopard.

## Core doctrine

LeoRM must be:

- small,
- explicit,
- predictable,
- Foundation-shaped,
- SQLite-honest,
- Leopard-native,
- manually memory-managed,
- warning-free,
- domain-neutral,
- documented at the API boundary.

## Public headers are contracts

Every public header must explain:

- what the class is responsible for,
- what the class is not responsible for,
- who owns returned objects,
- whether returned objects are autoreleased,
- whether the caller must close or finalize anything,
- what happens on error,
- which NSError domain and codes are used,
- whether nil is valid input,
- whether nil is valid output,
- whether the method requires an open database,
- whether the method mutates database state.

A header is not just a compiler interface.

A header is the first layer of documentation.

## Naming

Names must be boring, clear, and consistent.

Rules:

- public classes use the `LRM` prefix,
- method names should describe exact behavior,
- no clever abbreviations,
- no domain names in LeoRM core,
- no hidden magic behind friendly names,
- no API that sounds broader than it is.

Good:

```objc
- (BOOL)executeSQL:(NSString *)sql arguments:(NSArray *)arguments error:(NSError **)error;
````

Bad:

```objc
- (NSArray *)findAll;
```

Unless the scope and SQL behavior are explicitly owned by a domain repository.

## NSError culture

LeoRM uses NSError as its failure vocabulary.

Every fallible public method should either:

- return `BOOL` and accept `NSError **`,
    
- return an object and accept `NSError **`,
    
- or document why it cannot fail.
    

Error information should include useful context where possible:

- LeoRM error domain,
    
- SQLite result code,
    
- SQLite message,
    
- SQL string,
    
- database path,
    
- human-readable description.
    

Errors should be useful without stepping into LeoRM internals.

## Ownership culture

LeoRM targets manual retain/release.

Therefore ownership must be explicit.

Rules:

- factory methods return autoreleased objects,
    
- `init...` methods return owned objects,
    
- `close`, `finalizeStatement`, and transaction methods define lifecycle boundaries,
    
- dealloc may clean up defensively,
    
- defensive cleanup must not hide API misuse,
    
- returned row objects must document their valid lifetime,
    
- result sets must document when statements are finalized.
    

No public API may rely on ARC assumptions.

## SQL visibility

LeoRM must not hide SQL as the default model.

Rules:

- SQL should remain visible at repository boundaries,
    
- generated SQL, if ever added, must be inspectable,
    
- schema ownership belongs to domain stores or applications,
    
- LeoRM metadata must stay small and documented,
    
- normal SQLite tools should remain useful for inspecting databases.
    

SQLite is not an implementation embarrassment.

SQLite is the storage contract.

## Target-system verification

No LeoRM release is valid only because it builds on a modern machine.

A release must be verified on:

- Mac OS X 10.5.8 Leopard,
    
- PowerPC,
    
- MacOSX10.5.sdk,
    
- Xcode 3.1.4-compatible toolchain,
    
- Foundation.framework,
    
- libsqlite3,
    
- manual memory management.
    

The standard smoke path is:

```sh
make clean
make
make smoke
```

The build should be warning-free.

## Required quality gates

For LeoRM system-brick releases, the following are standard requirements, not optional critic-appeasement:

- failure-path tests,
    
- constraint-error tests,
    
- transaction rollback tests,
    
- migration-failure rollback tests,
    
- nil / NSNull behavior tests,
    
- NSData binding and row-reading tests,
    
- NSNumber integer and floating-point tests,
    
- NSString UTF-8 behavior tests,
    
- file-backed database example,
    
- memory / leak review on Leopard,
    
- public API header documentation,
    
- ownership rules,
    
- release artifact or reproducible build path,
    
- documented target-system verification.
    

If a release does not meet a gate, the release notes must say so explicitly.

## Examples are part of the API culture

Examples must prove real layering.

A good example:

- defines a domain object outside LeoRM,
    
- defines a domain store outside LeoRM,
    
- uses migrations,
    
- uses repositories,
    
- reads rows through LeoRM,
    
- keeps SQL visible,
    
- does not add domain logic to LeoRM core.
    

The NotesStore example exists for this reason.

## No accidental framework growth

LeoRM must not grow because an application wants a shortcut.

Before adding a feature, ask:

- Is this useful for many SQLite-backed Leopard-Crew projects?
    
- Does it require domain knowledge?
    
- Does it hide SQL?
    
- Does it duplicate Core Data?
    
- Does it make the public API harder to explain?
    
- Does it require modern runtime assumptions?
    
- Can it be tested on Leopard / PowerPC?
    

If the feature knows what the data means, it belongs above LeoRM.

## Release language

LeoRM release language should be precise.

Use:

- verified foundation release,
    
- storage brick,
    
- Repository/DAO layer,
    
- explicit SQLite schema support,
    
- Leopard / PowerPC verified.
    

Avoid:

- full ORM,
    
- Core Data replacement,
    
- modern database framework,
    
- magical persistence,
    
- universal solution.
    

## Doctrine

Cupertino-2009 quality is not decoration.

It is the API culture:

- public surface matters,
    
- naming matters,
    
- ownership matters,
    
- errors matter,
    
- target behavior matters,
    
- documentation matters,
    
- examples matter,
    
- restraint matters.
    

LeoRM should feel like a small native system component that Apple could plausibly have shipped for developers who wanted explicit SQLite without leaving Cocoa culture.  

