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
  if not force and now - lastSend < DEBOUNCE then dbg("ignored duplicate " .. cmd .. " (" .. why .. ")"); return false end
  lastSend = now
  local f = io.open(PIPE, "w") or io.open(LINUX_DIR .. "/commands.txt", "a")
  if not f then log("MediaBridge is not running"); return false end
  f:write(cmd .. "\n"); f:close()
  dbg("sent " .. cmd .. " (" .. why .. ")")
  return true
end

-- Get the active game world so we can follow the pause menu state independently
-- of the game's paused world tick.
-- Class templates (Default__ objects) aren't in a world; calling functions on them crashed UE4SS under Proton.
local function isLive(o)
  return o and o:IsValid() and not o:GetFullName():find("Default__", 1, true)
end

local pauseQuery = StaticFindObject("/Script/Engine.Default__GameplayStatics")
local function gameIsPaused()
  local controllers = FindAllOf("PlayerController") or FindAllOf("Controller") or {}
  for _, controller in ipairs(controllers) do
    local okWorld, world = false, nil
    if isLive(controller) then okWorld, world = pcall(function() return controller:GetWorld() end) end
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

-- One music manager drives both the car radio (radioOn) and the garage jukebox (GarageStereoOn).
-- Our music should play only when the game isn't paused, at least one of them is on, and the
-- station is MediaBridge. Returns nil when we can't tell yet.
local mmAddr, mmSince = nil, 0
local function musicShouldPlay()
  -- Wait for the real music manager: before it exists the game is still loading.
  local mm
  for _, m in ipairs(FindAllOf("BP_MusicManager_C") or {}) do
    if isLive(m) then mm = m; break end
  end
  if not mm then return nil end
  -- A new manager means a world is loading; let it settle before calling into it (crashed on save load).
  local addr = mm:GetAddress()
  if addr ~= mmAddr then mmAddr, mmSince = addr, clock end
  if clock - mmSince < 3 then return nil end
  local paused = gameIsPaused()
  if paused == nil then return nil end
  if paused then return false end
  local okOn, on = pcall(function() return mm.radioOn == true or mm.GarageStereoOn == true end)
  if not okOn then return nil end
  if not on then return false end
  local mine = ourTrack()
  if not mine then return false end
  local okT, cur = pcall(function() return mm:CurrentRadioTrack() end)
  if not okT or not cur or not cur:IsValid() then return false end
  return cur:GetAddress() == mine:GetAddress()
end

local lastShouldPlay

local function syncMediaBridgePlayback()
  local should = musicShouldPlay()
  if should == nil then return end
  -- Only act on changes; at startup just remember the state so we don't pause music the player started.
  if lastShouldPlay == nil or should == lastShouldPlay then lastShouldPlay = should; return end
  lastShouldPlay = should
  send(should and "play" or "pause", should and "radio on / game resumed" or "radio off / game paused", true)
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
-- No car keybind hooks: in the car the game checks IsLookingAtRadio itself and then calls
-- OnChannelUp/Down_Click, so hooking the keybinds skipped songs while looking at the road.
local hooks = {
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
      syncMediaBridgePlayback()
      readNowPlaying()
      applyDisplay()
    end)
    if not ok and tick % 40 == 1 then log("error: " .. tostring(err)) end
  end)
  return false
end)

log("loaded")
