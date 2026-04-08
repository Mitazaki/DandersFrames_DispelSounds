# NT_DispelSounds

Standalone addon that plays an alert sound when a dispellable debuff is detected on party or raid members.

This addon performs its own aura scanning using the WoW `C_UnitAuras` API. No external frame addon is required.

## Features

- Plays a sound when a dispellable debuff appears on a group member.
- **Automatic mode**: Detects your class/spec dispel capabilities and only alerts for debuff types you can remove.
- **Manual mode**: Choose exactly which debuff types trigger alerts.
- Supports all dispel types: **Magic**, **Curse**, **Disease**, **Poison**, **Bleed**, **Enrage**.
- Supports racial abilities (Dwarf Stoneform, Dark Iron Fireblood) for self-dispel detection.
- Works for party frames, raid frames, and the player.
- Supports `LibSharedMedia-3.0` sound selection.
- Per-unit cooldowns to reduce spam.
- Repeat alerts while the debuff remains active.
- Debug mode for chat logging.
- In-game options panel and slash commands.

## Automatic Detection

In **Automatic** mode, the addon determines which debuff types you can dispel based on your class and specialization:

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

### Racial Abilities (Self Only)

| Race | Ability | Types |
|------|---------|-------|
| Dwarf | Stoneform | Poison, Disease, Bleed |
| Dark Iron Dwarf | Fireblood | Poison, Disease, Curse, Bleed, Magic |

Racial abilities only affect your own debuffs and are enabled via the "Include Racial abilities" option.

## Requirements

- World of Warcraft (Retail)
- Optional: `LibSharedMedia-3.0` for custom sounds

## Installation

Install the addon folder here:

`World of Warcraft\_retail_\Interface\AddOns\NT_DispelSounds`

## Slash Commands

- `/dsa` — Open the options panel
- `/dsa test` — Play the currently selected alert sound
- `/dsa debug` — Toggle debug logging
- `/dsa status` — Print current addon status
- `/dsa reset` — Reset tracking state
- `/dsa scan` — Force rescan all units
- `/dsa changelog` — Show changelog popup

## Options

The options panel includes:

**General**
- Enable Dispel Sound Alert
- Enable for Party frames
- Enable for Raid frames
- Enable for Player

**Dispel Detection**
- Detection Mode (Automatic / Manual)
- Include Racial abilities (self only)
- Manual type filters: Magic, Curse, Disease, Poison, Bleed, Enrage

**Sound**
- Alert Sound (LibSharedMedia)
- Sound Channel
- Test Sound button

**Timing**
- Per-Unit Cooldown
- Global Cooldown

**Repeat Alert**
- Repeat sound while debuff persists
- Repeat Interval

**Debug**
- Debug mode (log to chat)

## How It Works

The addon listens to `UNIT_AURA` events for party, raid, and player units. When an aura change occurs, it scans the unit's harmful auras using `C_UnitAuras.GetAuraDataByIndex`. Each aura's `dispelName` (Magic, Curse, Disease, Poison) and `dispelType` (for Bleed/Enrage) are checked against the active filter.

In **Automatic** mode, the filter is built from your class/spec dispel capabilities (updated on spec change). In **Manual** mode, you control which types are active.

When a new dispellable debuff is detected on a unit that wasn't previously tracked, the alert sound plays. Per-unit and global cooldowns prevent sound spam.

## Migrating from DandersFrames_DispelSounds

This addon uses a new `NT_DispelSoundsDB` saved variable. On first load it will
automatically migrate your settings from the old `DispelSoundAlertDB`. Your sound,
timing, and repeat settings will carry over. The addon no longer requires
DandersFrames — all dispel detection is built-in.

## Notes

- The addon automatically re-detects dispel types when you change specialization.
- GUID-based tracking ensures the same character referenced by different unit IDs (e.g., "player" and "raid5") won't cause duplicate alerts.
- Bleed and Enrage detection uses the `dispelType` integer field from aura data, which may not be available for all debuffs.
