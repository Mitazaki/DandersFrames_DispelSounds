-- ============================================================================
-- NT_DispelSounds - Options Panel (Standalone)
-- ============================================================================

local addonName, DSA = ...

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local PANEL_WIDTH = 420
local PANEL_HEIGHT = 600
local COL_PADDING = 20
local COMPONENT_GAP = 6
local SECTION_GAP = 14
local HEADER_HEIGHT = 36
local FOOTER_HEIGHT = 52

local DEFAULT_SOUND_LABEL = "(Default: Raid Warning)"
local NONE_SOUND_LABEL = "None"
local ADDON_DISPLAY_NAME = DSA.ADDON_DISPLAY_NAME or "NT_DispelSounds"
local ADDON_VERSION = DSA.ADDON_VERSION or "2.0.0"

-- Color palette
local Colors = {
    panelBg       = { 0.08, 0.08, 0.08, 0.95 },
    panelBorder   = { 0.25, 0.25, 0.25, 1 },
    headerBg      = { 0.12, 0.12, 0.12, 1 },
    sectionBg     = { 0.1, 0.1, 0.1, 0.6 },
    sectionBorder = { 0.2, 0.2, 0.2, 1 },
    accent        = { 1, 0.82, 0, 1 },          -- Gold
    accentDim     = { 0.6, 0.5, 0.1, 1 },
    text          = { 1, 1, 1, 1 },
    textDim       = { 0.7, 0.7, 0.7, 1 },
    textMuted     = { 0.5, 0.5, 0.5, 1 },
    btnBg         = { 0.15, 0.15, 0.15, 1 },
    btnBgHover    = { 0.22, 0.22, 0.22, 1 },
    btnBorder     = { 0.3, 0.3, 0.3, 1 },
    btnBorderHov  = { 0.5, 0.5, 0.5, 1 },
    checkOn       = { 1, 0.82, 0, 1 },
    checkOff      = { 0.3, 0.3, 0.3, 1 },
    checkDisabled = { 0.2, 0.2, 0.2, 1 },
    sliderTrack   = { 0.2, 0.2, 0.2, 1 },
    sliderFill    = { 0.6, 0.5, 0.1, 1 },
    sliderThumb   = { 0.4, 0.4, 0.4, 1 },
    sliderThumbH  = { 1, 0.82, 0, 1 },
    dropBg        = { 0.1, 0.1, 0.1, 0.95 },
    dropBorder    = { 0.3, 0.3, 0.3, 1 },
    dropBorderFoc = { 1, 0.82, 0, 1 },
    separator     = { 0.25, 0.25, 0.25, 0.8 },
    success       = { 0.2, 0.8, 0.2, 1 },
    warning       = { 1, 0.6, 0, 1 },
    magic         = { 0.2, 0.6, 1.0, 1 },
    curse         = { 0.6, 0.0, 1.0, 1 },
    disease       = { 0.6, 0.4, 0.0, 1 },
    poison        = { 0.0, 0.6, 0.0, 1 },
    bleed         = { 1.0, 0.0, 0.0, 1 },
    enrage        = { 1.0, 0.4, 0.0, 1 },
}

-- Dispel type display info (for auto-detect readout only)
local DISPEL_TYPE_INFO = {
    { key = "Magic",   label = "Magic",   color = Colors.magic },
    { key = "Curse",   label = "Curse",   color = Colors.curse },
    { key = "Disease", label = "Disease", color = Colors.disease },
    { key = "Poison",  label = "Poison",  color = Colors.poison },
    { key = "Bleed",   label = "Bleed",   color = Colors.bleed },
    { key = "Enrage",  label = "Enrage",  color = Colors.enrage },
}

-- ============================================================================
-- LIBSHAREDMEDIA
-- ============================================================================

local function GetLSM()
    return LibStub and LibStub("LibSharedMedia-3.0", true)
end

