# Pacific Drive modding plan: MediaBridge radio mod

Goal: a Pacific Drive mod that connects the car radio to **MediaBridge** (`D:\The_Work_Space\MediaBridge`).
The radio's buttons should control your real music (Spotify etc.), the game should show what's playing,
and the music should play from the car with the game's own 3D audio. A volume slider is a nice extra.

## Game facts (checked 2026-10-10)
- **Install:** `D:\_Games\Steam\steamapps\common\Pacific Drive` (Steam app 1458140)
- **Shipping exe:** `PenDriverPro\Binaries\Win64\PenDriverPro-Win64-Shipping.exe` (project name `PenDriverPro`)
- **Engine:** Unreal Engine **4.27**, native C++, 64-bit, 6 regular `.pak` files (not IoStore)
- **Audio:** Wwise (Plugins/Wwise). The radio uses UE's **MediaPlayer (WmfMedia = Windows Media Foundation)**
  fed into Wwise through `WwiseMediaPlayer` / `UAkMediaPlayerComponent`. That's why custom stations get 3D car audio.
- **Anti-cheat:** none. Single-player.
- **Saves / config:** `%LOCALAPPDATA%\PenDriverPro\Saved` (config in `Saved\Config\Windows`)
- **Custom radio (built-in feature, v1.7.1+):** `%LOCALAPPDATA%\PenDriverPro\Custom\Radio\`
  - takes `.mp3 .wav .ogg` and `.m3u/.m3u8` playlists, and playlists can point to internet streams
  - turn it on in Settings → Audio → radio music source "Custom" or "Default and Custom"
  - the station name shown is the last part of the URL
- **Interesting strings in the exe:** `CustomRadio`, `StreamUrl`, `CurrentRadioTrack`, `OnRadioTrackBegin`,
  `OnRadioTrackEnded`, `HandleMediaPlayerFinished`, `.m3u8`

## The big shortcut: music already reaches the car radio
MediaBridge serves your music as an MP3 internet-radio stream at `http://127.0.0.1:48902/MediaBridge.mp3`.
`%LOCALAPPDATA%\PenDriverPro\Custom\Radio\MediaBridge.m3u8` already points to it.
Tested with Windows Media Foundation (the game's player): it opens in ~1 s and plays smoothly.
**Still to confirm in game:** that the station shows up, plays, and comes from the car.

The game handles the 3D audio itself, so **the mod doesn't touch audio**. The mod only needs to:
1. Hook the radio's controls (next/previous/power/volume) and send MediaBridge commands
   (`next`, `previous`, `play_pause`, `set_volume`) over `127.0.0.1:48900`.
2. Show the real song title/artist where the radio shows track info (MediaBridge `media` events).
3. Optional: cover art, a volume slider, auto-tune to the MediaBridge station.

Expect ~1–3 s of delay between a skip and hearing the new song (stream buffering). That's normal for internet radio.

## Route
- **UE4SS** (RE-UE4SS experimental): `UE4SS_v3.0.1-1164-g5e627997.zip` (8.3 MB, 2026-10-09) from
  https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest
  - **install:** put `dwmapi.dll` + the `ue4ss\` folder next to the shipping exe (`PenDriverPro\Binaries\Win64\`)
  - don't use the `zDEV-` zip
  - **uninstall:** delete `dwmapi.dll` and `ue4ss\`. Or launch with `--disable-ue4ss`.
- **Lua vs C++:** UE4SS Lua has no network sockets built in. Options:
  - **(a) recommended:** a small UE4SS **C++ mod** that does the TCP to MediaBridge and hooks the radio
  - (b) Lua for hooks, with a tiny helper DLL loaded via `require`
- **First steps in the next chat:**
  1. Install UE4SS and confirm it loads (`ue4ss\UE4SS.log`). Turn on the console/GUI in `UE4SS-settings.ini`.
  2. Use Live View / an object dump to find the radio classes. Search: `Radio`, `CustomRadio`, `StreamUrl`, `CurrentRadioTrack`.
  3. Hook `OnRadioTrackBegin` / radio button functions and log them, before building anything.

## Lab safety
- **Backup first:** `%LOCALAPPDATA%\PenDriverPro\Saved` (save games)
- **Steam "Verify integrity of game files"** restores the game folder (UE4SS files are extra files, not replacements)
- **To remove the station:** delete `MediaBridge.m3u8` from the Custom\Radio folder

## Unknowns
- Does the station play in game? Does the radio need to be "tuned" to it?
- Which class/functions the radio uses (find with UE4SS Live View)
- Whether the game shows stream metadata. If not, the mod sets the displayed text itself.
