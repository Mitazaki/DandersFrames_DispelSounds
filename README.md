# DandersFrames_DispelSounds

`DandersFrames_DispelSounds` plays an alert sound when `DandersFrames` shows its dispel overlay on party or raid frames.

The addon does not try to re-evaluate dispel logic itself. It listens to `DandersFrames` overlay visibility and uses that as the source of truth. This makes it compatible with current Midnight aura and secret-data behavior, while keeping all dispel filtering under `DandersFrames` control.

## Features

- Plays a sound when a `DandersFrames` dispel overlay appears on a unit frame.
- Works for party frames and raid frames.
- Supports `LibSharedMedia-3.0` sound selection.
- Supports per-unit cooldowns to reduce spam.
- Supports repeat alerts while the overlay remains visible.
- Includes a debug mode for chat logging.
- Includes an in-game options panel and slash command access.

## Requirements

- `DandersFrames`
- Optional: `LibSharedMedia-3.0` for custom sounds

## Installation

Install the addon folder here:

`World of Warcraft\_retail_\Interface\AddOns\DandersFrames_DispelSounds`

Make sure `DandersFrames` is enabled as well.

## How It Works

This addon listens for `DandersFrames` dispel overlay show/hide events.

That means the alert behavior depends on your `DandersFrames` Debuff Overlay configuration.

Recommended setup in `DandersFrames`:

`/df > Dispel Overlay > Show Overlay for: Only dispellable by me`

If you use that setting, this addon will alert only for debuffs that `DandersFrames` considers dispellable by your character.

You can also configure which types are included in `DandersFrames`, such as:

- `Magic`
- `Curse`
- `Disease`
- `Poison`
- `Bleed/Enrage`

## Slash Commands

The addon uses the slash command:

`/dsa`

Available commands:

- `/dsa`
  Opens the options panel.

- `/dsa test`
  Plays the currently selected alert sound.

- `/dsa debug`
  Toggles debug logging to the chat window.

- `/dsa status`
  Prints the current addon status and sound configuration.

- `/dsa reset`
  Resets the addon's in-memory tracking state.

## Options

The options panel includes:

- `Enable Dispel Sound Alert`
- `Enable for Party frames`
- `Enable for Raid frames`
- `Alert Sound`
- `Sound Channel`
- `Per-Unit Cooldown`
- `Global Cooldown`
- `Repeat sound while debuff persists`
- `Repeat Interval`
- `Debug mode`

## Debug Mode

Debug mode prints chat messages when:

- a `UNIT_AURA` sync occurs
- a `DandersFrames` overlay is hooked
- an overlay appears or disappears
- a sound playback attempt happens
- cooldown protection blocks playback

Use `/dsa debug` to turn it on or off.

## Notes

- This addon is intentionally lightweight.
- It does not duplicate `DandersFrames` dispel logic.
- If alerts are not firing, check your `DandersFrames` Debuff Overlay settings first.
- If custom sounds are unavailable, the addon falls back to a built-in WoW sound.

## Version

Current version: `1.0.0-beta1`

## Author

`Numbtongue (Drinkstea-Draenor-EU)`