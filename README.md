# Poof

Poof is a macOS-native text snippet expander menubar app.

## Current v1 behavior

- Menubar-only app (`LSUIElement`-style behavior via accessory activation policy)
- Global snippet expansion via typed triggers
- Trigger mode is user-selectable:
  - Delimiter mode: expand after trigger + delimiter
  - Immediate mode: expand as soon as trigger is fully typed
- Optional launch-at-login toggle in Settings
- TOML-driven config from a user-selectable directory
- Multiple config files are loaded recursively from that directory (`**/*.toml`)

## Config directory

Default:

`~/Library/Application Support/Poof`

On first launch, Poof creates:

- `snippets/default.toml`

You can change the config directory from `Settings…`.

## TOML format

Use `[[snippets]]` entries in any `.toml` file:

```toml
[[snippets]]
trigger = ":date"
replace = "{{date}}"
description = "Current date"

[[snippets]]
trigger = ":sig"
replace = "Best regards,\nYour Name{{cursor}}"
case_sensitive = true
```

Supported template tokens:

- `{{date}}` -> `yyyy-MM-dd`
- `{{time}}` -> `HH:mm`
- `{{datetime}}` -> `yyyy-MM-dd HH:mm`
- `{{date:<format>}}` -> custom `DateFormatter` format
- `{{clipboard}}` -> current clipboard text
- `{{uuid}}` -> random UUID
- `{{cursor}}` -> cursor landing position after expansion

## Build

```bash
swift build
swift run
```

## Xcode project

```bash
bin/generate-xcodeproj
open Poof.xcodeproj
```

`AppIcon` is configured on the app target, so app icon handling is managed by the asset catalog.

## Raycast import

```bash
just import-raycast "/path/to/Snippets.json"
```
