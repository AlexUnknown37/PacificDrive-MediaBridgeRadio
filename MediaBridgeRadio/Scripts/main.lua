-- MediaBridgeRadio for Pacific Drive (UE4SS Lua)
-- * Radio channel up/down -> MediaBridge next/previous (real music app)
-- * Shows the real song title + artist instead of "MediaBridge"
-- Talks to MediaBridge without sockets:
--   Windows:            commands -> \\.\pipe\MediaBridge          song info <- %LOCALAPPDATA%\MediaBridge\nowplaying.txt
--   Linux / Steam Deck: commands -> Z:\tmp\MediaBridge\commands.txt  song info <- Z:\tmp\MediaBridge\nowplaying.txt
--   (the game runs under Proton, MediaBridge runs natively; Z: is the Linux root)

local TAG = "[MediaBridgeRadio] "
local PIPE = [[\\.\pipe\MediaBridge]]
local NOWPLAYING = (os.getenv("LOCALAPPDATA") or "") .. "/MediaBridge/nowplaying.txt"
local LINUX_DIR = "Z:/tmp/MediaBridge"
local LINUX_NOWPLAYING = LINUX_DIR .. "/nowplaying.txt"
local DEBUG = false

local function log(s) print(TAG .. s .. "\n") end
local function dbg(s) if DEBUG then log(s) end end

-- ---------- clock ----------
-- os.clock() is CPU time, not real time (under Proton it runs much faster than the wall clock),
-- so keep our own real-time clock. The main loop at the bottom advances it every 250 ms.
-- (Only one LoopAsync: a second one made UE4SS hang when reloading mods with Ctrl+R.)
local clock = 0
local function seconds() return clock end

-- ---------- commands ----------
-- One button press fires several hooks, sometimes in two bursts up to ~0.7 s apart; send only once.
local DEBOUNCE = 0.9
local lastSend = -10
local function send(cmd, why, force)
  local now = seconds()
  if not force and now - lastSend < DEBOUNCE then dbg("ignored duplicate " .. cmd .. " (" .. why .. ")"); return end
  lastSend = now
  local f = io.open(PIPE, "w") or io.open(LINUX_DIR .. "/commands.txt", "a")
  if not f then log("MediaBridge is not running"); return end
  f:write(cmd .. "\n"); f:close()
  dbg("sent " .. cmd .. " (" .. why .. ")")
end

-- Get the active game world so we can follow the pause menu state independently
-- of the game's paused world tick.
local pauseQuery = StaticFindObject("/Script/Engine.Default__GameplayStatics")
local function gameIsPaused()
  local controllers = FindAllOf("PlayerController") or FindAllOf("Controller") or {}
  for _, controller in ipairs(controllers) do
    local okWorld, world = pcall(function() return controller:GetWorld() end)
    if okWorld and world and world:IsValid() then
      if pauseQuery and pauseQuery:IsValid() then
        local ok, paused = pcall(function() return pauseQuery:IsGamePaused(world) end)
        if ok and type(paused) == "boolean" then return paused end
      end
      local ok, paused = pcall(function() return world:IsPaused() end)
      if ok and type(paused) == "boolean" then return paused end
      ok, paused = pcall(function() return world.bIsPaused end)
      if ok and type(paused) == "boolean" then return paused end
    end
  end
end

local lastGamePaused
local closedBridgePlayers = {}
local pendingBridgeOpen = {}
local pendingBridgePlay = {}

