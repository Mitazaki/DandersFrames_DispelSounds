# NT_DispelSounds

Standalone addon that plays an alert sound when a dispellable debuff is detected on party or raid members.

## Features

- Plays a sound when a dispellable debuff appears on a group member
- **Dispellable by Me** — only alerts for debuffs your class/spec can remove, updates automatically when you change specs
- **All Dispellable** — alerts for any dispellable debuff on any group member
- Racial self-dispel alerts (Dwarf Stoneform, Dark Iron Dwarf Fireblood) with a separate sound option
- Cooldown awareness — optionally only alerts when your dispel ability is off cooldown
- Re-alerts when your ability comes off cooldown if a debuff is still present
- Per-unit and global cooldowns to reduce spam
- Repeat alerts while a debuff persists
- Custom sounds via LibSharedMedia
- Works for party, raid, and the player unit
- In-game options panel and slash commands

## Detection Modes

### Dispellable by Me

Alerts only for debuffs you can actually remove with your current class and spec. For the player unit, it also checks for racial self-dispel opportunities.

| Class | Spec | Dispel Types |
|-------|------|-------------|
| Paladin | Holy | Magic, Poison, Disease |
| Paladin | Protection, Retribution | Poison, Disease |
| Priest | Discipline, Holy | Magic, Disease |
| Priest | Shadow | Disease |
| Shaman | Elemental, Enhancement | Curse |
| Shaman | Restoration | Magic, Curse |
| Mage | All | Curse |
| Monk | Brewmaster, Windwalker | Poison, Disease |
| Monk | Mistweaver | Magic, Poison, Disease |
| Druid | Balance, Feral, Guardian | Curse, Poison |
| Druid | Restoration | Magic, Curse, Poison |
| Evoker | Devastation, Augmentation | Poison, Disease, Curse, Bleed |
| Evoker | Preservation | Magic, Poison, Disease, Curse, Bleed |

### Racial Self-Dispel

On the player unit, the addon automatically detects racial dispel abilities and plays a separate sound when a debuff can be removed by your racial and it's off cooldown.

| Race | Ability | Types |
|------|---------|-------|
| Dwarf | Stoneform | Poison, Disease, Bleed |
| Dark Iron Dwarf | Fireblood | Poison, Disease, Curse, Bleed, Magic |

### All Dispellable

Alerts for any debuff that has a dispel type on any group member, regardless of your class or spec.

## Requirements

- World of Warcraft (Retail)
- Optional: LibSharedMedia-3.0 for custom sounds

## Installation

Place the addon folder in:

`World of Warcraft\_retail_\Interface\AddOns\NT_DispelSounds`

## Slash Commands

| Command | Description |
|---------|-------------|
| `/dsa` | Open the options panel |
| `/dsa test` | Play the alert sound |
| `/dsa debug` | Toggle debug logging |
| `/dsa status` | Show current status |
| `/dsa reset` | Reset tracking state |
| `/dsa scan` | Force rescan all units |
| `/dsa changelog` | Show changelog popup |

## Options

**General** — Enable/disable the addon, party, raid, and player alerts.

**Dispel Detection** — Choose detection mode and cooldown awareness.

**Sound** — Select alert sound and channel. Separate sound for racial alerts.

**Timing** — Per-unit and global cooldowns.

**Repeat** — Repeat alerts while debuffs persist.

**Debug** — Chat logging for troubleshooting.

## Migrating from DandersFrames_DispelSounds

Settings are automatically migrated from the old saved variables on first load. DandersFrames is no longer required.