local function GetSoundList()
    local lsm = GetLSM()
    local items = { DEFAULT_SOUND_LABEL, NONE_SOUND_LABEL }
    if not lsm then return items end

    local list = lsm:List("sound")
    if not list or #list == 0 then return items end

    for _, soundName in ipairs(list) do
        if soundName ~= NONE_SOUND_LABEL then
            items[#items + 1] = soundName
        end
    end

    return items
end

-- ============================================================================
-- TOOLTIP HELPERS
-- ============================================================================

local function ShowTooltip(owner, title, desc)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(title, 1, 1, 1)
    if desc then
        GameTooltip:AddLine(desc, 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- ============================================================================
-- UI COMPONENT FACTORIES
-- ============================================================================

local refreshableComponents = {}

local function RegisterRefreshable(widget, refreshFn)
    refreshableComponents[#refreshableComponents + 1] = { widget = widget, refresh = refreshFn }
end

local function RefreshAll()
    for _, entry in ipairs(refreshableComponents) do
        if entry.widget and entry.refresh then
            entry.refresh()
        end
    end
end

-- --------------------------------------------------------------------------
-- Checkbox
-- --------------------------------------------------------------------------
local function CreateCheckbox(parent, config)
    local db = DSA.db

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(config.width or (PANEL_WIDTH - COL_PADDING * 2), 22)

    local box = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    box:SetSize(16, 16)
    box:SetPoint("LEFT", 0, 0)
    box:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local check = box:CreateTexture(nil, "OVERLAY")
    check:SetSize(12, 12)
    check:SetPoint("CENTER")
    check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", box, "RIGHT", 6, 0)
    label:SetText(config.label)
    label:SetTextColor(unpack(Colors.text))

    holder._isDisabled = false

    local function UpdateVisual()
        local checked = config.get()
        local disabled = holder._isDisabled
        if checked then
            if disabled then
                box:SetBackdropColor(Colors.checkOn[1] * 0.15, Colors.checkOn[2] * 0.15, Colors.checkOn[3] * 0.15, 1)
                box:SetBackdropBorderColor(unpack(Colors.checkDisabled))
                check:Show()
                check:SetAlpha(0.4)
                label:SetTextColor(unpack(Colors.textMuted))
            else
                box:SetBackdropColor(Colors.checkOn[1] * 0.3, Colors.checkOn[2] * 0.3, Colors.checkOn[3] * 0.3, 1)
                box:SetBackdropBorderColor(unpack(Colors.checkOn))
                check:Show()
                check:SetAlpha(1)
                label:SetTextColor(unpack(Colors.text))
            end
        else
            if disabled then
                box:SetBackdropColor(0.05, 0.05, 0.05, 1)
                box:SetBackdropBorderColor(unpack(Colors.checkDisabled))
                check:Hide()
                label:SetTextColor(unpack(Colors.textMuted))
            else
                box:SetBackdropColor(0.1, 0.1, 0.1, 1)
                box:SetBackdropBorderColor(unpack(Colors.checkOff))
                check:Hide()
                label:SetTextColor(unpack(Colors.text))
            end
        end
    end

    local function OnClick()
        if holder._isDisabled then return end
        local newVal = not config.get()
        config.set(newVal)
        UpdateVisual()
        if config.onChange then config.onChange(newVal) end
    end

    box:EnableMouse(true)
    box:SetScript("OnMouseUp", OnClick)

    holder:EnableMouse(true)
    holder:SetScript("OnMouseUp", OnClick)

    if config.tooltip then
        holder:SetScript("OnEnter", function(self)
            ShowTooltip(self, config.label, config.tooltip)
        end)
        holder:SetScript("OnLeave", HideTooltip)
    end

    UpdateVisual()
    RegisterRefreshable(holder, UpdateVisual)

    holder.box = box
    holder.check = check
    holder.label = label
    holder.SetDisabled = function(self, disabled)
        self._isDisabled = disabled
        UpdateVisual()
    end
    return holder
end

-- --------------------------------------------------------------------------
-- Slider
-- --------------------------------------------------------------------------
local function CreateSlider(parent, config)
    local TRACK_HEIGHT = 4
    local THUMB_WIDTH = 10
    local THUMB_HEIGHT = 16
    local sliderWidth = config.sliderWidth or 140
    local labelWidth = config.labelWidth or 120
    local step = config.step or 1
    local suffix = config.suffix or ""

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(labelWidth + sliderWidth + 60, 22)

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText(config.label)
    label:SetTextColor(unpack(Colors.text))

    local trackBg = CreateFrame("Frame", nil, holder, "BackdropTemplate")
    trackBg:SetPoint("LEFT", label, "RIGHT", 4, 0)
    trackBg:SetSize(sliderWidth, TRACK_HEIGHT)
    trackBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    trackBg:SetBackdropColor(unpack(Colors.sliderTrack))
    trackBg:SetBackdropBorderColor(unpack(Colors.sliderTrack))

    local trackFill = trackBg:CreateTexture(nil, "ARTWORK")
    trackFill:SetPoint("LEFT")
    trackFill:SetHeight(TRACK_HEIGHT)
    trackFill:SetColorTexture(unpack(Colors.sliderFill))

    local thumb = CreateFrame("Frame", nil, trackBg, "BackdropTemplate")
    thumb:SetSize(THUMB_WIDTH, THUMB_HEIGHT)
    thumb:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    thumb:SetBackdropColor(unpack(Colors.sliderThumb))
    thumb:SetBackdropBorderColor(unpack(Colors.sliderThumb))

    local valueText = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", trackBg, "RIGHT", 6, 0)
    valueText:SetTextColor(unpack(Colors.textDim))

    local currentValue = config.get()
    local isDragging = false

    local function FormatValue(val)
        if config.formatValue then
            return config.formatValue(val)
        end
        if step < 1 then
            return string.format("%.1f", val) .. suffix
        end
        return math.floor(val) .. suffix
    end

    local function SetValue(val)
        val = math.max(config.min, math.min(config.max, val))
        val = math.floor(val / step + 0.5) * step
        currentValue = val
        config.set(val)

        local pct = (val - config.min) / math.max(config.max - config.min, 0.001)
        local trackW = trackBg:GetWidth()
        trackFill:SetWidth(math.max(1, pct * trackW))
        thumb:ClearAllPoints()
        thumb:SetPoint("CENTER", trackBg, "LEFT", pct * trackW, 0)
        valueText:SetText(FormatValue(val))
    end

    local function UpdateFromMouse(x)
        local left = trackBg:GetLeft()
        local width = trackBg:GetWidth()
        if not left or width == 0 then return end
        local pct = math.max(0, math.min(1, (x - left) / width))
        local val = config.min + pct * (config.max - config.min)
        SetValue(val)
    end

    thumb:EnableMouse(true)
    thumb:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then isDragging = true end
    end)
    thumb:SetScript("OnMouseUp", function() isDragging = false end)

    trackBg:EnableMouse(true)
    trackBg:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            local x = GetCursorPosition() / UIParent:GetEffectiveScale()
            UpdateFromMouse(x)
            isDragging = true
        end
    end)
    trackBg:SetScript("OnMouseUp", function() isDragging = false end)

    holder:SetScript("OnUpdate", function()
        if isDragging then
            local x = GetCursorPosition() / UIParent:GetEffectiveScale()
            UpdateFromMouse(x)
        end
        if not IsMouseButtonDown("LeftButton") then
            isDragging = false
        end
    end)

    trackBg:EnableMouseWheel(true)
    trackBg:SetScript("OnMouseWheel", function(self, delta)
        SetValue(currentValue + delta * step)
    end)
    thumb:EnableMouseWheel(true)
    thumb:SetScript("OnMouseWheel", function(self, delta)
        SetValue(currentValue + delta * step)
    end)

    thumb:SetScript("OnEnter", function()
        thumb:SetBackdropColor(unpack(Colors.sliderThumbH))
        thumb:SetBackdropBorderColor(unpack(Colors.sliderThumbH))
    end)
    thumb:SetScript("OnLeave", function()
        if not isDragging then
            thumb:SetBackdropColor(unpack(Colors.sliderThumb))
            thumb:SetBackdropBorderColor(unpack(Colors.sliderThumb))
        end
    end)

    if config.tooltip then
        holder:EnableMouse(true)
        label:EnableMouse(false)
        holder:SetScript("OnEnter", function(self)
            ShowTooltip(self, config.label, config.tooltip)
        end)
        holder:SetScript("OnLeave", HideTooltip)
    end

    SetValue(currentValue)
    RegisterRefreshable(holder, function() SetValue(config.get()) end)

    holder.SetValue = SetValue
    holder.GetValue = function() return currentValue end
    return holder
end

-- --------------------------------------------------------------------------
-- Dropdown
-- --------------------------------------------------------------------------
local function CreateDropdown(parent, config)
    local labelWidth = config.labelWidth or 120
    local dropWidth = config.dropWidth or 180
    local maxVisible = config.maxVisible or 12
    local itemHeight = 20

    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(labelWidth + dropWidth + 8, 24)

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", 0, 0)
    label:SetWidth(labelWidth)
    label:SetJustifyH("LEFT")
    label:SetText(config.label)
    label:SetTextColor(unpack(Colors.text))

    local btn = CreateFrame("Button", nil, holder, "BackdropTemplate")
    btn:SetPoint("LEFT", label, "RIGHT", 4, 0)
    btn:SetSize(dropWidth, 22)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(Colors.btnBg))
    btn:SetBackdropBorderColor(unpack(Colors.dropBorder))

    local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    btnText:SetPoint("LEFT", 6, 0)
    btnText:SetPoint("RIGHT", -18, 0)
    btnText:SetJustifyH("LEFT")
    btnText:SetTextColor(unpack(Colors.text))

    local arrow = btn:CreateTexture(nil, "OVERLAY")
    arrow:SetSize(10, 10)
    arrow:SetPoint("RIGHT", -4, 0)
    arrow:SetTexture("Interface\\Buttons\\UI-SortArrow")
    arrow:SetTexCoord(0, 1, 1, 0)

    local menuFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
    menuFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    menuFrame:SetBackdropColor(unpack(Colors.dropBg))
    menuFrame:SetBackdropBorderColor(unpack(Colors.dropBorderFoc))
    menuFrame:SetFrameStrata("TOOLTIP")
    menuFrame:SetClipsChildren(true)
    menuFrame:Hide()

    local menuItems = {}
    local isOpen = false
    local scrollOffset = 0
    local currentItems = {}

    local scrollUp = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
    scrollUp:SetSize(14, 14)
    scrollUp:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scrollUp:SetBackdropColor(unpack(Colors.btnBg))
    scrollUp:SetBackdropBorderColor(unpack(Colors.btnBorder))
    scrollUp:Hide()

    local scrollUpText = scrollUp:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scrollUpText:SetPoint("CENTER")
    scrollUpText:SetText("^")

    local scrollDown = CreateFrame("Button", nil, menuFrame, "BackdropTemplate")
    scrollDown:SetSize(14, 14)
    scrollDown:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    scrollDown:SetBackdropColor(unpack(Colors.btnBg))
    scrollDown:SetBackdropBorderColor(unpack(Colors.btnBorder))
    scrollDown:Hide()

    local scrollDownText = scrollDown:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    scrollDownText:SetPoint("CENTER")
    scrollDownText:SetText("v")

    local function CloseMenu()
        menuFrame:Hide()
        isOpen = false
        btn:SetBackdropBorderColor(unpack(Colors.dropBorder))
    end

    local function UpdateText()
        local current = config.get()
        btnText:SetText(current or "")
    end

    local function UpdateScrollButtons()
        local needsScroll = #currentItems > maxVisible
        scrollUp:SetShown(needsScroll)
        scrollDown:SetShown(needsScroll)
        if not needsScroll then return end

        scrollUp:SetEnabled(scrollOffset > 0)
        scrollDown:SetEnabled(scrollOffset < (#currentItems - maxVisible))

        if scrollOffset > 0 then
            scrollUp:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
        else
            scrollUp:SetBackdropBorderColor(unpack(Colors.btnBorder))
        end

        if scrollOffset < (#currentItems - maxVisible) then
            scrollDown:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
        else
            scrollDown:SetBackdropBorderColor(unpack(Colors.btnBorder))
        end
    end

    local function RefreshVisibleItems()
        local currentVal = config.get()
        local visibleCount = math.min(#currentItems, maxVisible)

        for i = 1, visibleCount do
            local itemIndex = scrollOffset + i
            local itemValue = currentItems[itemIndex]
            local itemBtn = menuItems[i]

            if not itemBtn then
                itemBtn = CreateFrame("Button", nil, menuFrame)
                itemBtn:SetSize(dropWidth - 22, itemHeight)
                itemBtn:SetPoint("TOPLEFT", 2, -2 - (i - 1) * itemHeight)

                local itemBg = itemBtn:CreateTexture(nil, "BACKGROUND")
                itemBg:SetAllPoints()
                itemBg:SetColorTexture(0, 0, 0, 0)
                itemBtn.itemBg = itemBg

                local itemText = itemBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
                itemText:SetPoint("LEFT", 6, 0)
                itemText:SetPoint("RIGHT", -6, 0)
                itemText:SetJustifyH("LEFT")
                itemBtn.itemText = itemText

                itemBtn:SetScript("OnEnter", function(self)
                    self.itemBg:SetColorTexture(Colors.accent[1], Colors.accent[2], Colors.accent[3], 0.15)
                end)
                itemBtn:SetScript("OnLeave", function(self)
                    self.itemBg:SetColorTexture(0, 0, 0, 0)
                end)
                itemBtn:SetScript("OnClick", function(self)
                    if not self.itemValue then return end
                    config.set(self.itemValue)
                    UpdateText()
                    CloseMenu()
                    if config.onChange then config.onChange(self.itemValue) end
                end)

                menuItems[i] = itemBtn
            end

            itemBtn.itemValue = itemValue
            itemBtn.itemText:SetText(itemValue)
            if itemValue == currentVal then
                itemBtn.itemText:SetTextColor(unpack(Colors.accent))
            else
                itemBtn.itemText:SetTextColor(unpack(Colors.text))
            end
            itemBtn:Show()
        end

        for i = visibleCount + 1, #menuItems do
            menuItems[i]:Hide()
            menuItems[i].itemValue = nil
        end

        UpdateScrollButtons()
    end

    local function SetScrollOffset(newOffset)
        local maxOffset = math.max(0, #currentItems - maxVisible)
        scrollOffset = math.max(0, math.min(maxOffset, newOffset))
        RefreshVisibleItems()
    end

    local function BuildMenu()
        currentItems = config.items() or {}
        local visibleCount = math.min(#currentItems, maxVisible)
        local menuH = visibleCount * itemHeight + 4

        menuFrame:SetSize(dropWidth, menuH)
        menuFrame:ClearAllPoints()
        menuFrame:SetPoint("TOPLEFT", btn, "BOTTOMLEFT", 0, -2)

        local selectedIndex = 1
        local currentVal = config.get()
        for i, itemValue in ipairs(currentItems) do
            if itemValue == currentVal then
                selectedIndex = i
                break
            end
        end

        local initialOffset = 0
        if #currentItems > maxVisible then
            initialOffset = math.max(0, math.min(#currentItems - maxVisible, selectedIndex - math.floor(maxVisible / 2) - 1))
        end

        scrollUp:ClearAllPoints()
        scrollUp:SetPoint("TOPRIGHT", -2, -2)
        scrollDown:ClearAllPoints()
        scrollDown:SetPoint("BOTTOMRIGHT", -2, 2)

        SetScrollOffset(initialOffset)
    end

    scrollUp:SetScript("OnClick", function()
        SetScrollOffset(scrollOffset - 1)
    end)

    scrollDown:SetScript("OnClick", function()
        SetScrollOffset(scrollOffset + 1)
    end)

    menuFrame:EnableMouseWheel(true)
    menuFrame:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then
            SetScrollOffset(scrollOffset - 1)
        elseif delta < 0 then
            SetScrollOffset(scrollOffset + 1)
        end
    end)

    btn:SetScript("OnClick", function()
        if isOpen then
            CloseMenu()
        else
            BuildMenu()
            menuFrame:Show()
            isOpen = true
            btn:SetBackdropBorderColor(unpack(Colors.dropBorderFoc))
        end
    end)

    btn:SetScript("OnEnter", function()
        if not isOpen then
            btn:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
        end
    end)
    btn:SetScript("OnLeave", function()
        if not isOpen then
            btn:SetBackdropBorderColor(unpack(Colors.dropBorder))
        end
    end)

    UpdateText()
    RegisterRefreshable(holder, UpdateText)

    if config.tooltip then
        holder:EnableMouse(true)
        holder:SetScript("OnEnter", function(self)
            ShowTooltip(self, config.label, config.tooltip)
        end)
        holder:SetScript("OnLeave", HideTooltip)
    end

    holder.btn = btn
    holder.UpdateText = UpdateText
    return holder
end

-- --------------------------------------------------------------------------
-- Section Header
-- --------------------------------------------------------------------------
local function CreateSectionHeader(parent, text)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(PANEL_WIDTH - COL_PADDING * 2, 20)

    local line = holder:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("LEFT", 0, 0)
    line:SetPoint("RIGHT", 0, 0)
    line:SetColorTexture(unpack(Colors.separator))

    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("LEFT", 0, 10)
    label:SetText(text)
    label:SetTextColor(unpack(Colors.accent))

    return holder
end

-- --------------------------------------------------------------------------
-- Info Text
-- --------------------------------------------------------------------------
local function CreateInfoText(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetWidth(PANEL_WIDTH - COL_PADDING * 2)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    label:SetTextColor(unpack(Colors.textMuted))
    return label
end

-- ============================================================================
-- AUTO-DETECT STATUS HELPERS
-- ============================================================================

local function GetSpecDisplayName()
    local specIndex = GetSpecialization()
    if not specIndex then return "No Spec" end
    local _, name = GetSpecializationInfo(specIndex)
    local _, className = UnitClass("player")
    if name and className then
        return name .. " " .. className
    end
    return name or className or "Unknown"
end

local function BuildAutoDetectText()
    DSA.UpdateAutoDetect()
    local autoTypes = DSA.GetAutoDetectedTypes()

    local specName = GetSpecDisplayName()
    local lines = {}

    -- Spec types
    local typeList = {}
    for _, info in ipairs(DISPEL_TYPE_INFO) do
        if autoTypes[info.key] then
            local r, g, b = info.color[1], info.color[2], info.color[3]
            typeList[#typeList + 1] = string.format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, info.label)
        end
    end
    if #typeList > 0 then
        lines[#lines + 1] = "|cff88ff88Spec:|r " .. table.concat(typeList, ", ") .. "  |cff888888(" .. specName .. ")|r"
    else
        lines[#lines + 1] = "|cffff8888Spec:|r No dispel abilities detected  |cff888888(" .. specName .. ")|r"
    end

    -- Racial info
    if DSA.HasRacialDispel() then
        local raceName = UnitRace("player") or "Unknown"
        lines[#lines + 1] = "|cff88ff88Racial:|r Available  |cff888888(" .. raceName .. " — self only, separate sound)|r"
    end

    return table.concat(lines, "\n")
end

-- ============================================================================
-- MAIN PANEL CREATION
-- ============================================================================

local panel = nil

local function CreateOptionsPanel()
    if panel then return panel end

    local db = DSA.db

    -- Main frame
    panel = CreateFrame("Frame", "NT_DispelSoundsOptions", UIParent, "BackdropTemplate")
    panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
    panel:SetPoint("CENTER")
    panel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    panel:SetBackdropColor(unpack(Colors.panelBg))
    panel:SetBackdropBorderColor(unpack(Colors.panelBorder))
    panel:SetFrameStrata("DIALOG")
    panel:SetMovable(true)
    panel:EnableMouse(true)
    panel:SetClampedToScreen(true)
    panel:RegisterForDrag("LeftButton")
    panel:SetScript("OnDragStart", panel.StartMoving)
    panel:SetScript("OnDragStop", panel.StopMovingOrSizing)

    -- Close on Escape
    tinsert(UISpecialFrames, "NT_DispelSoundsOptions")

    -- ========================================================================
    -- HEADER
    -- ========================================================================
    local header = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    header:SetHeight(HEADER_HEIGHT)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(unpack(Colors.headerBg))

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff00ccffNT_DispelSounds|r")
    title:SetTextColor(unpack(Colors.text))

    local version = header:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, 0)
    version:SetText("v" .. ADDON_VERSION)
    version:SetTextColor(unpack(Colors.textMuted))

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(HEADER_HEIGHT - 8, HEADER_HEIGHT - 8)
    closeBtn:SetPoint("RIGHT", -6, 0)

    local closeTex = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeTex:SetPoint("CENTER")
    closeTex:SetText("x")
    closeTex:SetTextColor(unpack(Colors.textDim))

    closeBtn:SetScript("OnEnter", function()
        closeTex:SetTextColor(1, 0.3, 0.3, 1)
    end)
    closeBtn:SetScript("OnLeave", function()
        closeTex:SetTextColor(unpack(Colors.textDim))
    end)
    closeBtn:SetScript("OnClick", function()
        panel:Hide()
    end)

    -- ========================================================================
    -- SCROLLABLE CONTENT
    -- ========================================================================
    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", COL_PADDING, -HEADER_HEIGHT - 12)
    scrollFrame:SetPoint("BOTTOMRIGHT", -COL_PADDING - 22, FOOTER_HEIGHT)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(PANEL_WIDTH - COL_PADDING * 2)
    scrollFrame:SetScrollChild(content)

    local yOffset = -COL_PADDING

    local function PlaceWidget(widget, extraGap)
        extraGap = extraGap or 0
        widget:SetParent(content)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset - extraGap)
        local h = widget.GetHeight and widget:GetHeight() or 22
        yOffset = yOffset - extraGap - h - COMPONENT_GAP
    end

    local function PlaceFontString(fs, extraGap)
        extraGap = extraGap or 0
        yOffset = yOffset - extraGap
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset)
        local h = fs:GetStringHeight() or 12
        yOffset = yOffset - h - COMPONENT_GAP
    end

    -- ========================================================================
    -- SECTION: General
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "General"), 0)

    PlaceWidget(CreateCheckbox(content, {
        label = "Enable Dispel Sound Alert",
        get = function() return db.enabled end,
        set = function(v) db.enabled = v end,
        tooltip = "Master toggle for the addon.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "Enable for Party frames",
        get = function() return db.enableParty end,
        set = function(v) db.enableParty = v end,
        tooltip = "Play sounds when dispellable debuffs appear on party members.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "Enable for Raid frames",
        get = function() return db.enableRaid end,
        set = function(v) db.enableRaid = v end,
        tooltip = "Play sounds when dispellable debuffs appear on raid members.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "Enable for Player",
        get = function() return db.enablePlayer end,
        set = function(v) db.enablePlayer = v end,
        tooltip = "Play sounds when dispellable debuffs appear on yourself. Includes racial self-dispel alerts.",
    }))

    -- ========================================================================
    -- SECTION: Dispel Detection
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "Dispel Detection"), SECTION_GAP)

    PlaceWidget(CreateDropdown(content, {
        label = "Detection Mode",
        get = function()
            return db.filterMode == "auto" and "Dispellable by Me" or "All Dispellable"
        end,
        set = function(v)
            db.filterMode = (v == "Dispellable by Me") and "auto" or "all"
        end,
        items = function() return { "Dispellable by Me", "All Dispellable" } end,
        onChange = function()
            RefreshAll()
        end,
        tooltip = "Dispellable by Me: alerts only for debuffs your class/spec can remove. Also alerts for racial self-dispel on the player unit.\n\nAll Dispellable: alerts for any dispellable debuff on any group member.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "Only alert when ability is ready",
        get = function() return db.onlyWhenReady end,
        set = function(v) db.onlyWhenReady = v end,
        tooltip = "Only play the alert sound when your dispel ability (or racial) is off cooldown. Ignores the GCD. Re-scans when abilities come off cooldown.",
    }))

    -- Auto-detect status display
    local autoStatusText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoStatusText:SetWidth(PANEL_WIDTH - COL_PADDING * 2)
    autoStatusText:SetJustifyH("LEFT")
    autoStatusText:SetText(BuildAutoDetectText())
    PlaceFontString(autoStatusText, 4)

    -- ========================================================================
    -- SECTION: Sound
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "Sound"), SECTION_GAP)

    PlaceWidget(CreateDropdown(content, {
        label = "Alert Sound",
        get = function() return db.soundFile or DEFAULT_SOUND_LABEL end,
        set = function(v)
            if v == DEFAULT_SOUND_LABEL then
                db.soundFile = nil
            else
                db.soundFile = v
            end
        end,
        items = GetSoundList,
        onChange = function()
            C_Timer.After(0.05, function() DSA.PlayDispelSound(true) end)
        end,
        tooltip = "Sound to play when a dispellable debuff is detected. Uses LibSharedMedia sounds.",
    }))

    PlaceWidget(CreateDropdown(content, {
        label = "Sound Channel",
        get = function() return db.soundChannel end,
        set = function(v) db.soundChannel = v end,
        items = function() return { "Master", "SFX", "Music", "Ambience", "Dialog" } end,
        tooltip = "Audio channel to play the sound on.",
    }))

    -- Test sound button
    local testBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    testBtn:SetSize(100, 24)
    testBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    testBtn:SetBackdropColor(unpack(Colors.btnBg))
    testBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))

    local testBtnText = testBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    testBtnText:SetPoint("CENTER")
    testBtnText:SetText("Test Sound")
    testBtnText:SetTextColor(unpack(Colors.text))

    testBtn:SetScript("OnEnter", function()
        testBtn:SetBackdropColor(unpack(Colors.btnBgHover))
        testBtn:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
    end)
    testBtn:SetScript("OnLeave", function()
        testBtn:SetBackdropColor(unpack(Colors.btnBg))
        testBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))
    end)
    testBtn:SetScript("OnClick", function()
        DSA.PlayDispelSound(true)
    end)

    PlaceWidget(testBtn)

    -- Racial Sound (self-dispel alert)
    PlaceWidget(CreateDropdown(content, {
        label = "Racial Alert Sound (self only)",
        get = function() return db.racialSoundFile or DEFAULT_SOUND_LABEL end,
        set = function(v)
            if v == DEFAULT_SOUND_LABEL then
                db.racialSoundFile = nil
            else
                db.racialSoundFile = v
            end
        end,
        items = GetSoundList,
        onChange = function()
            C_Timer.After(0.05, function() DSA.PlayRacialSound(true) end)
        end,
        tooltip = "Sound to play when a racial-dispellable debuff is detected on yourself (e.g. Stoneform, Fireblood). Uses the main sound if not set.",
    }))

    -- Test racial sound button
    local testRacialBtn = CreateFrame("Button", nil, content, "BackdropTemplate")
    testRacialBtn:SetSize(130, 24)
    testRacialBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    testRacialBtn:SetBackdropColor(unpack(Colors.btnBg))
    testRacialBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))

    local testRacialBtnText = testRacialBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    testRacialBtnText:SetPoint("CENTER")
    testRacialBtnText:SetText("Test Racial Sound")
    testRacialBtnText:SetTextColor(unpack(Colors.text))

    testRacialBtn:SetScript("OnEnter", function()
        testRacialBtn:SetBackdropColor(unpack(Colors.btnBgHover))
        testRacialBtn:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
    end)
    testRacialBtn:SetScript("OnLeave", function()
        testRacialBtn:SetBackdropColor(unpack(Colors.btnBg))
        testRacialBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))
    end)
    testRacialBtn:SetScript("OnClick", function()
        DSA.PlayRacialSound(true)
    end)

    PlaceWidget(testRacialBtn)

    -- ========================================================================
    -- SECTION: Timing
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "Timing"), SECTION_GAP)

    PlaceWidget(CreateSlider(content, {
        label = "Per-Unit Cooldown",
        min = 0, max = 30, step = 0.5,
        suffix = "s",
        get = function() return db.cooldownPerUnit end,
        set = function(v) db.cooldownPerUnit = v end,
        tooltip = "Minimum seconds before re-alerting for the same unit. Prevents spam when a unit has ongoing dispellable debuffs.",
    }))

    PlaceWidget(CreateSlider(content, {
        label = "Global Cooldown",
        min = 0, max = 5, step = 0.1,
        suffix = "s",
        get = function() return db.globalCooldown end,
        set = function(v) db.globalCooldown = v end,
        tooltip = "Minimum seconds between any two sounds. Prevents overlapping alerts from multiple units.",
    }))

    -- ========================================================================
    -- SECTION: Repeat
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "Repeat Alert"), SECTION_GAP)

    PlaceWidget(CreateCheckbox(content, {
        label = "Repeat sound while debuff persists",
        get = function() return db.repeatSound end,
        set = function(v)
            db.repeatSound = v
            if not v then DSA.StopAllRepeats() end
        end,
        tooltip = "Keep playing the alert sound at intervals while the dispellable debuff is still active.",
    }))

    PlaceWidget(CreateSlider(content, {
        label = "Repeat Interval",
        min = 1, max = 30, step = 0.5,
        suffix = "s",
        get = function() return db.repeatInterval end,
        set = function(v) db.repeatInterval = v end,
        tooltip = "Seconds between repeated sound plays.",
    }))

    -- ========================================================================
    -- SECTION: Debug
    -- ========================================================================
    PlaceWidget(CreateSectionHeader(content, "Debug"), SECTION_GAP)

    PlaceWidget(CreateCheckbox(content, {
        label = "Debug mode (log to chat)",
        get = function() return db.debug end,
        set = function(v) db.debug = v end,
        tooltip = "Print detailed debug info to chat: aura scanning, dispel detection, sound playback attempts, cooldown blocks. Also available via /dsa debug.",
    }))

    PlaceFontString(CreateInfoText(content,
        "|cff888888This addon scans party/raid unit auras directly using the WoW C_UnitAuras API. "
        .. "No external frame addon is required.|r"
    ), 4)

    -- ========================================================================
    -- OnShow: refresh status
    -- ========================================================================
    panel:SetScript("OnShow", function()
        autoStatusText:SetText(BuildAutoDetectText())
        RefreshAll()
    end)

    -- Set content height
    content:SetHeight(math.abs(yOffset) + COL_PADDING)

    -- ========================================================================
    -- BOTTOM BAR
    -- ========================================================================
    local bottomBar = CreateFrame("Frame", nil, panel)
    bottomBar:SetHeight(FOOTER_HEIGHT)
    bottomBar:SetPoint("BOTTOMLEFT", 0, 0)
    bottomBar:SetPoint("BOTTOMRIGHT", 0, 0)

    local sep = bottomBar:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT", 8, 0)
    sep:SetPoint("TOPRIGHT", -8, 0)
    sep:SetColorTexture(unpack(Colors.separator))

    local authorText = bottomBar:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    authorText:SetPoint("BOTTOM", 0, 8)
    authorText:SetText("Author: Numbtongue (Drinkstea-Draenor-EU)")
    authorText:SetTextColor(unpack(Colors.textMuted))

    -- Reset button
    local resetBtn = CreateFrame("Button", nil, bottomBar, "BackdropTemplate")
    resetBtn:SetSize(80, 24)
    resetBtn:SetPoint("LEFT", 12, -4)
    resetBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    resetBtn:SetBackdropColor(unpack(Colors.btnBg))
    resetBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))

    local resetText = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    resetText:SetPoint("CENTER")
    resetText:SetText("Defaults")
    resetText:SetTextColor(unpack(Colors.text))

    resetBtn:SetScript("OnEnter", function()
        resetBtn:SetBackdropColor(unpack(Colors.btnBgHover))
        resetBtn:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
        ShowTooltip(resetBtn, "Reset to Defaults", "Reset all settings to their default values.")
    end)
    resetBtn:SetScript("OnLeave", function()
        resetBtn:SetBackdropColor(unpack(Colors.btnBg))
        resetBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))
        HideTooltip()
    end)
    resetBtn:SetScript("OnClick", function()
        StaticPopup_Show("DSA_RESET_CONFIRM")
    end)

    StaticPopupDialogs["DSA_RESET_CONFIRM"] = {
        text = "Reset NT_DispelSounds to default settings?",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            for k, v in pairs(DSA.DEFAULTS) do
                db[k] = v
            end
            DSA.MarkAutoDetectDirty()
            autoStatusText:SetText(BuildAutoDetectText())
            RefreshAll()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    panel:Hide()
    return panel
end

-- ============================================================================
-- TOGGLE
-- ============================================================================

function DSA:ToggleOptions()
    local p = CreateOptionsPanel()
    if p:IsShown() then
        p:Hide()
    else
        p:Show()
    end
end

-- ============================================================================
-- SETTINGS REGISTRATION (appears in Interface > AddOns)
-- ============================================================================

local function RegisterSettings()
    local category = Settings.RegisterCanvasLayoutCategory(CreateOptionsPanel(), ADDON_DISPLAY_NAME)
    category.ID = "NT_DispelSounds"
    Settings.RegisterAddOnCategory(category)
    DSA.settingsCategory = category
end

local settingsFrame = CreateFrame("Frame")
settingsFrame:RegisterEvent("PLAYER_LOGIN")
settingsFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent(event)
    C_Timer.After(0.1, function()
        local ok, err = pcall(RegisterSettings)
        if not ok then
            -- Fallback: just use slash command
        end
    end)
end)
