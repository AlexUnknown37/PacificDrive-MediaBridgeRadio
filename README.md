# MediaBridge Radio for Pacific Drive

Play your own music (Spotify, browser, any music app) on the Pacific Drive car radio, with the game's own 3D sound.

- **Skip with the radio:** channel up/down plays the next or previous song in your music app (keybinds and the on-screen radio buttons)
- **Now playing:** the radio screen shows "Song Title - Artist"
- Works on **Windows** and **Steam Deck / Linux** (Proton)
- Only takes over the buttons while you're tuned to the MediaBridge station

It's a small UE4SS Lua mod that uses the game's built-in custom radio and [MediaBridge](https://github.com/AlexUnknown37/MediaBridge). It doesn't change any game files.

## How it works

| Part | How |
|---|---|
| Music in the car | The game's custom radio plays MediaBridge's stream `http://127.0.0.1:48902/MediaBridge.wav` (playlist: `release/Custom Radio playlist/MediaBridge.m3u8`) |
| Skip buttons | UE4SS hooks on the radio's channel up/down (keybinds and on-screen buttons) send `next` / `previous` through MediaBridge's script bridge |
| Song name | The mod reads MediaBridge's `nowplaying.txt` and writes "Title - Artist" into the station's track title |

Script bridge paths:
- **Windows:** commands to the named pipe `\\.\pipe\MediaBridge`, song from `%LOCALAPPDATA%\MediaBridge\nowplaying.txt`
- **Linux / Steam Deck:** commands appended to `Z:\tmp\MediaBridge\commands.txt`, song from `Z:\tmp\MediaBridge\nowplaying.txt` (Proton's `Z:` is the Linux root)

Hooked functions:
- `BP_Controller_PlayerCar_C` / `BP_PlayerController_MainCharacter_C`: `InpActEvt_Radio_ChannelUp/Down_*`
- `UMG_HighlightRadioWidget_C`: `OnChannelUp_Click`, `OnChannelDown_Click`
- `BP_RadioComponent_C`: `OnSkipTrack` (fallback)

One press fires several of these, so the mod sends only one command per 0.9 s, timed by its own real-time clock. Don't use `os.clock()` for this: it's CPU time and is wrong under Proton.

## Install

Full player steps (Windows and Steam Deck) are in [release/README.txt](release/README.txt). Short version:

1. Install UE4SS (experimental) next to `PenDriverPro-Win64-Shipping.exe`. On Steam Deck, also set the launch option `WINEDLLOVERRIDES="dwmapi=n,b" %command%`.
2. Copy `MediaBridgeRadio` into `ue4ss/Mods/` and add `MediaBridgeRadio : 1` to `mods.txt`.
3. Copy `MediaBridge.m3u8` into the game's `PenDriverPro/Custom/Radio/` folder.
4. Run MediaBridge. In game, set Radio Music Source to Custom and press Rebuild database.

## Repo layout

```
MediaBridgeRadio/Scripts/main.lua   the mod
release/                            what goes in the download zip (readme, playlist)
MODPAGE.md                          Nexus mod page text
MODDING_PLAN.md                     research notes: engine, radio classes, route
```

## Credits

- Ironwood Studios, for Pacific Drive and its custom radio support
- The RE-UE4SS team
- Made with help from Claude (Anthropic's AI assistant)
