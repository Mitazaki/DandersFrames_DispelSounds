-- ============================================================================
-- DandersFrames_DispelSounds - Core
-- Plays a sound when DandersFrames shows a dispel overlay
-- ============================================================================

local addonName, DSA = ...
local ADDON_DISPLAY_NAME = "DandersFrames_DispelSounds"
local ADDON_VERSION = "1.0.0-beta1"

local DEFAULTS = {
    enabled = true,
    enableParty = true,
    enableRaid = true,
    soundFile = nil,
    soundChannel = "Master",
    cooldownPerUnit = 3,
    globalCooldown = 0.5,
    repeatSound = false,
    repeatInterval = 5,
    debug = false,
}

DSA.DEFAULTS = DEFAULTS

local db
local overlayState = {}
local unitCooldowns = {}
local lastGlobalSound = 0
local repeatTimers = {}
local hookedOverlays = setmetatable({}, { __mode = "k" })
local LSM

local PREFIX = "|cff00ccffDSA|r"

local function DebugPrint(...)
    if db and db.debug then
        print(PREFIX, ...)
    end
end

local function GetLSM()
    if LSM then return LSM end
    LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    return LSM
end

local function ResolveSoundFile(settingKey)
    local soundKey = db[settingKey]

    if not soundKey or soundKey == "" then
        DebugPrint("|cffffff88" .. settingKey .. ":|r nil/empty, using default built-in sound")
        return "soundkit", SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 1
    end

    if soundKey == "None" then
        DebugPrint("|cff888888" .. settingKey .. ":|r set to 'None', no sound will play")
        return nil, nil
    end

    local lsm = GetLSM()
    if lsm then
        local path = lsm:Fetch("sound", soundKey)
        if path and path ~= "" and path ~= soundKey then
            DebugPrint("|cff88ff88" .. settingKey .. ":|r LSM '" .. soundKey .. "' -> " .. tostring(path))
            return "file", path
        end
        DebugPrint("|cffff8888" .. settingKey .. ":|r LSM returned '" .. tostring(path) .. "' for key '" .. soundKey .. "' (not a valid sound)")
    else
        DebugPrint("|cffff8888" .. settingKey .. ":|r LibSharedMedia not available")
    end

    DebugPrint("|cffffff88" .. settingKey .. ":|r falling back to default built-in sound")
    return "soundkit", SOUNDKIT and (SOUNDKIT.RAID_WARNING or SOUNDKIT.READY_CHECK or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON) or 1
end

local function DoPlaySound(soundType, soundValue, channel)
    if not soundType or not soundValue then
        DebugPrint("|cff888888DoPlaySound:|r no sound to play")
        return false
    end

    local willPlay, handle
    if soundType == "soundkit" then
        DebugPrint("|cff88ff88DoPlaySound:|r PlaySound(" .. tostring(soundValue) .. ", '" .. tostring(channel) .. "', true)")
        willPlay, handle = PlaySound(soundValue, channel, true)
    else
        DebugPrint("|cff88ff88DoPlaySound:|r PlaySoundFile('" .. tostring(soundValue) .. "', '" .. tostring(channel) .. "')")
        willPlay, handle = PlaySoundFile(soundValue, channel)
    end

    if not willPlay then
        DebugPrint("|cffff8888DoPlaySound:|r returned false (willPlay=" .. tostring(willPlay) .. ", handle=" .. tostring(handle) .. "), retrying without channel...")
        if soundType == "soundkit" then
            willPlay, handle = PlaySound(soundValue, nil, true)
        else
            willPlay, handle = PlaySoundFile(soundValue)
        end

        if not willPlay and soundType == "soundkit" and SOUNDKIT then
            local fallbackKit = SOUNDKIT.READY_CHECK or SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON
            if fallbackKit and fallbackKit ~= soundValue then
                DebugPrint("|cffff8888DoPlaySound:|r retrying with fallback soundkit " .. tostring(fallbackKit))
                willPlay, handle = PlaySound(fallbackKit, channel, true)
                if not willPlay then
                    willPlay, handle = PlaySound(fallbackKit, nil, true)
                end
            end
        end

        if not willPlay then
            DebugPrint("|cffff4444DoPlaySound:|r STILL FAILED. Sound value: " .. tostring(soundValue) .. " type: " .. tostring(soundType))
        else
            DebugPrint("|cff88ff88DoPlaySound:|r fallback playback succeeded")
        end
    end

    return willPlay and true or false
end

local function PlayDispelSound(force)
    local now = GetTime()

    if not force and now - lastGlobalSound < db.globalCooldown then
        DebugPrint("|cffff8888PlayDispelSound:|r blocked by global cooldown (" .. string.format("%.1f", db.globalCooldown - (now - lastGlobalSound)) .. "s left)")
        return false
    end

    local soundType, soundValue = ResolveSoundFile("soundFile")
    local ok = DoPlaySound(soundType, soundValue, db.soundChannel or "Master")
    lastGlobalSound = now
    return ok
end