-- Closing the radio's live MediaPlayer discards audio already buffered by the game.
local function closeBridgeStream()
  closedBridgePlayers = {}
  for _, player in ipairs(FindAllOf("MediaPlayer") or {}) do
    local ok, url = pcall(function() return player:GetUrl():ToString() end)
    if ok and url and url:find("MediaBridge", 1, true) then
      local closed = pcall(function() player:Close() end)
      if closed then
        table.insert(closedBridgePlayers, { player = player, url = url })
      end
    end
  end
  if #closedBridgePlayers > 0 then
    log("closed " .. #closedBridgePlayers .. " MediaBridge stream player(s) to clear buffered audio")
  else
    log("could not find an open MediaBridge stream player to clear")
  end
end

-- Reconnect slightly after unpausing so the game's asynchronous Close has time to finish.
local function reopenBridgeStream()
  pendingBridgeOpen = {}
  for _, entry in ipairs(closedBridgePlayers) do
    table.insert(pendingBridgeOpen, {
      player = entry.player,
      url = entry.url,
      openAt = seconds() + 0.5,
      deadline = seconds() + 8,
    })
  end
  closedBridgePlayers = {}
end

local function serviceBridgeReconnect()
  local now = seconds()
  for i = #pendingBridgeOpen, 1, -1 do
    local entry = pendingBridgeOpen[i]
    if now >= entry.openAt then
      local ok, opened = pcall(function() return entry.player:OpenUrl(entry.url) end)
      if ok and opened ~= false then
        table.insert(pendingBridgePlay, { player = entry.player, deadline = entry.deadline })
        table.remove(pendingBridgeOpen, i)
      elseif now >= entry.deadline then
        log("could not reopen the MediaBridge stream")
        table.remove(pendingBridgeOpen, i)
      else
        entry.openAt = now + 0.5
      end
    end
  end

  for i = #pendingBridgePlay, 1, -1 do
    local entry = pendingBridgePlay[i]
    local ok, playing = pcall(function() return entry.player:IsPlaying() end)
    if ok and playing == true then
      table.remove(pendingBridgePlay, i)
    elseif now >= entry.deadline then
      log("MediaBridge stream reopened but did not start playing")
      table.remove(pendingBridgePlay, i)
    else
      local playOk, started = pcall(function() return entry.player:Play() end)
      if playOk and started == true then table.remove(pendingBridgePlay, i) end
    end
  end
end

local function syncMediaBridgePause()
  local paused = gameIsPaused()
  if paused == nil then return end
  if lastGamePaused == nil then
    lastGamePaused = paused
    if paused then
      send("pause", "game already paused", true)
      closeBridgeStream()
    end
    return
  end
  if paused == lastGamePaused then return end
  lastGamePaused = paused
  if paused then
    send("pause", "game paused", true)
    closeBridgeStream()
  else
    send("play", "game resumed", true)
    reopenBridgeStream()
  end
end

-- Is the radio on our station? (only take over the buttons then)
local cachedTrack
local function ourTrack()
  if cachedTrack and cachedTrack:IsValid() then return cachedTrack end
  cachedTrack = nil
  local tracks = FindAllOf("MusicTrack")
  if not tracks then return nil end
  for _, t in ipairs(tracks) do
    if t:IsValid() then
      local ok, url = pcall(function() return t.ExternalUrl:ToString() end)
      if ok and url and url:find("MediaBridge", 1, true) then cachedTrack = t; return t end
    end
  end
end

-- The on-foot controller receives the radio channel actions even when the player is
-- looking elsewhere. Its HighlightIsRadio function is the game's own focus check for
-- the radio interaction widget, so only take over those keybinds while it is true.
local function isLookingAtRadio()
  for _, controller in ipairs(FindAllOf("BP_PlayerController_MainCharacter_C") or {}) do
    local ok, focused = pcall(function() return controller:HighlightIsRadio() end)
    if ok and focused == true then return true end
  end
  return false
end

-- ---------- hooks ----------
local hooks = {
  -- keybinds while driving
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_11", "next" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_12", "next" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_9", "previous" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_10", "previous" },
  -- keybinds on foot
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_2", "next", false, true },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_3", "next", false, true },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_0", "previous", false, true },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_1", "previous", false, true },
  -- clicking the radio's on-screen buttons
  { "/Game/UI/Inventory/ItemWidgets/HighlightWidget/UMG_HighlightRadioWidget.UMG_HighlightRadioWidget_C", "OnChannelUp_Click", "next" },
  { "/Game/UI/Inventory/ItemWidgets/HighlightWidget/UMG_HighlightRadioWidget.UMG_HighlightRadioWidget_C", "OnChannelDown_Click", "previous" },
  -- last resort: the radio component skipping (direction unknown -> next). Debounce drops it if a specific one fired.
  { "/Game/Gameplay/Inventory/GenericItemProperties/Components/BP_RadioComponent.BP_RadioComponent_C", "OnSkipTrack", "next", true },
}

