# Changelog

## v0.9.0b — Major Overhaul + Initial Standalone Release

### Renamed to NT_DispelSounds
- Previously DandersFrames_DispelSounds. Now fully standalone — DandersFrames is no longer required.

### New Options UI
- Sidebar navigation with four pages: Options, Changelog, Profiles, Author.
- Wider panel layout with clean page switching.

### Profile System
- Create, copy, switch, rename, and delete settings profiles.
- Settings are stored per-profile in saved variables.
- Existing settings are automatically migrated into a "Default" profile.

### Role Filtering
- New toggles to enable/disable alerts per role: Healer, DPS, Tank.
- Units with no assigned role always trigger alerts.

### Author Page
- Links to Wago, CurseForge, and donation page with copy-to-clipboard dialogs.

### Renamed to NT_DispelSounds
- Previously DandersFrames_DispelSounds. Now fully standalone — DandersFrames is no longer required.

### Two Detection Modes
- **Dispellable by Me** — only alerts for debuffs your class/spec can remove. Automatically updates when you change specs.
- **All Dispellable** — alerts for any dispellable debuff on any group member.

### Other
- Settings are automatically migrated from the old saved variables.

## Initial Release (DandersFrames_DispelSounds)

### Initial release
- Release with DandersFrames dependency