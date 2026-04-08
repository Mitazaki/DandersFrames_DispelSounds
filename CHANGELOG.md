# Changelog

## v2.0.0

### Renamed to NT_DispelSounds
- Previously DandersFrames_DispelSounds. Now fully standalone — DandersFrames is no longer required.

### Two Detection Modes
- **Dispellable by Me** — only alerts for debuffs your class/spec can remove. Automatically updates when you change specs.
- **All Dispellable** — alerts for any dispellable debuff on any group member.

### Racial Self-Dispel
- Automatic racial alert for Dwarves (Stoneform) and Dark Iron Dwarves (Fireblood) when you have a dispellable debuff on yourself.
- Separate sound option for racial alerts so you can distinguish them from spec dispel alerts.
- Only alerts when the racial ability is off cooldown.

### Cooldown Awareness
- New option: "Only alert when ability is ready" — suppresses alerts when your dispel is on cooldown.
- Re-scans and alerts when your ability comes off cooldown if a debuff is still present.
- Ignores the GCD so alerts still fire during normal gameplay.

### Other
- Player unit monitoring — enable/disable alerts for your own character.
- Settings are automatically migrated from the old saved variables.
