MediaBridge Radio for Pacific Drive  -  version 1.1.4
====================================================

Play your own music (Spotify, browser, etc.) on the car radio.
The radio's channel buttons skip songs, and the radio shows "Title - Artist".

NEEDS
-----
- Pacific Drive v1.7.1 or newer (custom radio feature)
- UE4SS (experimental build): https://github.com/UE4SS-RE/RE-UE4SS/releases/tag/experimental-latest
- MediaBridge (free, running in your system tray): https://github.com/AlexUnknown37/MediaBridge

INSTALL
-------
1. Install UE4SS: put dwmapi.dll and the ue4ss folder in
   Pacific Drive\PenDriverPro\Binaries\Win64\
2. Copy the MediaBridgeRadio folder into
   Pacific Drive\PenDriverPro\Binaries\Win64\ue4ss\Mods\
3. Open ue4ss\Mods\mods.txt and add this line above "Keybinds : 1":
   MediaBridgeRadio : 1
4. Copy "Custom Radio playlist\MediaBridge.m3u8" into
   %LOCALAPPDATA%\PenDriverPro\Custom\Radio\
   (paste that path into the File Explorer address bar; create the folders if they don't exist)
5. Start MediaBridge and play some music.
6. In game: Settings > Audio > Radio Music Source = "Custom" or "Default and Custom",
   then press "Rebuild database".
7. Get in the car and tune to the MediaBridge station.

STEAM DECK / LINUX
------------------
Same steps, with these differences:
- Run the Linux version of MediaBridge (in Desktop Mode).
- In Steam: Pacific Drive > Properties > Launch Options:
  WINEDLLOVERRIDES="dwmapi=n,b" %command%
  (needed for UE4SS to load under Proton)
- The game folder is ~/.steam/steam/steamapps/common/Pacific Drive/
- Step 4: copy MediaBridge.m3u8 into the game's Proton folder:
  ~/.steam/steam/steamapps/compatdata/1458140/pfx/drive_c/users/steamuser/AppData/Local/PenDriverPro/Custom/Radio/
The mod finds MediaBridge on its own (it checks /tmp/MediaBridge).

UNINSTALL
---------
Delete the MediaBridgeRadio folder and MediaBridge.m3u8.

NOTES
-----
- The music is about 3 seconds behind your music app. That's the game's stream buffer.
- The buttons only control your music while you're tuned to the MediaBridge station.
- On-foot channel keybinds only work while you're looking at the radio.
- Your music plays while the car radio or the garage jukebox is on and tuned to MediaBridge,
  and pauses when both are off, when you tune to another station, or when you pause the game.
- Tip: send your music app's sound to a virtual cable (e.g. VB-Cable) and pick it in
  MediaBridge's tray menu, so you only hear the music from the car.
