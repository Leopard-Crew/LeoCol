# Process Snapshot Probe Findings

## Test system

The first process snapshot probe was built and run successfully on Mac OS X 10.5.8 PowerPC.

## Result

The probe can collect a conservative process table snapshot without root privileges.

Confirmed fields:

- snapshot timestamp,
- pid,
- ppid,
- uid,
- kernel process name,
- best-effort executable path hint.

## Confirmed Leopard behavior

`KERN_PROC` / `KERN_PROC_ALL` works for collecting the process list.

`KERN_PROCARGS2` can provide useful executable path hints when called with a preallocated `_SC_ARG_MAX`-sized buffer.

A preliminary NULL-size query is not reliable enough for this Leopard/PPC probe.

## Example findings

The probe resolved executable hints for common user-session processes, including:

- loginwindow,
- Finder,
- Dock,
- SystemUIServer,
- Terminal,
- Xcode,
- AppleSpell,
- ARDAgent,
- AppleVNCServer,
- user launchd,
- sshd,
- sftp-server.

## Important limitation

The `process_name` field comes from the kernel process table and may be truncated.

Examples observed on Leopard include shortened names such as:

- `AirPort Base Sta`,
- `HP IO Classic Pr`,
- `SpeechSynthesisS`.

Therefore, `process_name` must be treated as a display hint only.

LeoCol identity resolution must prefer executable paths, bundle containment, Info.plist metadata, and resolver confidence.

## Expected unknowns

Some system or kernel-level processes legitimately produce no executable hint.

Examples include:

- `kernel_task`,
- early root-owned daemons,
- protected or special system processes.

A missing executable hint is not an error by itself.

## Phase 1 status

The Phase 1 process snapshot probe is successful.

LeoCol can now see enough Leopard process state to justify the next implementation phase: a small persistent SQLite journal.
