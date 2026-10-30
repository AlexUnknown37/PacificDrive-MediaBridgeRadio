# Nexus mod page: MediaBridge Radio

## Basic fields

- **Mod name:** MediaBridge Radio - Your Music on the Car Radio
- **Version:** 1.1.4
- **Category:** Audio (or Miscellaneous if Audio isn't listed)
- **Author:** AlexUnknown37
- **Language:** English
- **Tags:** Audio, Music, Radio, UI, Quality of Life
- **Contains adult content:** No

**Brief overview** (the short summary under the title):

> Play your own music (Spotify, browser, any music app) on the car radio, with the game's 3D sound. The radio's channel buttons skip songs, and the screen shows the real song title and artist. Uses the game's custom radio and the free MediaBridge tool.

---

## Description

MediaBridge Radio turns your Pacific Drive car radio into a remote for your own music. Your Spotify, browser or other music app plays from the car with the game's own 3D sound and radio filter. Skip songs with the radio's channel buttons, and the radio screen shows the real song title and artist instead of a station name.

It uses the game's built-in custom radio and the free MediaBridge tool. The mod doesn't change any game files or the game's audio.

## Installation instructions

1. Install **UE4SS** (experimental build): put `dwmapi.dll` and the `ue4ss` folder in `Pacific Drive\PenDriverPro\Binaries\Win64\`.
2. Copy the `MediaBridgeRadio` folder from the download into `...\Win64\ue4ss\Mods\`.
3. Open `...\ue4ss\Mods\mods.txt` and add this line above `Keybinds : 1`:
   `MediaBridgeRadio : 1`
4. Copy `Custom Radio playlist\MediaBridge.m3u8` from the download into `%LOCALAPPDATA%\PenDriverPro\Custom\Radio\` (paste that path into the File Explorer address bar).
5. Install and start **MediaBridge**, and play some music.
6. In game: Settings → Audio → Radio Music Source → **Custom** or **Default and Custom**, then press **Rebuild database**.
7. Get in the car and tune to the MediaBridge station.

**Steam Deck / Linux:** same steps, but run the Linux version of MediaBridge, add the launch option `WINEDLLOVERRIDES="dwmapi=n,b" %command%` (so UE4SS loads under Proton), and copy the playlist into `~/.steam/steam/steamapps/compatdata/1458140/pfx/drive_c/users/steamuser/AppData/Local/PenDriverPro/Custom/Radio/`.

**Uninstall:** delete the `MediaBridgeRadio` folder and `MediaBridge.m3u8`.

## Main features

- **Your music on the car radio**: plays from the car with the game's 3D audio and radio filter.
- **Skip with the radio**: channel up/down plays the next or previous song in your music app. Works with keybinds and the on-screen radio buttons.
- On-foot channel keybinds only work while you're looking at the radio.
- **Now playing**: the radio screen shows "Song Title - Artist".
- **Plays and pauses with the radio**: your music plays while the car radio or garage jukebox is on, and pauses when both are off, on another station, or when you pause the game.
- Works with any music app that shows up in Windows' media controls (Spotify, browsers, etc.). Tested with Spotify.
- Only takes over the buttons while you're tuned to the MediaBridge station. The normal stations work as usual.

**Known limits**
- The music is about 3 seconds behind your music app (the game's stream buffer), so skips take a moment to be heard.
- Single-player only. Windows, Linux and Steam Deck (Proton).

## Requirements

- Pacific Drive v1.7.1 or newer (needs the custom radio feature)
- UE4SS experimental: https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest
- MediaBridge: https://github.com/AlexUnknown37/MediaBridge/releases
- A music app that works with Windows' media controls
- Recommended: set your music app's output to a virtual cable (e.g. VB-Cable) and pick it in MediaBridge's tray menu, so you don't hear the music twice

## Shout outs

- Ironwood Studios, for Pacific Drive and for building custom radio support into the game
- The RE-UE4SS team, for the mod loader that makes this possible
- Made with help from Claude (Anthropic's AI assistant)

---

## Requirements tab (Nexus "Requirements" section)

| Mod / tool | Link | Notes |
|---|---|---|
| UE4SS (experimental) | https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest | Mod loader. Don't use the zDEV- zip. |
| MediaBridge | https://github.com/AlexUnknown37/MediaBridge/releases | Must be running while you play. |

## Files tab

- **File name:** MediaBridge Radio
- **File version:** 1.1.4
- **File category:** Main file
- **Upload:** `MediaBridgeRadio-1.1.4.zip`
- **File description:** The mod folder, the ready-made radio playlist and a readme with install steps.

## Permissions and credits

- **Upload elsewhere:** not without permission
- **Modify / improve:** yes, with credit
- **Convert to other games:** yes, with credit
- **Use assets in other mods:** yes, with credit
- **Use in paid content:** no
- **Contains AI-generated content:** Yes, code written with help from Claude (if Nexus asks)

## Images

Nexus needs at least one image. Good ones:
1. In the car, radio showing "Song Title - Artist" (the main image)
2. Your music app next to the game showing the same song
3. Settings → Audio with Radio Music Source set to Custom

A 20–30 second video of a skip with the name changing would help most.

## Changelog

**1.1.4**: Your music now plays and pauses with the radio. It plays while the car radio or the garage jukebox is on and tuned to MediaBridge, and pauses when both are off, when you tune to another station, or when you pause the game. Turning off one while the other is still on keeps the music going. Tested on Windows and Steam Deck (Proton 11.0-2 and Experimental).

**1.1.3**: Pausing no longer closes and reopens the radio stream.

**1.1.2**: Pausing the game pauses your music; unpausing plays it again.

**1.1.1**: The radio now updates the song name when the song changes in your music app (not only when you skip with the radio). Fixed UE4SS hanging on Ctrl+R mod reload.

**1.1.0**: Steam Deck / Linux support (with the Linux version of MediaBridge).

**1.0.0**: First release.
