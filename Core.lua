-- ============================================================================
-- NT_DispelSounds - Core (Standalone)
-- Plays a sound when a dispellable debuff is detected on party or raid members
-- ============================================================================

local addonName, DSA = ...
local ADDON_DISPLAY_NAME = "NT_DispelSounds"
local ADDON_VERSION = "0.9.0b"

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local DEFAULTS = {
    enabled = true,
    enableRoleHealer = true,
    enableRoleDPS = true,
    enableRoleTank = true,
    filterMode = "auto",
    soundFile = nil,
    soundChannel = "Master",
    cooldownPerUnit = 3,
    globalCooldown = 0.5,
    repeatSound = false,
    repeatInterval = 5,
    debug = false,
}

DSA.DEFAULTS = DEFAULTS
DSA.ADDON_DISPLAY_NAME = ADDON_DISPLAY_NAME
DSA.ADDON_VERSION = ADDON_VERSION

-- ============================================================================
-- STATE
-- ============================================================================

local db
local dispelState = {}
local unitCooldowns = {}
local lastGlobalSound = 0
local repeatTimers = {}
local LSM

local PREFIX = "|cff00ccffDSA|r"

-- ============================================================================
-- DEBUG
-- ============================================================================

local function DebugPrint(...)
    if db and db.debug then
        print(PREFIX, ...)
    end
end

-- ============================================================================
-- LIBSHAREDMEDIA
-- ============================================================================

local function GetLSM()
    if LSM then return LSM end
    LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    return LSM
end

-- ============================================================================
-- AURA SCANNING
-- Returns: true or false
-- ============================================================================

local FILTER_PLAYER_DISPELLABLE = "HARMFUL|RAID_PLAYER_DISPELLABLE"