local function PlayForUnit(unit)
    if not db.enabled then
        DebugPrint("|cffff8888PlayForUnit(" .. tostring(unit) .. "):|r addon disabled")
        return
    end

    local now = GetTime()
    if unitCooldowns[unit] and (now - unitCooldowns[unit]) < db.cooldownPerUnit then
        DebugPrint("|cffff8888PlayForUnit(" .. tostring(unit) .. "):|r per-unit cooldown (" .. string.format("%.1f", db.cooldownPerUnit - (now - unitCooldowns[unit])) .. "s left)")
        return
    end

    DebugPrint("|cff88ff88PlayForUnit(" .. tostring(unit) .. "):|r attempting sound...")
    if PlayDispelSound() then
        unitCooldowns[unit] = now
    end
end

local function StopRepeat(unit)
    if repeatTimers[unit] then
        repeatTimers[unit]:Cancel()
        repeatTimers[unit] = nil
    end
end

local function StopAllRepeats()
    for unit, timer in pairs(repeatTimers) do
        timer:Cancel()
    end
    wipe(repeatTimers)
end

local function StartRepeat(unit)
    if not db.repeatSound then return end
    StopRepeat(unit)

    repeatTimers[unit] = C_Timer.NewTicker(db.repeatInterval, function()
        if not db.enabled or not db.repeatSound then
            StopRepeat(unit)
            return
        end

        local frame = DandersFrames_GetFrameForUnit and DandersFrames_GetFrameForUnit(unit)
        if not frame or not frame.dfDispelOverlay or not frame.dfDispelOverlay:IsShown() then
            StopRepeat(unit)
            return
        end

        PlayForUnit(unit)
    end)
end

local function HandleOverlayShown(frame)
    if not frame or not frame.unit then return end

    local unit = frame.unit
    if frame.isRaidFrame then
        if not db.enableRaid then return end
    else
        if not db.enableParty then return end
    end

    if overlayState[unit] then
        return
    end

    DebugPrint("|cff00ff00ALERT|r " .. unit .. ": DandersFrames overlay shown")
    overlayState[unit] = true
    PlayForUnit(unit)
    StartRepeat(unit)
end

local function HandleOverlayHidden(frame)
    if not frame or not frame.unit then return end

    local unit = frame.unit
    if not overlayState[unit] then
        return
    end

    DebugPrint("|cff888888CLEAR|r " .. unit .. ": DandersFrames overlay hidden")
    overlayState[unit] = false
    StopRepeat(unit)
end

local function AttachOverlayHooks(frame)
    if not frame or not frame.dfDispelOverlay then return end

    local overlay = frame.dfDispelOverlay
    if hookedOverlays[overlay] then return end

    hookedOverlays[overlay] = true
    overlay.dsaUnitFrame = frame

    overlay:HookScript("OnShow", function(self)
        HandleOverlayShown(self.dsaUnitFrame)
    end)

    overlay:HookScript("OnHide", function(self)
        HandleOverlayHidden(self.dsaUnitFrame)
    end)

    DebugPrint("|cff88ff88Hooked overlay for|r " .. tostring(frame.unit))
end

local function CheckFrame(frame)
    if not frame or not frame.unit then return end

    if frame.isRaidFrame then
        if not db.enableRaid then return end
    else
        if not db.enableParty then return end
    end

    AttachOverlayHooks(frame)

    local hasOverlay = frame.dfDispelOverlay and true or false
    local overlayShown = hasOverlay and frame.dfDispelOverlay:IsShown() or false

    if db and db.debug then
        DebugPrint("|cffffff00" .. frame.unit .. "|r overlay=" .. tostring(hasOverlay) .. " shown=" .. tostring(overlayShown) .. " tracked=" .. tostring(overlayState[frame.unit] or false))
    end

    if overlayShown then
        HandleOverlayShown(frame)
    else
        HandleOverlayHidden(frame)
    end
end

local function ScanAllFrames()
    if not DandersFrames_IterateFrames then return end
    DandersFrames_IterateFrames(function(frame)
        CheckFrame(frame)
    end)
end

local eventFrame = CreateFrame("Frame")
local pendingUnits = {}
local batchScheduled = false

local function ProcessPendingUnits()
    batchScheduled = false
    if not db or not db.enabled then
        wipe(pendingUnits)
        return
    end
    if not DandersFrames_IsReady or not DandersFrames_IsReady() then
        wipe(pendingUnits)
        return
    end

    for unit in pairs(pendingUnits) do
        local frame = DandersFrames_GetFrameForUnit(unit)
        if frame then
            CheckFrame(frame)
        end
    end
    wipe(pendingUnits)
end

local function ScheduleBatch()
    if not batchScheduled then
        batchScheduled = true
        C_Timer.After(0, ProcessPendingUnits)
    end
end

