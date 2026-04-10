# NT_DispelSounds

**NT_DispelSounds** plays an alert sound when a dispellable debuff is detected on your party or raid frames.

It works as a standalone addon and does not require DandersFrames.

## Features

- Plays a sound when a dispellable debuff appears on a group member
- Supports **Dispellable by Me** and **All Dispellable** detection modes
- Supports LibSharedMedia-3.0 sound selection
- Supports per-unit and global cooldowns to reduce spam
- Supports repeat alerts while the debuff remains active
- Supports role-based filtering for your current spec: Healer, DPS, Tank
- Includes an in-game options panel with sidebar navigation
- Includes profile management for addon settings
- Includes debug mode for chat logging

## Detection Modes

### Dispellable by Me

Alerts only for debuffs your character can remove with the current spec.

This mode follows Blizzard's player-dispellable filtering and matches the behavior used by DandersFrames for standard dispel checks.

### All Dispellable

Alerts for any debuff with a standard dispel type on any group member.

## Requirements

- World of Warcraft (Retail)
- Optional: LibSharedMedia-3.0 for custom sounds

## Installation

Install the addon folder here:

`World of Warcraft\_retail_\Interface\AddOns\NT_DispelSounds`

## How It Works

The addon scans party and raid units directly and plays the selected sound when a matching debuff is found.

Alert behavior depends on:

- your selected detection mode
- your current specialization role filter
- your sound cooldown settings
- whether repeat alerts are enabled

## Slash Commands

The addon uses the slash command:

`/dsa`

**Available commands:**

- `/dsa` - Opens the options panel
- `/dsa test` - Plays the currently selected alert sound
- `/dsa debug` - Toggles debug logging to the chat window
- `/dsa status` - Prints the current addon status and sound configuration
- `/dsa reset` - Resets the addon's in-memory tracking state
- `/dsa scan` - Forces a rescan of group members
- `/dsa changelog` - Opens the changelog page

## Options

- Enable Dispel Sound Alert
- Detection Mode
- Role Filter: Healer, DPS, Tank
- Alert Sound
- Sound Channel
- Per-Unit Cooldown
- Global Cooldown
- Repeat sound while debuff persists
- Repeat Interval
- Debug mode
- Profiles management

## Profiles

The addon includes profile support so you can:

- create a new profile
- switch between profiles
- copy the current profile
- rename profiles
- delete unused profiles

## Debug Mode

Debug mode prints chat messages when:

- a unit is scanned for matching debuffs
- a dispellable debuff is detected or cleared
- a sound playback attempt happens
- cooldown protection blocks playback

Use `/dsa debug` to turn it on or off.

## Notes

- This addon is standalone
- It does not require DandersFrames
- In follower dungeons, NPC companions count as party members
- If custom sounds are unavailable, the addon falls back to a built-in WoW sound

## Version

`v0.9.0b`

## Author

`Numbtongue (Drinkstea-Draenor-EU)`