local function ScanUnitForDispellableDebuffs(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return false end
    if not UnitExists(unit) then return false end

    if db.filterMode == "auto" then
        -- "Dispellable by Me": use RAID_PLAYER_DISPELLABLE filter (same as DandersFrames)
        local IsFiltered = C_UnitAuras.IsAuraFilteredOutByInstanceID

        for i = 1, 40 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if not auraData then break end

            local id = auraData.auraInstanceID
            if id then
                if IsFiltered then
                    if not IsFiltered(unit, id, FILTER_PLAYER_DISPELLABLE) then
                        DebugPrint("|cff88ff88Scan " .. unit .. ":|r player-dispellable aura (id=" .. id .. ")")
                        return true
                    end
                else
                    -- Fallback: if API unavailable, treat any standard-dispellable as player-dispellable
                    local dn = auraData.dispelName
                    if dn == "Magic" or dn == "Curse" or dn == "Disease" or dn == "Poison" then
                        DebugPrint("|cff88ff88Scan " .. unit .. ":|r dispellable aura found (fallback, id=" .. id .. ")")
                        return true
                    end
                end
            end
        end

        return false
    else
        -- "All Dispellable": alert for any harmful aura with a dispel type
        for i = 1, 40 do
            local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
            if not auraData then break end

            if auraData.dispelName ~= nil then
                DebugPrint("|cff88ff88Scan " .. unit .. ":|r dispellable aura found (all mode)")
                return true
            end
        end

        return false
    end
end

-- ============================================================================
-- SOUND PLAYBACK
-- ============================================================================

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
        DebugPrint("|cffff8888DoPlaySound:|r returned false, retrying without channel...")
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
        DebugPrint("|cffff8888PlayDispelSound:|r blocked by global cooldown")
        return false
    end

    local soundType, soundValue = ResolveSoundFile("soundFile")
    local ok = DoPlaySound(soundType, soundValue, db.soundChannel or "Master")
    lastGlobalSound = now
    return ok
end

local function PlayForUnit(unit)
    if not db.enabled then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    local now = GetTime()
    if unitCooldowns[guid] and (now - unitCooldowns[guid]) < db.cooldownPerUnit then
        DebugPrint("|cffff8888PlayForUnit(" .. unit .. "):|r per-unit cooldown")
        return
    end

    DebugPrint("|cff88ff88PlayForUnit(" .. unit .. "):|r playing sound")
    if PlayDispelSound() then
        unitCooldowns[guid] = now
    end
end

-- ============================================================================
-- REPEAT TIMERS
-- ============================================================================

local function StopRepeat(guid)
    if repeatTimers[guid] then
        repeatTimers[guid]:Cancel()
        repeatTimers[guid] = nil
    end
end

local function StopAllRepeats()
    for guid, timer in pairs(repeatTimers) do
        timer:Cancel()
    end
    wipe(repeatTimers)
end

local function StartRepeat(unit)
    if not db.repeatSound then return end
    local guid = UnitGUID(unit)
    if not guid then return end
    StopRepeat(guid)

    local capturedUnit = unit
    repeatTimers[guid] = C_Timer.NewTicker(db.repeatInterval, function()
        if not db.enabled or not db.repeatSound then
            StopRepeat(guid)
            return
        end

        if not UnitExists(capturedUnit) or UnitGUID(capturedUnit) ~= guid then
            StopRepeat(guid)
            return
        end

        local scanResult = ScanUnitForDispellableDebuffs(capturedUnit)
        if not scanResult then
            StopRepeat(guid)
            dispelState[guid] = false
            return
        end

        PlayForUnit(capturedUnit)
    end)
end

-- ============================================================================
-- UNIT PROCESSING
-- ============================================================================

local function GetPlayerRole()
    local specIndex = GetSpecialization()
    if specIndex then
        local role = GetSpecializationRole(specIndex)
        if role and role ~= "NONE" then
            return role
        end
    end
    return "NONE"
end

local function IsPlayerRoleEnabled()
    local role = GetPlayerRole()
    if role == "HEALER" then return db.enableRoleHealer end
    if role == "DAMAGER" then return db.enableRoleDPS end
    if role == "TANK" then return db.enableRoleTank end
    return true -- NONE or unknown: always alert
end

local function ProcessUnit(unit)
    if not db or not db.enabled then return end
    if not UnitExists(unit) then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    if not IsPlayerRoleEnabled() then
        if dispelState[guid] then
            dispelState[guid] = false
            StopRepeat(guid)
        end
        return
    end

    local scanResult = ScanUnitForDispellableDebuffs(unit)

    if scanResult and not dispelState[guid] then
        DebugPrint("|cff00ff00ALERT|r " .. unit .. ": dispellable debuff detected")
        dispelState[guid] = true
        PlayForUnit(unit)
        StartRepeat(unit)
    elseif not scanResult and dispelState[guid] then
        DebugPrint("|cff888888CLEAR|r " .. unit .. ": no more dispellable debuffs")
        dispelState[guid] = false
        StopRepeat(guid)
    end
end

-- ============================================================================
-- UNIT RELEVANCE
-- ============================================================================

local function IsRelevantUnit(unit)
    if not unit then return false end
    if unit == "player" then return true end
    if unit:match("^party%d") then return true end
    if unit:match("^raid%d") then return true end
    return false
end

-- ============================================================================
-- SCANNING
-- ============================================================================

local function ScanAllUnits()
    if not db or not db.enabled then return end

    ProcessUnit("player")

    local numGroup = GetNumGroupMembers()
    if numGroup == 0 then return end

    local inRaid = IsInRaid()
    if inRaid then
        for i = 1, numGroup do
            ProcessUnit("raid" .. i)
        end
    else
        for i = 1, numGroup - 1 do
            ProcessUnit("party" .. i)
        end
    end
end

-- ============================================================================
-- EVENTS
-- ============================================================================

local eventFrame = CreateFrame("Frame")
local pendingUnits = {}
local batchScheduled = false

local function ProcessPendingUnits()
    batchScheduled = false
    if not db or not db.enabled then
        wipe(pendingUnits)
        return
    end

    for unit in pairs(pendingUnits) do
        ProcessUnit(unit)
    end
    wipe(pendingUnits)
end

local function ScheduleBatch()
    if not batchScheduled then
        batchScheduled = true
        C_Timer.After(0, ProcessPendingUnits)
    end
end

eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")

eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "ADDON_LOADED" then
        local name = ...
        if name == addonName then
            -- Migrate from old DispelSoundAlertDB
            if not NT_DispelSoundsDB and DispelSoundAlertDB then
                NT_DispelSoundsDB = DispelSoundAlertDB
                DispelSoundAlertDB = nil
            end

            if not NT_DispelSoundsDB then
                NT_DispelSoundsDB = {}
            end

            -- Convert flat settings to profile structure
            if not NT_DispelSoundsDB.profiles then
                -- Legacy key migrations
                if NT_DispelSoundsDB.soundName and not NT_DispelSoundsDB.soundFile then
                    NT_DispelSoundsDB.soundFile = NT_DispelSoundsDB.soundName
                end
                if NT_DispelSoundsDB.filterMode == "manual" then
                    NT_DispelSoundsDB.filterMode = "all"
                end

                -- Collect valid settings (only DEFAULTS keys, ignore legacy)
                local settings = {}
                for k, v in pairs(DEFAULTS) do
                    settings[k] = (NT_DispelSoundsDB[k] ~= nil) and NT_DispelSoundsDB[k] or v
                end

                NT_DispelSoundsDB = {
                    profiles = { ["Default"] = settings },
                    activeProfile = "Default",
                }
            end

            -- Ensure active profile is valid
            local ap = NT_DispelSoundsDB.activeProfile or "Default"
            if not NT_DispelSoundsDB.profiles[ap] then
                ap = next(NT_DispelSoundsDB.profiles) or "Default"
                NT_DispelSoundsDB.activeProfile = ap
            end
            if not NT_DispelSoundsDB.profiles[ap] then
                NT_DispelSoundsDB.profiles[ap] = {}
            end

            -- Apply defaults to active profile
            for k, v in pairs(DEFAULTS) do
                if NT_DispelSoundsDB.profiles[ap][k] == nil then
                    NT_DispelSoundsDB.profiles[ap][k] = v
                end
            end

            db = NT_DispelSoundsDB.profiles[ap]
            DSA.db = db

            self:RegisterEvent("UNIT_AURA")
            self:RegisterEvent("GROUP_ROSTER_UPDATE")
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
            self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. "|r |cff888888v" .. ADDON_VERSION .. "|r loaded. Use |cffffff00/dsa|r to open options.")
        C_Timer.After(2, ScanAllUnits)
        C_Timer.After(1, function()
            if NT_DispelSoundsDB and NT_DispelSoundsDB.changelogDismissedVersion ~= ADDON_VERSION and DSA.ShowChangelogPopup then
                DSA:ShowChangelogPopup()
            end
        end)

    elseif event == "UNIT_AURA" then
        local unit = ...
        if IsRelevantUnit(unit) then
            pendingUnits[unit] = true
            ScheduleBatch()
        end

    elseif event == "GROUP_ROSTER_UPDATE" then
        wipe(dispelState)
        wipe(unitCooldowns)
        StopAllRepeats()
        C_Timer.After(0.5, ScanAllUnits)

    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(dispelState)
        wipe(unitCooldowns)
        StopAllRepeats()
        C_Timer.After(1, ScanAllUnits)

    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        DebugPrint("|cffffff00Spec changed:|r resetting dispel state")
        C_Timer.After(0.5, function()
            wipe(dispelState)
            StopAllRepeats()
            ScanAllUnits()
        end)
    end