local function IsRelevantUnit(unit)
    if not unit then return false end
    if unit:match("^party%d") then return true end
    if unit:match("^raid%d") then return true end
    if unit == "player" then return true end
    return false
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            if not DispelSoundAlertDB then
                DispelSoundAlertDB = {}
            end

            for k, v in pairs(DEFAULTS) do
                if DispelSoundAlertDB[k] == nil then
                    DispelSoundAlertDB[k] = v
                end
            end

            if DispelSoundAlertDB.soundName and not DispelSoundAlertDB.soundFile then
                DispelSoundAlertDB.soundFile = DispelSoundAlertDB.soundName
                DispelSoundAlertDB.soundName = nil
            end

            DispelSoundAlertDB.onlyPlayerDispellable = nil
            DispelSoundAlertDB.racialEnabled = nil
            DispelSoundAlertDB.racialSoundFile = nil
            DispelSoundAlertDB.racialSoundName = nil
            DispelSoundAlertDB.racialSoundChannel = nil
            DispelSoundAlertDB.racialCooldown = nil
            DispelSoundAlertDB.racialOnlyOffCooldown = nil

            db = DispelSoundAlertDB
            DSA.db = db

            self:RegisterEvent("UNIT_AURA")
            self:RegisterEvent("GROUP_ROSTER_UPDATE")
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
            self:RegisterEvent("PLAYER_REGEN_ENABLED")
            self:RegisterEvent("PLAYER_REGEN_DISABLED")

            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. "|r |cff888888" .. ADDON_VERSION .. "|r loaded. Use |cffffff00/dsa|r to open options.")
        C_Timer.After(2, ScanAllFrames)

    elseif event == "UNIT_AURA" then
        local unit = ...
        if IsRelevantUnit(unit) then
            DebugPrint("|cffffff00UNIT_AURA|r " .. tostring(unit) .. " received; syncing DandersFrames overlay state")
            pendingUnits[unit] = true
            ScheduleBatch()
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        wipe(overlayState)
        wipe(unitCooldowns)
        StopAllRepeats()
        C_Timer.After(0.5, ScanAllFrames)

    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(overlayState)
        wipe(unitCooldowns)
        StopAllRepeats()
        C_Timer.After(1, ScanAllFrames)
    end
end)

SLASH_DISPELSOUNDALERT1 = "/dsa"
SLASH_DISPELSOUNDALERT2 = "/dispelsound"
SlashCmdList["DISPELSOUNDALERT"] = function(msg)
    msg = strtrim(msg):lower()
    if msg == "test" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Playing test sound...")
        PlayDispelSound(true)
    elseif msg == "debug" then
        db.debug = not db.debug
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Debug " .. (db.debug and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
        if db.debug then
            print("  Debug will log: overlay state, sound playback, cooldown blocks")
            print("  Use |cffffff00/dsa debug|r again to turn off")
            print("  --- Quick Diagnostic ---")
            print("  Enabled: " .. tostring(db.enabled))
            print("  DF ready: " .. tostring(DandersFrames_IsReady and DandersFrames_IsReady() or false))
            local lsm = LibStub and LibStub("LibSharedMedia-3.0", true)
            print("  LSM loaded: " .. tostring(lsm ~= nil))
            if lsm then
                local soundList = lsm:List("sound")
                print("  LSM sounds registered: " .. (soundList and #soundList or 0))
            end
            print("  SOUNDKIT.RAID_WARNING = " .. tostring(SOUNDKIT and SOUNDKIT.RAID_WARNING or "N/A"))
            print("  soundFile setting: " .. tostring(db.soundFile or "(nil = default)"))
            local sType, sVal = ResolveSoundFile("soundFile")
            print("  Dispel resolves to: type=" .. tostring(sType) .. " value=" .. tostring(sVal))
            local frameCount = 0
            if DandersFrames_IterateFrames then
                DandersFrames_IterateFrames(function(frame)
                    if frame and frame.unit then
                        frameCount = frameCount + 1
                        local hasOv = frame.dfDispelOverlay and true or false
                        local ovShow = hasOv and frame.dfDispelOverlay:IsShown() or false
                        print("    " .. frame.unit .. ": overlay=" .. tostring(hasOv) .. " shown=" .. tostring(ovShow) .. " tracked=" .. tostring(overlayState[frame.unit] or false))
                    end
                end)
            end
            print("  DF frames found: " .. frameCount)
        end
    elseif msg == "status" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Status:")
        print("  Enabled: " .. (db.enabled and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Party: " .. (db.enableParty and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Raid: " .. (db.enableRaid and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Sound: " .. tostring(db.soundFile or "(default)"))
        print("  Channel: " .. tostring(db.soundChannel))
    elseif msg == "reset" then
        wipe(overlayState)
        wipe(unitCooldowns)
        StopAllRepeats()
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r State reset.")
    else
        if DSA.ToggleOptions then
            DSA:ToggleOptions()
        else
            print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Commands:")
            print("  /dsa - Open options")
            print("  /dsa test - Play test sound")
            print("  /dsa debug - Toggle debug output")
            print("  /dsa status - Show current status")
            print("  /dsa reset - Reset tracking state")
        end
    end
end

DSA.PlayDispelSound = PlayDispelSound
DSA.ScanAllFrames = ScanAllFrames
DSA.ResolveSoundFile = ResolveSoundFile
DSA.GetLSM = GetLSM
DSA.StopAllRepeats = StopAllRepeats
