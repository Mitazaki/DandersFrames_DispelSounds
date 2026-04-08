# NT_DispelSounds

Standalone addon that plays an alert sound when a dispellable debuff is detected on party or raid members.

This addon performs its own aura scanning using the WoW `C_UnitAuras` API. No external frame addon is required.

## Features

- Plays a sound when a dispellable debuff appears on a group member.
- **Dispellable by Me**: Uses Blizzard's `RAID_PLAYER_DISPELLABLE` filter to alert only for debuffs your class/spec can remove.
- **All Dispellable**: Alerts for any debuff with a dispel type (Magic, Curse, Disease, Poison).
- Both modes are fully combat-safe (uses WoW's secret-value-safe APIs).
- Supports racial abilities (Dwarf Stoneform, Dark Iron Fireblood) for self-dispel detection.
- Works for party frames, raid frames, and the player.
- Supports `LibSharedMedia-3.0` sound selection.
- Per-unit cooldowns to reduce spam.
- Repeat alerts while the debuff remains active.
- Debug mode for chat logging.
- In-game options panel and slash commands.

## Automatic Detection

In **Dispellable by Me** mode, WoW's built-in `RAID_PLAYER_DISPELLABLE` aura filter handles class/spec detection. The table below shows reference info for what each spec can dispel:

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
- Detection Mode (Dispellable by Me / All Dispellable)
- Include Racial abilities (self only)

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

The addon listens to `UNIT_AURA` events for party, raid, and player units. When an aura change occurs, it scans the unit's harmful auras using `C_UnitAuras.GetAuraDataByIndex`.

In **Dispellable by Me** mode, each aura's `auraInstanceID` is checked against Blizzard's `RAID_PLAYER_DISPELLABLE` filter via `C_UnitAuras.IsAuraFilteredOut`. This is combat-safe and handles class/spec detection natively.

In **All Dispellable** mode, the addon checks `auraData.dispelName ~= nil` (a safe nil-check on secret values) to detect any dispellable debuff.

> **Note:** WoW marks aura data fields as "secret" values, which cannot be read as strings or used as table keys. This prevents per-type filtering (e.g. alert only for Magic). Both modes use combat-safe APIs that work within this restriction.

When a new dispellable debuff is detected on a unit that wasn't previously tracked, the alert sound plays. Per-unit and global cooldowns prevent sound spam.

## Migrating from DandersFrames_DispelSounds

This addon uses a new `NT_DispelSoundsDB` saved variable. On first load it will
automatically migrate your settings from the old `DispelSoundAlertDB`. Your sound,
timing, and repeat settings will carry over. The addon no longer requires
DandersFrames — all dispel detection is built-in.

## Notes

- The addon automatically re-detects dispel types when you change specialization.
- GUID-based tracking ensures the same character referenced by different unit IDs (e.g., "player" and "raid5") won't cause duplicate alerts.
- Aura field secret values (dispelName, dispelType, etc.) cannot be read in WoW — only nil-checked or filtered via Blizzard APIs.