end)

-- ============================================================================
-- SLASH COMMANDS
-- ============================================================================

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
            print("  Enabled: " .. tostring(db.enabled))
            print("  Mode: " .. tostring(db.filterMode))
            local lsm = GetLSM()
            print("  LSM loaded: " .. tostring(lsm ~= nil))
            print("  Sound: " .. tostring(db.soundFile or "(default)"))
        end
    elseif msg == "status" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Status:")
        print("  Enabled: " .. (db.enabled and "|cff00ff00YES|r" or "|cffff0000NO|r"))

        print("  Roles: Healer=" .. (db.enableRoleHealer and "|cff00ff00YES|r" or "|cffff0000NO|r")
            .. " DPS=" .. (db.enableRoleDPS and "|cff00ff00YES|r" or "|cffff0000NO|r")
            .. " Tank=" .. (db.enableRoleTank and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Mode: " .. tostring(db.filterMode))
        if db.filterMode == "auto" then
            print("  Dispellable by Me: uses RAID_PLAYER_DISPELLABLE filter")
        else
            print("  All Dispellable: alerts for any dispellable debuff")
        end
        print("  Sound: " .. tostring(db.soundFile or "(default)"))
        print("  Channel: " .. tostring(db.soundChannel))
    elseif msg == "reset" then
        wipe(dispelState)
        wipe(unitCooldowns)
        StopAllRepeats()
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r State reset.")
    elseif msg == "scan" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Scanning all units...")
        ScanAllUnits()
    elseif msg == "changelog" then
        DSA:ShowChangelog()
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
            print("  /dsa scan - Force rescan all units")
            print("  /dsa changelog - Show changelog")
        end
    end
end

-- ============================================================================
-- PROFILE MANAGEMENT
-- ============================================================================

function DSA.GetProfileList()
    local list = {}
    for name in pairs(NT_DispelSoundsDB.profiles) do
        list[#list + 1] = name
    end
    table.sort(list)
    return list
end

function DSA.GetActiveProfile()
    return NT_DispelSoundsDB.activeProfile
end

function DSA.SwitchProfile(name)
    if not NT_DispelSoundsDB.profiles[name] then return false end
    NT_DispelSoundsDB.activeProfile = name
    for k, v in pairs(DEFAULTS) do
        if NT_DispelSoundsDB.profiles[name][k] == nil then
            NT_DispelSoundsDB.profiles[name][k] = v
        end
    end
    db = NT_DispelSoundsDB.profiles[name]
    DSA.db = db
    wipe(dispelState)
    wipe(unitCooldowns)
    StopAllRepeats()
    C_Timer.After(0.5, ScanAllUnits)
    return true
end

function DSA.CreateProfile(name, copyFrom)
    if not name or name == "" then return false end
    if NT_DispelSoundsDB.profiles[name] then return false end
    if copyFrom and NT_DispelSoundsDB.profiles[copyFrom] then
        local copy = {}
        for k, v in pairs(NT_DispelSoundsDB.profiles[copyFrom]) do
            copy[k] = v
        end
        NT_DispelSoundsDB.profiles[name] = copy
    else
        local new = {}
        for k, v in pairs(DEFAULTS) do
            new[k] = v
        end
        NT_DispelSoundsDB.profiles[name] = new
    end
    return true
end

function DSA.DeleteProfile(name)
    if not name or name == "" then return false end
    if name == NT_DispelSoundsDB.activeProfile then return false end
    if not NT_DispelSoundsDB.profiles[name] then return false end
    NT_DispelSoundsDB.profiles[name] = nil
    return true
end

function DSA.RenameProfile(oldName, newName)
    if not newName or newName == "" then return false end
    if not NT_DispelSoundsDB.profiles[oldName] then return false end
    if NT_DispelSoundsDB.profiles[newName] then return false end
    NT_DispelSoundsDB.profiles[newName] = NT_DispelSoundsDB.profiles[oldName]
    NT_DispelSoundsDB.profiles[oldName] = nil
    if NT_DispelSoundsDB.activeProfile == oldName then
        NT_DispelSoundsDB.activeProfile = newName
    end
    return true
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

DSA.PlayDispelSound = PlayDispelSound
DSA.ScanAllUnits = ScanAllUnits
DSA.ResolveSoundFile = ResolveSoundFile
DSA.GetLSM = GetLSM
DSA.StopAllRepeats = StopAllRepeats
