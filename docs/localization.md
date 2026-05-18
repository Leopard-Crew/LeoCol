# LeoCol Localization Boundary

LeoCol supports localized user-facing strings through `.lproj` resources.

## Principle

Localization must not create language-specific layouts.

The Cocoa viewer uses one layout for all supported languages.

Longer languages, especially German, are used as layout stress tests.

## Allowed

- Localized labels
- Localized column headers
- Localized status messages
- Localized state wording
- Globally robust column widths

## Not allowed

- Per-language column widths
- Per-language window sizes
- Per-language control positions
- Per-language UI structure
- Runtime layout branching based on language

## Rule

If a localized string does not fit, the default layout should be improved for all languages.

German is currently the first longer-language validation target.

## Data boundary

LeoCol's stored data remains canonical and technical.

Localization applies only to presentation strings in the Cocoa viewer.
