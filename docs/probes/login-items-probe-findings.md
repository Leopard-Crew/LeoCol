# Login Items Provenance Probe Findings

## Probe

```text
Probe/tools/leocol_login_items_probe.m
````

## Purpose

The Login Items provenance probe inventories user login items as local provenance evidence.

It is read-only.

It does not add, remove, disable, repair, or launch login items.

## Evidence target

The probe writes login item evidence into:

```text
provenance_evidence
```

with evidence type:

```text
login-item
```

## Evidence source

```text
System Events login items
```

This follows the Leopard-era native scripting interface for login items.

## Initial result

On the iMac G5 test system, the probe inserted:

```text
1 login item provenance record
```

The discovered item was:

```text
SpeechSynthesisServer
```

After improving path handling, the item resolved to:

```text
/System/Library/Frameworks/ApplicationServices.framework/Versions/A/Frameworks/SpeechSynthesis.framework/Versions/A/Resources/SpeechSynthesisServer.app
```

Resolution state:

```text
resolved
```

## Earlier probe issue

The first version detected the login item name but did not preserve the path.

That produced:

```text
observed-only
```

This was not sufficiently precise because System Events did provide a usable path.

The path extraction was made more robust by falling back to the raw AppleScript text value when POSIX path conversion is not needed or fails.

## Interpretation

The current login item baseline is clean for the tested class of stale login references.

The previously removed stale iTunesHelper login item is no longer present.

No stale login item reference was found in this run.

## Boundary

The probe records evidence only.

It must not become a login item editor, cleaner, or repair tool.

