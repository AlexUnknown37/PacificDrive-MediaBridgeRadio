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

Listen to your own music in the car! Whatever you're playing in Spotify, YouTube or any other music app comes out of the Pacific Drive car radio, with the game's 3D sound and radio effect.

- The radio's **channel buttons skip songs** (D-pad left/right, next / previous)
- The radio screen shows the **song name and artist**
- Your music **plays when the radio is on and pauses when it's off** (car radio and garage jukebox), and pauses when you pause the game
- The normal in-game stations still work as usual

Works on **Windows** and **Steam Deck / Linux**. It doesn't change any game files.

---

## What you need

- **Pacific Drive** (v1.7.1 or newer)
- **UE4SS**, the mod loader: https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest
- **MediaBridge**, a small free app that hands your music to the game: https://github.com/AlexUnknown37/MediaBridge/releases

## Install the mod

**1. Install UE4SS** (skip if you already have it)
Download the UE4SS zip (not the one starting with `zDEV-`). Unzip it into:
`Pacific Drive\PenDriverPro\Binaries\Win64\`
You should now have `dwmapi.dll` and a `ue4ss` folder next to `PenDriverPro-Win64-Shipping.exe`.

**2. Add this mod**
Copy the `MediaBridgeRadio` folder from this download into:
`...\Win64\ue4ss\Mods\`
Then open `ue4ss\Mods\mods.txt` in Notepad and add this line just above `Keybinds : 1`:
`MediaBridgeRadio : 1`

**3. Add the radio station**
Copy `MediaBridge.m3u8` (in the `Custom Radio playlist` folder of this download) into:
`%LOCALAPPDATA%\PenDriverPro\Custom\Radio\`
Tip: paste that path into the File Explorer address bar. If the `Custom` or `Radio` folder doesn't exist, create it.

**4. Turn on custom radio in the game**
Settings → Audio → **Radio Music Source** → **Custom** (or **Default and Custom**), then press **Rebuild database**. You only need to do this once.

**5. Play!**
Start MediaBridge (see below), play some music, then get in the car, turn on the radio and tune to the **MediaBridge** station.

**Steam Deck / Linux:** the same steps with three changes:
- In Steam: Pacific Drive → Properties → **Launch Options**: `WINEDLLOVERRIDES="dwmapi=n,b" %command%` (this lets UE4SS load)
- The game folder is `~/.steam/steam/steamapps/common/Pacific Drive/`
- Put `MediaBridge.m3u8` in `~/.steam/steam/steamapps/compatdata/1458140/pfx/drive_c/users/steamuser/AppData/Local/PenDriverPro/Custom/Radio/`

**Uninstall:** delete the `MediaBridgeRadio` folder and `MediaBridge.m3u8`.

---

## Set up MediaBridge and your music

### Windows

**1. Run MediaBridge**
Download `MediaBridge.exe` and double-click it. A green music note appears in the tray (bottom-right, maybe under the `^` arrow). Click it and turn on **Start with Windows** if you don't want to start it every time.

**2. Play your music** in Spotify, a web browser (YouTube, SoundCloud…) or any app that shows up in Windows' media controls. That's enough to hear it in the car.

**3. Recommended: so you only hear the music from the car**
Without this you'll hear the music twice: once from your speakers and once from the car radio.
- Install **VB-Cable** (free): https://vb-audio.com/Cable/
- Send your music app to **CABLE Input**:
  - **Spotify:** Settings → Playback → Output device → **CABLE Input**
  - **Web browser or any other app:** Windows Settings → System → Sound → **Volume mixer** (or *App volume and device preferences*) → set your browser's Output to **CABLE Input**. The browser must be playing something to show up in the list.
- In MediaBridge's tray menu, under **Listen to**, pick **CABLE Input** (it usually picks it by itself).

Now game sounds, Discord and everything else stay on your speakers, and your music only plays from the car.

### Steam Deck / Linux

No VB-Cable needed: MediaBridge makes its own virtual speaker.

1. In **Desktop Mode**, put the Linux `MediaBridge` program in a folder that stays, e.g. `~/Applications/MediaBridge/`.
2. Open Konsole in that folder and run:
   `chmod +x MediaBridge && ./MediaBridge --install`
   It now starts by itself every time, in Desktop Mode and Game Mode.
3. Open http://127.0.0.1:48902/ in a browser. Under **Send these apps here automatically**, tick the box and type your app's name, e.g. `spotify`, or `firefox` / `chrome` for a web browser (YouTube Music etc.). For more than one, separate them with commas: `spotify, firefox`.
4. Play your music, then switch to Game Mode and play.

---

## Good to know

- The music is about **3 seconds behind** your music app (that's the game's radio buffer), so a skip takes a moment to be heard.
- The channel buttons only skip songs while you're tuned to the MediaBridge station, and the keybinds only while you're looking at the radio, just like the normal stations.
- Single-player only.

**Not working?**
- No MediaBridge station: check step 3 and press **Rebuild database** again.
- Station is silent: make sure MediaBridge is running and your music is playing.
- Song name says "MediaBridge": check the `MediaBridgeRadio : 1` line in `mods.txt` (step 2).

## Shout outs

- Ironwood Studios, for Pacific Drive and for building custom radio support into the game
- The RE-UE4SS team, for the mod loader that makes this possible
- Made with help from Claude (Anthropic's AI assistant)

## Support

If you enjoy this mod, you can support me here:
- Ko-fi: https://ko-fi.com/alexjustalex
- Patreon: https://patreon.com/AlexanderVazquez
- GitHub: https://github.com/AlexUnknown37

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

**1.1.4**: Your music now plays and pauses with the radio. It plays while the car radio or the garage jukebox is on and tuned to MediaBridge, and pauses when both are off, when you tune to another station, or when you pause the game. Turning off one while the other is still on keeps the music going. In the car, the channel buttons now only skip songs while you're looking at the radio (like the normal stations). Fixed a crash while the game starts or loads a save (seen on Proton stable and Windows). Tested on Windows and Steam Deck (Proton stable, 10.0, 11.0-2, Experimental and GE-Proton9-26).

**1.1.3**: Pausing no longer closes and reopens the radio stream.

**1.1.2**: Pausing the game pauses your music; unpausing plays it again.

**1.1.1**: The radio now updates the song name when the song changes in your music app (not only when you skip with the radio). Fixed UE4SS hanging on Ctrl+R mod reload.

**1.1.0**: Steam Deck / Linux support (with the Linux version of MediaBridge).

**1.0.0**: First release.
