-- ============================================================================
-- NT_DispelSounds - Core (Standalone)
-- Plays a sound when a dispellable debuff is detected on party or raid members
-- ============================================================================

local addonName, DSA = ...
local ADDON_DISPLAY_NAME = "NT_DispelSounds"
local ADDON_VERSION = "2.0.0"

-- ============================================================================
-- DEFAULTS
-- ============================================================================

local DEFAULTS = {
    enabled = true,
    enableParty = true,
    enableRaid = true,
    enablePlayer = true,
    filterMode = "auto",
    includeRacials = true,
    soundFile = nil,
    soundChannel = "Master",
    cooldownPerUnit = 3,
    globalCooldown = 0.5,
    repeatSound = false,
    repeatInterval = 5,
    debug = false,
    changelogDismissed = nil,
}

DSA.DEFAULTS = DEFAULTS
DSA.ADDON_DISPLAY_NAME = ADDON_DISPLAY_NAME
DSA.ADDON_VERSION = ADDON_VERSION

-- ============================================================================
-- DISPEL CAPABILITY TABLES
-- ============================================================================

-- classID -> specID -> { dispel types removable from friendlies }
local CLASS_SPEC_DISPELS = {
    [2] = { -- Paladin
        [65]  = {"Magic", "Poison", "Disease"},      -- Holy (Cleanse)
        [66]  = {"Poison", "Disease"},               -- Protection (Cleanse Toxins)
        [70]  = {"Poison", "Disease"},               -- Retribution (Cleanse Toxins)
    },
    [5] = { -- Priest
        [256] = {"Magic", "Disease"},                -- Discipline (Purify)
        [257] = {"Magic", "Disease"},                -- Holy (Purify)
        [258] = {"Disease"},                         -- Shadow (Purify Disease)
    },
    [7] = { -- Shaman
        [262] = {"Curse"},                           -- Elemental (Cleanse Spirit)
        [263] = {"Curse"},                           -- Enhancement (Cleanse Spirit)
        [264] = {"Magic", "Curse"},                  -- Restoration (Purify Spirit)
    },
    [8] = { -- Mage
        [62]  = {"Curse"},                           -- Arcane (Remove Curse)
        [63]  = {"Curse"},                           -- Fire (Remove Curse)
        [64]  = {"Curse"},                           -- Frost (Remove Curse)
    },
    [10] = { -- Monk
        [268] = {"Poison", "Disease"},               -- Brewmaster (Detox)
        [269] = {"Poison", "Disease"},               -- Windwalker (Detox)
        [270] = {"Magic", "Poison", "Disease"},      -- Mistweaver (Detox)
    },
    [11] = { -- Druid
        [102] = {"Curse", "Poison"},                 -- Balance (Remove Corruption)
        [103] = {"Curse", "Poison"},                 -- Feral (Remove Corruption)
        [104] = {"Curse", "Poison"},                 -- Guardian (Remove Corruption)
        [105] = {"Magic", "Curse", "Poison"},        -- Restoration (Nature's Cure)
    },
    [13] = { -- Evoker
        [1467] = {"Poison", "Disease", "Curse", "Bleed"},           -- Devastation (Cauterizing Flame)
        [1468] = {"Magic", "Poison", "Disease", "Curse", "Bleed"},  -- Preservation (Naturalize + Cauterizing Flame)
        [1473] = {"Poison", "Disease", "Curse", "Bleed"},           -- Augmentation (Cauterizing Flame)
    },
}

-- Racial self-dispel abilities (remove debuffs from self only)
-- raceFile (from UnitRace) -> { types }
local RACIAL_DISPELS = {
    ["Dwarf"]         = {"Poison", "Disease", "Bleed"},                    -- Stoneform
    ["DarkIronDwarf"] = {"Poison", "Disease", "Curse", "Bleed", "Magic"}, -- Fireblood
}

-- dispelName string (from aura data) -> our key
local DISPEL_NAME_TO_KEY = {
    ["Magic"]   = "Magic",
    ["Curse"]   = "Curse",
    ["Disease"] = "Disease",
    ["Poison"]  = "Poison",
}

-- ============================================================================
-- STATE
-- ============================================================================

local db
local dispelState = {}
local unitCooldowns = {}
local lastGlobalSound = 0
local repeatTimers = {}
local LSM

local autoDispelTypes = {}
local autoRacialTypes = {}
local autoDetectDirty = true

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
-- AUTO-DETECT
-- ============================================================================

local function UpdateAutoDetect()
    wipe(autoDispelTypes)
    wipe(autoRacialTypes)

    local _, _, classID = UnitClass("player")
    local specIndex = GetSpecialization()
    local specID = specIndex and GetSpecializationInfo(specIndex) or nil

    if classID and CLASS_SPEC_DISPELS[classID] then
        local specTable = specID and CLASS_SPEC_DISPELS[classID][specID]
        if specTable then
            for _, t in ipairs(specTable) do
                autoDispelTypes[t] = true
            end
        end
    end

    if db and db.includeRacials then
        local _, raceFile = UnitRace("player")
        if raceFile and RACIAL_DISPELS[raceFile] then
            for _, t in ipairs(RACIAL_DISPELS[raceFile]) do
                autoRacialTypes[t] = true
            end
        end
    end

    autoDetectDirty = false

    if db and db.debug then
        local types = {}
        for t in pairs(autoDispelTypes) do types[#types + 1] = t end
        DebugPrint("|cff88ff88Auto-detect:|r spec types = {" .. table.concat(types, ", ") .. "}")
        local rt = {}
        for t in pairs(autoRacialTypes) do rt[#rt + 1] = t end
        if #rt > 0 then
            DebugPrint("|cff88ff88Auto-detect:|r racial (self) = {" .. table.concat(rt, ", ") .. "}")
        end
    end
end

DSA.UpdateAutoDetect = UpdateAutoDetect

function DSA.GetAutoDetectedTypes()
    if autoDetectDirty then UpdateAutoDetect() end
    return autoDispelTypes
end

function DSA.GetAutoRacialTypes()
    if autoDetectDirty then UpdateAutoDetect() end
    return autoRacialTypes
end

function DSA.MarkAutoDetectDirty()
    autoDetectDirty = true
end

-- ============================================================================
-- DISPEL TYPE FILTER (informational — used for auto-detect display only)
-- ============================================================================

local function IsDispelTypeEnabled(dispelType, unit)
    if not dispelType then return false end

    if db.filterMode == "auto" then
        if autoDetectDirty then UpdateAutoDetect() end
        if autoDispelTypes[dispelType] then return true end
        if unit and UnitIsUnit(unit, "player") and autoRacialTypes[dispelType] then
            return true
        end
        return false
    else
        -- "all" mode: any dispellable aura triggers
        return true
    end
end

-- ============================================================================
-- AURA SCANNING
-- Combat-safe: aura fields (dispelName, dispelType, etc.) are secret values
-- in WoW and cannot be used as table indices or compared to strings.
-- We use C_UnitAuras.IsAuraFilteredOut with RAID_PLAYER_DISPELLABLE (auto)
-- or nil-checks on dispelName (all mode) which are secret-safe.
-- ============================================================================

local FILTER_PLAYER_DISPELLABLE = "HARMFUL|RAID_PLAYER_DISPELLABLE"

local function ScanUnitForDispellableDebuffs(unit)
    if not C_UnitAuras or not C_UnitAuras.GetAuraDataByIndex then return false end
    if not UnitExists(unit) then return false end

    if db.filterMode == "auto" then
        -- Auto mode: use Blizzard's RAID_PLAYER_DISPELLABLE filter (combat-safe)
        -- This matches debuffs the player's class/spec can remove
        local IsAuraFilteredOut = C_UnitAuras.IsAuraFilteredOut
        if IsAuraFilteredOut then
            for i = 1, 40 do
                local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                if not auraData then break end

                local id = auraData.auraInstanceID
                if id and not IsAuraFilteredOut(unit, id, FILTER_PLAYER_DISPELLABLE) then
                    DebugPrint("|cff88ff88Scan " .. unit .. ":|r player-dispellable aura found (id=" .. id .. ")")
                    return true
                end
            end
        else
            -- Fallback if IsAuraFilteredOut unavailable: nil-check dispelName
            for i = 1, 40 do
                local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                if not auraData then break end

                -- nil-check is safe with secret values (returns true if value exists but is secret)
                if auraData.dispelName ~= nil then
                    DebugPrint("|cff88ff88Scan " .. unit .. ":|r dispellable aura found (fallback)")
                    return true
                end
            end
        end

        -- For racial self-dispels on player: check if any harmful aura is dispellable
        -- Racials (Stoneform, Fireblood) can remove types not in RAID_PLAYER_DISPELLABLE
        if db.includeRacials and UnitIsUnit(unit, "player") then
            local hasRacials = next(autoRacialTypes) ~= nil
            if hasRacials then
                for i = 1, 40 do
                    local auraData = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL")
                    if not auraData then break end

                    if auraData.dispelName ~= nil then
                        DebugPrint("|cff88ff88Scan " .. unit .. ":|r racial-dispellable aura on self")
                        return true
                    end
                end
            end
        end

        return false
    else
        -- All Dispellable mode: alert for any harmful aura with a dispel type
        -- nil-check on dispelName is safe with secret values
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

        if not ScanUnitForDispellableDebuffs(capturedUnit) then
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

local function ProcessUnit(unit)
    if not db or not db.enabled then return end
    if not UnitExists(unit) then return end

    local guid = UnitGUID(unit)
    if not guid then return end

    local hasDispellable = ScanUnitForDispellableDebuffs(unit)

    if hasDispellable and not dispelState[guid] then
        DebugPrint("|cff00ff00ALERT|r " .. unit .. ": dispellable debuff detected")
        dispelState[guid] = true
        PlayForUnit(unit)
        StartRepeat(unit)
    elseif not hasDispellable and dispelState[guid] then
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
    if unit == "player" then return db.enablePlayer end
    if unit:match("^party%d") then return db.enableParty end
    if unit:match("^raid%d") then return db.enableRaid end
    return false
end

-- ============================================================================
-- SCANNING
-- ============================================================================

local function ScanAllUnits()
    if not db or not db.enabled then return end

    if db.enablePlayer then
        ProcessUnit("player")
    end

    local numGroup = GetNumGroupMembers()
    if numGroup == 0 then return end

    local inRaid = IsInRaid()
    if inRaid then
        if db.enableRaid then
            for i = 1, numGroup do
                ProcessUnit("raid" .. i)
            end
        end
    else
        if db.enableParty then
            for i = 1, numGroup - 1 do
                ProcessUnit("party" .. i)
            end
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
            -- Migrate from old DispelSoundAlertDB if NT_DispelSoundsDB doesn't exist yet
            if not NT_DispelSoundsDB and DispelSoundAlertDB then
                NT_DispelSoundsDB = DispelSoundAlertDB
                DispelSoundAlertDB = nil
            end

            if not NT_DispelSoundsDB then
                NT_DispelSoundsDB = {}
            end

            for k, v in pairs(DEFAULTS) do
                if NT_DispelSoundsDB[k] == nil then
                    NT_DispelSoundsDB[k] = v
                end
            end

            -- Migrate legacy keys from old DandersFrames-dependent version
            if NT_DispelSoundsDB.soundName and not NT_DispelSoundsDB.soundFile then
                NT_DispelSoundsDB.soundFile = NT_DispelSoundsDB.soundName
                NT_DispelSoundsDB.soundName = nil
            end
            NT_DispelSoundsDB.onlyPlayerDispellable = nil
            NT_DispelSoundsDB.racialEnabled = nil
            NT_DispelSoundsDB.racialSoundFile = nil
            NT_DispelSoundsDB.racialSoundName = nil
            NT_DispelSoundsDB.racialSoundChannel = nil
            NT_DispelSoundsDB.racialCooldown = nil
            NT_DispelSoundsDB.racialOnlyOffCooldown = nil

            -- Clean up old per-type filter keys (no longer used; secret values prevent type filtering)
            NT_DispelSoundsDB.filterMagic = nil
            NT_DispelSoundsDB.filterCurse = nil
            NT_DispelSoundsDB.filterDisease = nil
            NT_DispelSoundsDB.filterPoison = nil
            NT_DispelSoundsDB.filterBleed = nil
            NT_DispelSoundsDB.filterEnrage = nil

            -- Migrate old "manual" mode to "all"
            if NT_DispelSoundsDB.filterMode == "manual" then
                NT_DispelSoundsDB.filterMode = "all"
            end

            db = NT_DispelSoundsDB
            DSA.db = db

            self:RegisterEvent("UNIT_AURA")
            self:RegisterEvent("GROUP_ROSTER_UPDATE")
            self:RegisterEvent("PLAYER_ENTERING_WORLD")
            self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")

            self:UnregisterEvent("ADDON_LOADED")
        end

    elseif event == "PLAYER_LOGIN" then
        UpdateAutoDetect()
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. "|r |cff888888v" .. ADDON_VERSION .. "|r loaded. Use |cffffff00/dsa|r to open options.")
        C_Timer.After(2, ScanAllUnits)

        -- Show changelog popup if not dismissed
        if db and db.changelogDismissed ~= ADDON_VERSION then
            C_Timer.After(3, function()
                DSA:ShowChangelog()
            end)
        end

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
        autoDetectDirty = true
        DebugPrint("|cffffff00Spec changed:|r re-detecting dispel types")
        C_Timer.After(0.5, function()
            UpdateAutoDetect()
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
            UpdateAutoDetect()
            print("  Enabled: " .. tostring(db.enabled))
            print("  Mode: " .. tostring(db.filterMode))
            local types = {}
            for t in pairs(autoDispelTypes) do types[#types + 1] = t end
            print("  Auto-detected types: " .. (#types > 0 and table.concat(types, ", ") or "(none)"))
            local rt = {}
            for t in pairs(autoRacialTypes) do rt[#rt + 1] = t end
            if #rt > 0 then
                print("  Racial types (self): " .. table.concat(rt, ", "))
            end
            local lsm = GetLSM()
            print("  LSM loaded: " .. tostring(lsm ~= nil))
            print("  Sound: " .. tostring(db.soundFile or "(default)"))
        end
    elseif msg == "status" then
        print("|cff00ccff" .. ADDON_DISPLAY_NAME .. ":|r Status:")
        print("  Enabled: " .. (db.enabled and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Party: " .. (db.enableParty and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Raid: " .. (db.enableRaid and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Player: " .. (db.enablePlayer and "|cff00ff00YES|r" or "|cffff0000NO|r"))
        print("  Mode: " .. tostring(db.filterMode))
        if db.filterMode == "auto" then
            UpdateAutoDetect()
            local types = {}
            for t in pairs(autoDispelTypes) do types[#types + 1] = t end
            print("  Detected types: " .. (#types > 0 and table.concat(types, ", ") or "(none - no spec?)"))
        else
            print("  All Dispellable mode: alerts for any dispellable debuff")
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
-- CHANGELOG POPUP
-- ============================================================================

local changelogFrame = nil

function DSA:ShowChangelog()
    if changelogFrame then
        changelogFrame:Show()
        return
    end

    local WIDTH = 440
    local HEIGHT = 420

    local f = CreateFrame("Frame", "NT_DispelSoundsChangelog", UIParent, "BackdropTemplate")
    f:SetSize(WIDTH, HEIGHT)
    f:SetPoint("CENTER")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    f:SetBackdropBorderColor(0.25, 0.25, 0.25, 1)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)

    tinsert(UISpecialFrames, "NT_DispelSoundsChangelog")

    -- Header
    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    header:SetHeight(36)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(0.12, 0.12, 0.12, 1)

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff00ccffNT_DispelSounds|r  |cff888888v" .. ADDON_VERSION .. "|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(28, 28)
    closeBtn:SetPoint("RIGHT", -6, 0)
    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeTex:SetPoint("CENTER")
    closeTex:SetText("x")
    closeTex:SetTextColor(0.7, 0.7, 0.7, 1)
    closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(0.7, 0.7, 0.7, 1) end)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Body scroll
    local scrollFrame = CreateFrame("ScrollFrame", nil, f, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", 16, -44)
    scrollFrame:SetPoint("BOTTOMRIGHT", -36, 52)

    local body = CreateFrame("Frame", nil, scrollFrame)
    body:SetWidth(WIDTH - 56)
    scrollFrame:SetScrollChild(body)

    local text = body:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(WIDTH - 56)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    text:SetText(
        "|cffffd100What's New in v" .. ADDON_VERSION .. "|r\n\n"
        .. "|cff00ccffRenamed to NT_DispelSounds|r\n"
        .. "This addon was previously called |cff888888DandersFrames_DispelSounds|r.\n"
        .. "It has been renamed to |cff00ccffNT_DispelSounds|r.\n\n"

        .. "|cff00ccffDandersFrames is no longer required|r\n"
        .. "The addon is now fully standalone. It scans unit auras directly\n"
        .. "using the WoW C_UnitAuras API. No external frame addon needed.\n\n"

        .. "|cff00ccffTwo detection modes|r\n"
        .. "|cffffff00Dispellable by Me|r - Uses Blizzard's RAID_PLAYER_DISPELLABLE\n"
        .. "filter to detect only debuffs your class/spec can remove.\n"
        .. "Automatically updates when you change specs.\n\n"
        .. "|cffffff00All Dispellable|r - Alerts for any debuff that has a dispel type\n"
        .. "(Magic, Curse, Disease, Poison) on any group member.\n\n"

        .. "|cff888888Note: WoW uses secret values for aura data in combat,\n"
        .. "which prevents per-type filtering (e.g. only Magic). Both modes\n"
        .. "are fully combat-safe.|r\n\n"

        .. "|cff00ccffRacial support|r\n"
        .. "Dwarf (Stoneform) and Dark Iron Dwarf (Fireblood) racials\n"
        .. "are detected for self-dispel alerts on the player unit.\n\n"

        .. "|cff00ccffPlayer unit monitoring|r\n"
        .. "New option to enable/disable alerts for your own character.\n\n"

        .. "|cff00ccffSettings migrated|r\n"
        .. "Your previous sound, timing, and repeat settings carry over\n"
        .. "automatically from the old saved variables.\n\n"

        .. "|cff888888Use |cffffff00/dsa|cff888888 to open options. "
        .. "Use |cffffff00/dsa changelog|cff888888 to show this again.|r"
    )

    body:SetHeight(text:GetStringHeight() + 20)

    -- Bottom bar
    local bottomBar = CreateFrame("Frame", nil, f)
    bottomBar:SetHeight(46)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)

    local sep = bottomBar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 8, 0)
    sep:SetPoint("TOPRIGHT", -8, 0)
    sep:SetColorTexture(0.25, 0.25, 0.25, 0.8)

    -- "Don't show again" checkbox
    local cbBox = CreateFrame("Frame", nil, bottomBar, "BackdropTemplate")
    cbBox:SetSize(16, 16)
    cbBox:SetPoint("LEFT", 16, -2)
    cbBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local cbCheck = cbBox:CreateTexture(nil, "OVERLAY")
    cbCheck:SetSize(12, 12)
    cbCheck:SetPoint("CENTER")
    cbCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    cbCheck:Hide()

    local cbLabel = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbLabel:SetPoint("LEFT", cbBox, "RIGHT", 6, 0)
    cbLabel:SetText("Don't show this again")
    cbLabel:SetTextColor(0.7, 0.7, 0.7, 1)

    local dismissed = false

    local function UpdateCheckVisual()
        if dismissed then
            cbBox:SetBackdropColor(0.3 * 1, 0.3 * 0.82, 0, 1)
            cbBox:SetBackdropBorderColor(1, 0.82, 0, 1)
            cbCheck:Show()
        else
            cbBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
            cbBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            cbCheck:Hide()
        end
    end

    local function ToggleDismiss()
        dismissed = not dismissed
        if dismissed then
            db.changelogDismissed = ADDON_VERSION
        else
            db.changelogDismissed = nil
        end
        UpdateCheckVisual()
    end

    cbBox:EnableMouse(true)
    cbBox:SetScript("OnMouseUp", ToggleDismiss)
    bottomBar:EnableMouse(true)
    bottomBar:SetScript("OnMouseUp", function(self, button, ...)
        local left = cbBox:GetLeft()
        local right = cbLabel:GetRight()
        local top = cbBox:GetTop()
        local bottom = cbBox:GetBottom()
        if not left then return end
        local cx, cy = GetCursorPosition()
        local s = UIParent:GetEffectiveScale()
        cx, cy = cx / s, cy / s
        if cx >= left and cx <= right + 4 and cy >= bottom - 2 and cy <= top + 2 then
            ToggleDismiss()
        end
    end)

    -- Set initial state
    dismissed = (db.changelogDismissed == ADDON_VERSION)
    UpdateCheckVisual()

    changelogFrame = f
    f:Show()
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

DSA.PlayDispelSound = PlayDispelSound
DSA.ScanAllUnits = ScanAllUnits
DSA.ResolveSoundFile = ResolveSoundFile
DSA.GetLSM = GetLSM
DSA.StopAllRepeats = StopAllRepeats
DSA.IsDispelTypeEnabled = IsDispelTypeEnabled
DSA.CLASS_SPEC_DISPELS = CLASS_SPEC_DISPELS
DSA.RACIAL_DISPELS = RACIAL_DISPELS
