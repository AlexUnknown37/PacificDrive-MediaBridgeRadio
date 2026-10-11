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
-- so keep our own real-time clock in 50 ms steps.
local ticks = 0
LoopAsync(50, function() ticks = ticks + 1; return false end)
local function seconds() return ticks * 0.05 end

-- ---------- commands ----------
-- One button press fires several hooks, sometimes in two bursts up to ~0.7 s apart; send only once.
local DEBOUNCE = 0.9
local lastSend = -10
local function send(cmd, why)
  local now = seconds()
  if now - lastSend < DEBOUNCE then dbg("ignored duplicate " .. cmd .. " (" .. why .. ")"); return end
  lastSend = now
  local f = io.open(PIPE, "w") or io.open(LINUX_DIR .. "/commands.txt", "a")
  if not f then log("MediaBridge is not running"); return end
  f:write(cmd .. "\n"); f:close()
  dbg("sent " .. cmd .. " (" .. why .. ")")
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

-- ---------- hooks ----------
local hooks = {
  -- keybinds while driving
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_11", "next" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_12", "next" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_9", "previous" },
  { "/Game/Systems/Controller/BP_Controller_PlayerCar.BP_Controller_PlayerCar_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_10", "previous" },
  -- keybinds on foot
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_2", "next" },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelUp_K2Node_InputActionEvent_3", "next" },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_0", "previous" },
  { "/Game/Systems/Controller/BP_PlayerController_MainCharacter.BP_PlayerController_MainCharacter_C", "InpActEvt_Radio_ChannelDown_K2Node_InputActionEvent_1", "previous" },
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

local function applyDisplay()
  local track = ourTrack()
  if not track then return end
  if current.title == "" then return end
  -- The game redraws the radio text from the track's Title, so put the full text there;
  -- otherwise the game and this mod take turns and the text flashes.
  local text = displayText()
  local okT, title = pcall(function() return track.Title:ToString() end)
  if okT and title ~= text then
    pcall(function() track.Title = FText(text) end)
    pcall(function() track.Artist = FText("") end)
  end
  -- the radio widget, if it's on screen and still showing the old station name
  for _, w in ipairs(FindAllOf("UMG_HighlightRadioWidget_C") or {}) do
    if w:IsValid() then
      local tb = w.CurrentTrackText
      if tb and tb:IsValid() then
        local ok, shown = pcall(function() return tb:GetText():ToString() end)
        if ok and shown ~= text and shown:find("^MediaBridge") then
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
  ExecuteInGameThread(function()
    local ok, err = pcall(function()
      if tick % 8 == 1 then tryRegister() end
      readNowPlaying()
      applyDisplay()
    end)
    if not ok and tick % 40 == 1 then log("error: " .. tostring(err)) end
  end)
  return false
end)

log("loaded")
