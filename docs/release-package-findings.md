# LeoCol Release Package Findings

## Status

This document records the first successful LeoCol PPC-only release packaging
finding.

## Release candidate

~~~text
LeoCol-0.16.2-Leopard-PPC.dmg
LeoCol-0.16.2-Leopard-PPC.dmg.sha256
~~~

## Architecture

The packaged application binary was verified as PowerPC-only:

~~~text
Non-fat file: App/build/Release/LeoCol.app/Contents/MacOS/LeoCol is architecture: ppc7400
~~~

This is accepted for the LeoCol Leopard PowerPC release artifact.

The release packaging script rejects fat binaries and therefore prevents an
accidental i386/PowerPC universal binary from being published as a PPC artifact.

## SHA256

GitHub release sidecar:

~~~text
a5dc7b529f67804dae9f8a872d3bbacb49a2831251864506d1d7bbb1d21dd755  LeoCol-0.16.2-Leopard-PPC.dmg
~~~

## Included resources

The release package contains:

- LeoCol.app
- application icon
- localized English help
- localized German help
- bundled V1 probes
- README.txt
- external SHA256 sidecar file

## Release boundary

LeoCol remains:

- read-only
- manually operated
- non-daemonized
- non-mutating
- non-certifying

## GitHub release assets

The following files should be attached to the GitHub release:

~~~text
LeoCol-0.16.2-Leopard-PPC.dmg
LeoCol-0.16.2-Leopard-PPC.dmg.sha256
~~~

Do not commit these files to the repository.