local registered = {}
local function tryRegister()
  local missing = 0
  for i, h in ipairs(hooks) do
    if not registered[i] then
      local fn = StaticFindObject(h[1] .. ":" .. h[2])
      if fn and fn:IsValid() then
        local ok = pcall(RegisterHook, h[1] .. ":" .. h[2], function()
          if h[5] and not isLookingAtRadio() then return end
          if not ourTrack() then return end
          if h[4] then
            -- fallback hook fires after the specific ones; only send if nothing was sent just now
            if seconds() - lastSend < DEBOUNCE then return end
          end
          send(h[3], h[2])
        end)
        registered[i] = ok
        if ok then dbg("hooked " .. h[2]) end
      end
      if not registered[i] then missing = missing + 1 end
    end
  end
  return missing
end

-- ---------- song info ----------
local current = { title = "", artist = "", seq = "" }
local function readNowPlaying()
  local f, err = io.open(NOWPLAYING, "r")
  if not f then f = io.open(LINUX_NOWPLAYING, "r") end
  if not f then
    current.fails = (current.fails or 0) + 1
    if current.fails % 20 == 1 then log("can't read song file (" .. current.fails .. "x): " .. tostring(err)) end
    return false
  end
  local data = f:read("*a"); f:close()
  if not current.readOnce then current.readOnce = true; log("song file read ok: " .. #data .. " bytes") end
  local t = {}
  for k, v in data:gmatch("([%w_]+)=([^\r\n]*)") do t[k] = v end
  if not t.seq or t.seq == current.seq then return false end
  current.seq = t.seq
  local title, artist = t.title or "", t.artist or ""
  if title == current.title and artist == current.artist then return false end
  current.title, current.artist = title, artist
  dbg("now playing: " .. title .. " - " .. artist)
  return true
end

local function displayText()
  if current.title == "" then return nil end
  if current.artist ~= "" then return current.title .. " - " .. current.artist end
  return current.title
end

local wroteTexts = {}

local function applyDisplay()
  local track = ourTrack()
  if not track then return end
  if current.title == "" then return end
  -- The game redraws the radio text from the track's Title, so put the full text there;
  -- otherwise the game and this mod take turns and the text flashes.
  local text = displayText()
  local okT, title = pcall(function() return track.Title:ToString() end)
  if okT and title ~= text then
    wroteTexts[title] = true -- only this mod changes our station's title, so the old one is ours too
    pcall(function() track.Title = FText(text) end)
    pcall(function() track.Artist = FText("") end)
  end
  -- The radio widget only re-reads the Title when the station (re)loads, so when the song changes by
  -- itself (or in the music app) update the screen too: if it shows the station name or a song text
  -- this mod wrote earlier. Other stations' text is left alone.
  wroteTexts[text] = true
  for _, w in ipairs(FindAllOf("UMG_HighlightRadioWidget_C") or {}) do
    if w:IsValid() then
      local tb = w.CurrentTrackText
      if tb and tb:IsValid() then
        local ok, shown = pcall(function() return tb:GetText():ToString() end)
        if ok and shown ~= text and (shown:find("^MediaBridge") or wroteTexts[shown]) then
          pcall(function() tb:SetText(FText(text)) end)
        end
      end
    end
  end
end

-- ---------- main loop ----------
local tick = 0
LoopAsync(250, function()
  tick = tick + 1
  clock = clock + 0.25
  ExecuteInGameThread(function()
    local ok, err = pcall(function()
      if tick % 8 == 1 then tryRegister() end
      syncMediaBridgePause()
      serviceBridgeReconnect()
      readNowPlaying()
      applyDisplay()
    end)
    if not ok and tick % 40 == 1 then log("error: " .. tostring(err)) end
  end)
  return false
end)

log("loaded")
