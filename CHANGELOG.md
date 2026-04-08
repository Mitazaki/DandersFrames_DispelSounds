# Changelog

## v2.0.0

### Renamed to NT_DispelSounds
- Previously DandersFrames_DispelSounds. Now fully standalone — DandersFrames is no longer required.

### Two Detection Modes
- **Dispellable by Me** — only alerts for debuffs your class/spec can remove. Automatically updates when you change specs.
- **All Dispellable** — alerts for any dispellable debuff on any group member.

### Cooldown Awareness
- New option: "Only alert when ability is ready" — suppresses alerts when your dispel is on cooldown.
- Tracks your class/spec dispel ability cooldown in combat.
- Re-scans and alerts when your ability comes off cooldown if a debuff is still present.
- Ignores the GCD so alerts still fire during normal gameplay.

### Other
- Player unit monitoring — enable/disable alerts for your own character.
- Settings are automatically migrated from the old saved variables.
