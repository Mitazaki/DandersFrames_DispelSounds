-- ============================================================================
-- NT_DispelSounds - Options Panel
-- ============================================================================

local addonName, DSA = ...

-- ============================================================================
-- CONSTANTS
-- ============================================================================

local PANEL_WIDTH = 580
local PANEL_HEIGHT = 620
local SIDEBAR_WIDTH = 110
local CONTENT_WIDTH = PANEL_WIDTH - SIDEBAR_WIDTH
local COL_PADDING = 16
local CONTENT_INNER = CONTENT_WIDTH - COL_PADDING * 2
local COMPONENT_GAP = 6
local SECTION_GAP = 14
local HEADER_HEIGHT = 36
local SIDEBAR_BTN_H = 32

local DEFAULT_SOUND_LABEL = "(Default: Raid Warning)"
local NONE_SOUND_LABEL = "None"
local ADDON_DISPLAY_NAME = DSA.ADDON_DISPLAY_NAME or "NT_DispelSounds"
local ADDON_VERSION = DSA.ADDON_VERSION or "0.9.0b"

-- ============================================================================
-- COLORS
-- ============================================================================

local Colors = {
    panelBg       = { 0.08, 0.08, 0.08, 0.95 },
    panelBorder   = { 0.25, 0.25, 0.25, 1 },
    headerBg      = { 0.12, 0.12, 0.12, 1 },
    sidebarBg     = { 0.06, 0.06, 0.06, 1 },
    sidebarBtnH   = { 0.15, 0.15, 0.15, 1 },
    sidebarBtnA   = { 0.12, 0.12, 0.12, 1 },
    accent        = { 1, 0.82, 0, 1 },
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
    link          = { 0.3, 0.7, 1.0, 1 },
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
    if desc then GameTooltip:AddLine(desc, 0.7, 0.7, 0.7, true) end
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

-- ============================================================================
-- REFRESHABLE SYSTEM
-- ============================================================================

local refreshableComponents = {}

local function RegisterRefreshable(widget, refreshFn)
    refreshableComponents[#refreshableComponents + 1] = { widget = widget, refresh = refreshFn }
end

local function RefreshAll()
    for _, entry in ipairs(refreshableComponents) do
        if entry.widget and entry.refresh then entry.refresh() end
    end
end

-- ============================================================================
-- UI COMPONENT FACTORIES
-- ============================================================================

-- --------------------------------------------------------------------------
-- Checkbox
-- --------------------------------------------------------------------------
local function CreateCheckbox(parent, config)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetSize(config.width or CONTENT_INNER, 22)

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
        if config.formatValue then return config.formatValue(val) end
        if step < 1 then return string.format("%.1f", val) .. suffix end
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
        if not IsMouseButtonDown("LeftButton") then isDragging = false end
    end)

    trackBg:EnableMouseWheel(true)
    trackBg:SetScript("OnMouseWheel", function(self, delta) SetValue(currentValue + delta * step) end)
    thumb:EnableMouseWheel(true)
    thumb:SetScript("OnMouseWheel", function(self, delta) SetValue(currentValue + delta * step) end)

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
        holder:SetScript("OnEnter", function(self) ShowTooltip(self, config.label, config.tooltip) end)
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
            if itemValue == currentVal then selectedIndex = i; break end
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

    scrollUp:SetScript("OnClick", function() SetScrollOffset(scrollOffset - 1) end)
    scrollDown:SetScript("OnClick", function() SetScrollOffset(scrollOffset + 1) end)
    menuFrame:EnableMouseWheel(true)
    menuFrame:SetScript("OnMouseWheel", function(_, delta)
        SetScrollOffset(scrollOffset + (delta > 0 and -1 or 1))
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
        if not isOpen then btn:SetBackdropBorderColor(unpack(Colors.btnBorderHov)) end
    end)
    btn:SetScript("OnLeave", function()
        if not isOpen then btn:SetBackdropBorderColor(unpack(Colors.dropBorder)) end
    end)

    UpdateText()
    RegisterRefreshable(holder, UpdateText)

    if config.tooltip then
        holder:EnableMouse(true)
        holder:SetScript("OnEnter", function(self) ShowTooltip(self, config.label, config.tooltip) end)
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
    holder:SetSize(CONTENT_INNER, 28)
    local label = holder:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    label:SetPoint("BOTTOMLEFT", 0, 10)
    label:SetText(text)
    label:SetTextColor(unpack(Colors.accent))
    local line = holder:CreateTexture(nil, "ARTWORK")
    line:SetHeight(1)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetPoint("BOTTOMRIGHT", 0, 0)
    line:SetColorTexture(unpack(Colors.separator))
    return holder
end

-- --------------------------------------------------------------------------
-- Info Text
-- --------------------------------------------------------------------------
local function CreateInfoText(parent, text)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetWidth(CONTENT_INNER)
    label:SetJustifyH("LEFT")
    label:SetText(text)
    label:SetTextColor(unpack(Colors.textMuted))
    return label
end

-- --------------------------------------------------------------------------
-- Action Button
-- --------------------------------------------------------------------------
local function CreateActionButton(parent, config)
    local w = config.width or 120
    local h = config.height or 24
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w, h)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    btn:SetBackdropColor(unpack(Colors.btnBg))
    btn:SetBackdropBorderColor(unpack(Colors.btnBorder))
    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER")
    label:SetText(config.label)
    label:SetTextColor(unpack(Colors.text))
    btn:SetScript("OnEnter", function()
        btn:SetBackdropColor(unpack(Colors.btnBgHover))
        btn:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
        if config.tooltip then ShowTooltip(btn, config.label, config.tooltip) end
    end)
    btn:SetScript("OnLeave", function()
        btn:SetBackdropColor(unpack(Colors.btnBg))
        btn:SetBackdropBorderColor(unpack(Colors.btnBorder))
        HideTooltip()
    end)
    if config.onClick then btn:SetScript("OnClick", config.onClick) end
    btn.label = label
    return btn
end

-- ============================================================================
-- COPY URL DIALOG
-- ============================================================================

local copyDialog = nil

local function ShowCopyDialog(title, url)
    if not copyDialog then
        local f = CreateFrame("Frame", "DSA_CopyDialog", UIParent, "BackdropTemplate")
        f:SetSize(420, 110)
        f:SetPoint("CENTER", 0, 100)
        f:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        f:SetBackdropBorderColor(unpack(Colors.accent))
        f:SetFrameStrata("FULLSCREEN_DIALOG")
        f:EnableMouse(true)
        f:SetMovable(true)
        f:RegisterForDrag("LeftButton")
        f:SetScript("OnDragStart", f.StartMoving)
        f:SetScript("OnDragStop", f.StopMovingOrSizing)

        tinsert(UISpecialFrames, "DSA_CopyDialog")

        local titleFs = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        titleFs:SetPoint("TOPLEFT", 12, -12)
        titleFs:SetTextColor(unpack(Colors.accent))
        f.title = titleFs

        local closeBtn = CreateFrame("Button", nil, f)
        closeBtn:SetSize(24, 24)
        closeBtn:SetPoint("TOPRIGHT", -4, -4)
        local closeTex = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        closeTex:SetPoint("CENTER")
        closeTex:SetText("x")
        closeTex:SetTextColor(unpack(Colors.textDim))
        closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3, 1) end)
        closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(unpack(Colors.textDim)) end)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        local editBox = CreateFrame("EditBox", "DSA_CopyDialogEditBox", f, "BackdropTemplate")
        editBox:SetSize(396, 24)
        editBox:SetPoint("TOP", 0, -40)
        editBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8x8",
            edgeFile = "Interface\\Buttons\\WHITE8x8",
            edgeSize = 1,
        })
        editBox:SetBackdropColor(0.12, 0.12, 0.12, 1)
        editBox:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetAutoFocus(false)
        editBox:SetScript("OnEscapePressed", function() f:Hide() end)
        editBox:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        f.editBox = editBox

        local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        hint:SetPoint("BOTTOM", 0, 10)
        hint:SetText("|cff888888Press Ctrl+C to copy, then Escape to close|r")

        copyDialog = f
    end

    copyDialog.title:SetText(title)
    copyDialog.editBox:SetText(url)
    copyDialog:Show()
    copyDialog.editBox:SetFocus()
    copyDialog.editBox:HighlightText()
end

-- ============================================================================
-- HELPER: BuildModeInfoText
-- ============================================================================

local function BuildModeInfoText()
    if DSA.db.filterMode == "auto" then
        return "|cff88ff88Dispellable by Me:|r Uses Blizzard's RAID_PLAYER_DISPELLABLE filter to detect debuffs your current spec can remove."
    else
        return "|cff88ff88All Dispellable:|r Alerts for any debuff with a dispel type (Magic, Curse, Disease, Poison) on any group member."
    end
end

-- ============================================================================
-- HELPER: Scrollable Page Frame
-- ============================================================================

local function CreateScrollablePage(parent)
    local page = CreateFrame("Frame", nil, parent)
    page:SetAllPoints()
    page:Hide()

    local scrollFrame = CreateFrame("ScrollFrame", nil, page, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", COL_PADDING, -COL_PADDING)
    scrollFrame:SetPoint("BOTTOMRIGHT", -COL_PADDING - 22, 8)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(CONTENT_INNER)
    scrollFrame:SetScrollChild(content)

    page.scrollFrame = scrollFrame
    page.content = content

    local yOffset = { value = 0 }

    page.PlaceWidget = function(widget, extraGap)
        extraGap = extraGap or 0
        widget:SetParent(content)
        widget:ClearAllPoints()
        widget:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset.value - extraGap)
        local h = widget.GetHeight and widget:GetHeight() or 22
        yOffset.value = yOffset.value - extraGap - h - COMPONENT_GAP
    end

    page.PlaceFontString = function(fs, extraGap)
        extraGap = extraGap or 0
        yOffset.value = yOffset.value - extraGap
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", 0, yOffset.value)
        local h = fs:GetStringHeight() or 12
        yOffset.value = yOffset.value - h - COMPONENT_GAP
    end

    page.FinalizeHeight = function()
        content:SetHeight(math.abs(yOffset.value) + COL_PADDING)
    end

    return page
end

-- ============================================================================
-- PAGE: Options
-- ============================================================================

local function BuildOptionsPage(contentArea)
    local page = CreateScrollablePage(contentArea)
    local content = page.content
    local PlaceWidget = page.PlaceWidget
    local PlaceFontString = page.PlaceFontString

    -- ---- General ----
    PlaceWidget(CreateSectionHeader(content, "General"), 0)

    PlaceWidget(CreateCheckbox(content, {
        label = "Enable Dispel Sound Alert",
        get = function() return DSA.db.enabled end,
        set = function(v) DSA.db.enabled = v end,
        tooltip = "Master toggle for the addon.",
    }))

    -- ---- Role Filter ----
    PlaceWidget(CreateSectionHeader(content, "Role Filter"), SECTION_GAP)

    PlaceWidget(CreateCheckbox(content, {
        label = "Healer",
        get = function() return DSA.db.enableRoleHealer end,
        set = function(v) DSA.db.enableRoleHealer = v end,
        tooltip = "Enable alerts when you are playing a Healer spec. Uncheck to disable all alerts while healing.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "DPS",
        get = function() return DSA.db.enableRoleDPS end,
        set = function(v) DSA.db.enableRoleDPS = v end,
        tooltip = "Enable alerts when you are playing a DPS spec. Uncheck to disable all alerts while in a DPS spec.",
    }))

    PlaceWidget(CreateCheckbox(content, {
        label = "Tank",
        get = function() return DSA.db.enableRoleTank end,
        set = function(v) DSA.db.enableRoleTank = v end,
        tooltip = "Enable alerts when you are playing a Tank spec. Uncheck to disable all alerts while tanking.",
    }))

    -- ---- Dispel Detection ----
    PlaceWidget(CreateSectionHeader(content, "Dispel Detection"), SECTION_GAP)

    local autoStatusText -- forward declaration for closure
    PlaceWidget(CreateDropdown(content, {
        label = "Detection Mode",
        get = function()
            return DSA.db.filterMode == "auto" and "Dispellable by Me" or "All Dispellable"
        end,
        set = function(v)
            DSA.db.filterMode = (v == "Dispellable by Me") and "auto" or "all"
        end,
        items = function() return { "Dispellable by Me", "All Dispellable" } end,
        onChange = function()
            if autoStatusText then autoStatusText:SetText(BuildModeInfoText()) end
            RefreshAll()
        end,
        tooltip = "Dispellable by Me: alerts only for debuffs your class/spec can remove.\n\nAll Dispellable: alerts for any dispellable debuff on any group member.",
    }))

    autoStatusText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    autoStatusText:SetWidth(CONTENT_INNER)
    autoStatusText:SetJustifyH("LEFT")
    autoStatusText:SetText(BuildModeInfoText())
    PlaceFontString(autoStatusText, 4)

    -- ---- Sound ----
    PlaceWidget(CreateSectionHeader(content, "Sound"), SECTION_GAP)

    PlaceWidget(CreateDropdown(content, {
        label = "Alert Sound",
        get = function() return DSA.db.soundFile or DEFAULT_SOUND_LABEL end,
        set = function(v)
            if v == DEFAULT_SOUND_LABEL then DSA.db.soundFile = nil else DSA.db.soundFile = v end
        end,
        items = GetSoundList,
        onChange = function()
            C_Timer.After(0.05, function() DSA.PlayDispelSound(true) end)
        end,
        tooltip = "Sound to play when a dispellable debuff is detected. Uses LibSharedMedia sounds.",
    }))

    PlaceWidget(CreateDropdown(content, {
        label = "Sound Channel",
        get = function() return DSA.db.soundChannel end,
        set = function(v) DSA.db.soundChannel = v end,
        items = function() return { "Master", "SFX", "Music", "Ambience", "Dialog" } end,
        tooltip = "Audio channel to play the sound on.",
    }))

    PlaceWidget(CreateActionButton(content, {
        label = "Test Sound",
        width = 100,
        onClick = function() DSA.PlayDispelSound(true) end,
    }))

    -- ---- Timing ----
    PlaceWidget(CreateSectionHeader(content, "Timing"), SECTION_GAP)

    PlaceWidget(CreateSlider(content, {
        label = "Per-Unit Cooldown",
        min = 0, max = 30, step = 0.5, suffix = "s",
        get = function() return DSA.db.cooldownPerUnit end,
        set = function(v) DSA.db.cooldownPerUnit = v end,
        tooltip = "Minimum seconds before re-alerting for the same unit.",
    }))

    PlaceWidget(CreateSlider(content, {
        label = "Global Cooldown",
        min = 0, max = 10, step = 0.1, suffix = "s",
        get = function() return DSA.db.globalCooldown end,
        set = function(v) DSA.db.globalCooldown = v end,
        tooltip = "Minimum seconds between any two sounds.",
    }))

    -- ---- Repeat Alert ----
    PlaceWidget(CreateSectionHeader(content, "Repeat Alert"), SECTION_GAP)

    PlaceWidget(CreateCheckbox(content, {
        label = "Repeat sound while debuff persists",
        get = function() return DSA.db.repeatSound end,
        set = function(v)
            DSA.db.repeatSound = v
            if not v then DSA.StopAllRepeats() end
        end,
        tooltip = "Keep playing the alert sound at intervals while the dispellable debuff is still active.",
    }))

    PlaceWidget(CreateSlider(content, {
        label = "Repeat Interval",
        min = 1, max = 30, step = 0.5, suffix = "s",
        get = function() return DSA.db.repeatInterval end,
        set = function(v) DSA.db.repeatInterval = v end,
        tooltip = "Seconds between repeated sound plays.",
    }))

    -- ---- Debug ----
    PlaceWidget(CreateSectionHeader(content, "Debug"), SECTION_GAP)

    PlaceWidget(CreateCheckbox(content, {
        label = "Debug mode (log to chat)",
        get = function() return DSA.db.debug end,
        set = function(v) DSA.db.debug = v end,
        tooltip = "Print detailed debug info to chat. Also available via /dsa debug.",
    }))

    PlaceFontString(CreateInfoText(content,
        "|cff888888This addon scans party/raid unit auras directly using the WoW "
        .. "C_UnitAuras API. No external frame addon is required.|r"
    ), 4)

    -- ---- Defaults button ----
    PlaceWidget(CreateSectionHeader(content, ""), SECTION_GAP)

    StaticPopupDialogs["DSA_RESET_CONFIRM"] = {
        text = "Reset NT_DispelSounds to default settings?",
        button1 = "Reset",
        button2 = "Cancel",
        OnAccept = function()
            local profile = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
            for k, v in pairs(DSA.DEFAULTS) do
                DSA.db[k] = v
            end
            if autoStatusText then autoStatusText:SetText(BuildModeInfoText()) end
            RefreshAll()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    PlaceWidget(CreateActionButton(content, {
        label = "Reset to Defaults",
        width = 130,
        tooltip = "Reset all settings in the active profile to their default values.",
        onClick = function() StaticPopup_Show("DSA_RESET_CONFIRM") end,
    }))

    page.FinalizeHeight()

    page.Refresh = function()
        if autoStatusText then autoStatusText:SetText(BuildModeInfoText()) end
        RefreshAll()
    end

    return page
end

-- ============================================================================
-- PAGE: Changelog
-- ============================================================================

local function BuildChangelogPage(contentArea)
    local page = CreateScrollablePage(contentArea)
    local content = page.content

    local text = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("TOPLEFT", 0, 0)
    text:SetWidth(CONTENT_INNER)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)

    local changelogText = DSA.CHANGELOG_TEXT or "|cff888888No changelog data found.\nCreate ChangelogData.lua to add entries.|r"
    text:SetText(changelogText)

    content:SetHeight(text:GetStringHeight() + COL_PADDING * 2)

    page.Refresh = function()
        local t = DSA.CHANGELOG_TEXT or "|cff888888No changelog data found.|r"
        text:SetText(t)
        content:SetHeight(text:GetStringHeight() + COL_PADDING * 2)
    end

    return page
end

-- ============================================================================
-- PAGE: Profiles
-- ============================================================================

local function BuildProfilesPage(contentArea)
    local page = CreateScrollablePage(contentArea)
    local content = page.content
    local PlaceWidget = page.PlaceWidget
    local PlaceFontString = page.PlaceFontString

    PlaceWidget(CreateSectionHeader(content, "Active Profile"), 0)

    local activeLabel = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    activeLabel:SetWidth(CONTENT_INNER)
    activeLabel:SetJustifyH("LEFT")
    local function UpdateActiveLabel()
        local name = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
        activeLabel:SetText("|cffffd100" .. name .. "|r")
    end
    UpdateActiveLabel()
    PlaceFontString(activeLabel, 4)

    PlaceWidget(CreateSectionHeader(content, "Switch Profile"), SECTION_GAP)

    -- Dropdown to switch profiles (forward-declare for refresh)
    local profileDropdown
    profileDropdown = CreateDropdown(content, {
        label = "Profile",
        labelWidth = 60,
        dropWidth = 200,
        get = function()
            return DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
        end,
        set = function(v)
            if DSA.SwitchProfile then
                DSA.SwitchProfile(v)
                UpdateActiveLabel()
                RefreshAll()
            end
        end,
        items = function()
            return DSA.GetProfileList and DSA.GetProfileList() or { "Default" }
        end,
        onChange = function()
            UpdateActiveLabel()
            if profileDropdown and profileDropdown.UpdateText then
                profileDropdown.UpdateText()
            end
        end,
    })
    PlaceWidget(profileDropdown)

    -- ---- Manage ----
    PlaceWidget(CreateSectionHeader(content, "Manage"), SECTION_GAP)

    -- New Profile
    StaticPopupDialogs["DSA_NEW_PROFILE"] = {
        text = "Enter a name for the new profile:",
        button1 = "Create",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            if DSA.CreateProfile and DSA.CreateProfile(name) then
                UpdateActiveLabel()
                RefreshAll()
            else
                print("|cff00ccffDSA:|r Could not create profile (name empty or already exists).")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = self:GetText()
            if DSA.CreateProfile and DSA.CreateProfile(name) then
                UpdateActiveLabel()
                RefreshAll()
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    PlaceWidget(CreateActionButton(content, {
        label = "New Profile",
        width = 130,
        tooltip = "Create a new profile with default settings.",
        onClick = function() StaticPopup_Show("DSA_NEW_PROFILE") end,
    }))

    -- Copy Current
    StaticPopupDialogs["DSA_COPY_PROFILE"] = {
        text = "Enter a name for the copied profile:",
        button1 = "Copy",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            local active = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
            if DSA.CreateProfile and DSA.CreateProfile(name, active) then
                UpdateActiveLabel()
                RefreshAll()
            else
                print("|cff00ccffDSA:|r Could not copy profile (name empty or already exists).")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = self:GetText()
            local active = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
            if DSA.CreateProfile and DSA.CreateProfile(name, active) then
                UpdateActiveLabel()
                RefreshAll()
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    PlaceWidget(CreateActionButton(content, {
        label = "Copy Current",
        width = 130,
        tooltip = "Create a new profile as a copy of the active profile.",
        onClick = function() StaticPopup_Show("DSA_COPY_PROFILE") end,
    }))

    -- Rename
    StaticPopupDialogs["DSA_RENAME_PROFILE"] = {
        text = "Enter a new name for the active profile:",
        button1 = "Rename",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local newName = self.editBox:GetText()
            local active = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
            if DSA.RenameProfile and DSA.RenameProfile(active, newName) then
                UpdateActiveLabel()
                RefreshAll()
            else
                print("|cff00ccffDSA:|r Could not rename profile (name empty or already exists).")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local newName = self:GetText()
            local active = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
            if DSA.RenameProfile and DSA.RenameProfile(active, newName) then
                UpdateActiveLabel()
                RefreshAll()
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    PlaceWidget(CreateActionButton(content, {
        label = "Rename",
        width = 130,
        tooltip = "Rename the active profile.",
        onClick = function() StaticPopup_Show("DSA_RENAME_PROFILE") end,
    }))

    -- Delete
    StaticPopupDialogs["DSA_DELETE_PROFILE"] = {
        text = "Delete a profile? (Cannot delete the active profile.)\n\nEnter the profile name to delete:",
        button1 = "Delete",
        button2 = "Cancel",
        hasEditBox = true,
        OnAccept = function(self)
            local name = self.editBox:GetText()
            if DSA.DeleteProfile and DSA.DeleteProfile(name) then
                RefreshAll()
            else
                print("|cff00ccffDSA:|r Cannot delete (active profile, not found, or name empty).")
            end
        end,
        EditBoxOnEnterPressed = function(self)
            local parent = self:GetParent()
            local name = self:GetText()
            if DSA.DeleteProfile and DSA.DeleteProfile(name) then
                RefreshAll()
            end
            parent:Hide()
        end,
        timeout = 0,
        whileDead = true,
        hideOnEscape = true,
        preferredIndex = 3,
    }

    PlaceWidget(CreateActionButton(content, {
        label = "Delete",
        width = 130,
        tooltip = "Delete a profile by name. The active profile cannot be deleted.",
        onClick = function() StaticPopup_Show("DSA_DELETE_PROFILE") end,
    }))

    -- Profile list
    PlaceWidget(CreateSectionHeader(content, "All Profiles"), SECTION_GAP)

    local profileListText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    profileListText:SetWidth(CONTENT_INNER)
    profileListText:SetJustifyH("LEFT")
    profileListText:SetSpacing(2)

    local function UpdateProfileList()
        local list = DSA.GetProfileList and DSA.GetProfileList() or { "Default" }
        local active = DSA.GetActiveProfile and DSA.GetActiveProfile() or "Default"
        local lines = {}
        for _, name in ipairs(list) do
            if name == active then
                lines[#lines + 1] = "|cffffd100> " .. name .. "|r  |cff88ff88(active)|r"
            else
                lines[#lines + 1] = "|cff888888  " .. name .. "|r"
            end
        end
        profileListText:SetText(table.concat(lines, "\n"))
    end
    UpdateProfileList()
    PlaceFontString(profileListText, 4)

    page.FinalizeHeight()

    page.Refresh = function()
        UpdateActiveLabel()
        UpdateProfileList()
    end

    return page
end

-- ============================================================================
-- PAGE: Author
-- ============================================================================

local function BuildAuthorPage(contentArea)
    local page = CreateScrollablePage(contentArea)
    local content = page.content
    local PlaceWidget = page.PlaceWidget
    local PlaceFontString = page.PlaceFontString

    PlaceWidget(CreateSectionHeader(content, "Author"), 0)

    local nameText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    nameText:SetWidth(CONTENT_INNER)
    nameText:SetJustifyH("LEFT")
    nameText:SetText("|cffffd100Numbtongue|r")
    PlaceFontString(nameText, 4)

    local charText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    charText:SetWidth(CONTENT_INNER)
    charText:SetJustifyH("LEFT")
    charText:SetText("|cff888888Drinkstea - Draenor EU|r")
    PlaceFontString(charText, 2)

    -- ---- Links ----
    PlaceWidget(CreateSectionHeader(content, "Links"), SECTION_GAP)

    PlaceFontString(CreateInfoText(content,
        "|cff888888Click a link button to get a copyable URL.|r"
    ), 2)

    PlaceWidget(CreateActionButton(content, {
        label = "Wago",
        width = CONTENT_INNER,
        onClick = function()
            ShowCopyDialog("Wago", "https://wago.io/p/Numbtongue")
        end,
        tooltip = "Open a dialog with the Wago profile link.",
    }), 4)

    PlaceWidget(CreateActionButton(content, {
        label = "CurseForge",
        width = CONTENT_INNER,
        onClick = function()
            ShowCopyDialog("CurseForge", "https://www.curseforge.com/members/numbtongue/projects")
        end,
        tooltip = "Open a dialog with the CurseForge profile link.",
    }), 4)

    PlaceWidget(CreateActionButton(content, {
        label = "Donate - Buy Me a Coffee",
        width = CONTENT_INNER,
        onClick = function()
            ShowCopyDialog("Donate", "https://buymeacoffee.com/dlcrash")
        end,
        tooltip = "Open a dialog with the donation link.",
    }), 4)

    -- ---- About ----
    PlaceWidget(CreateSectionHeader(content, "About"), SECTION_GAP)

    local aboutText = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    aboutText:SetWidth(CONTENT_INNER)
    aboutText:SetJustifyH("LEFT")
    aboutText:SetSpacing(3)
    aboutText:SetText(
        "|cff00ccffNT_DispelSounds|r  v" .. ADDON_VERSION .. "\n\n"
        .. "Standalone dispel sound alert addon for World of Warcraft.\n"
        .. "Plays a sound when a dispellable debuff is detected on\n"
        .. "party or raid members.\n\n"
        .. "|cff888888Use |cffffff00/dsa|cff888888 to open this panel.|r"
    )
    PlaceFontString(aboutText, 4)

    page.FinalizeHeight()
    page.Refresh = function() end

    return page
end

-- ============================================================================
-- MAIN PANEL CREATION
-- ============================================================================

local panel = nil
local showPageFn = nil
local changelogPopup = nil

local function SetChangelogDismissed(dismissed)
    if not NT_DispelSoundsDB then return end
    if dismissed then
        NT_DispelSoundsDB.changelogDismissedVersion = ADDON_VERSION
    else
        NT_DispelSoundsDB.changelogDismissedVersion = nil
    end
end

local function CreateChangelogPopup()
    if changelogPopup then return changelogPopup end

    local f = CreateFrame("Frame", "NT_DispelSoundsChangelogPopup", UIParent, "BackdropTemplate")
    f:SetSize(420, 200)
    f:SetPoint("CENTER", 0, 60)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
    f:SetBackdropBorderColor(unpack(Colors.accent))
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    tinsert(UISpecialFrames, "NT_DispelSoundsChangelogPopup")

    local header = CreateFrame("Frame", nil, f, "BackdropTemplate")
    header:SetHeight(34)
    header:SetPoint("TOPLEFT", 0, 0)
    header:SetPoint("TOPRIGHT", 0, 0)
    header:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    header:SetBackdropColor(unpack(Colors.headerBg))

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", 12, 0)
    title:SetText("|cff00ccffNT_DispelSounds|r  |cff888888v" .. ADDON_VERSION .. "|r")

    local closeBtn = CreateFrame("Button", nil, header)
    closeBtn:SetSize(24, 24)
    closeBtn:SetPoint("RIGHT", -6, 0)
    local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    closeText:SetPoint("CENTER")
    closeText:SetText("x")
    closeText:SetTextColor(unpack(Colors.textDim))

    local body = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    body:SetPoint("TOPLEFT", 16, -48)
    body:SetPoint("TOPRIGHT", -16, -48)
    body:SetJustifyH("LEFT")
    body:SetText("|cffffd100What's new in v" .. ADDON_VERSION .. "|r\n\nReview the latest changes and updates in the changelog.")

    local dismissed = false

    local cbBox = CreateFrame("Frame", nil, f, "BackdropTemplate")
    cbBox:SetSize(16, 16)
    cbBox:SetPoint("BOTTOMLEFT", 16, 18)
    cbBox:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })

    local cbCheck = cbBox:CreateTexture(nil, "OVERLAY")
    cbCheck:SetSize(12, 12)
    cbCheck:SetPoint("CENTER")
    cbCheck:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")

    local cbLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    cbLabel:SetPoint("LEFT", cbBox, "RIGHT", 6, 0)
    cbLabel:SetText("Don't show again until next update")
    cbLabel:SetTextColor(unpack(Colors.textDim))

    local function UpdateCheckbox()
        if dismissed then
            cbBox:SetBackdropColor(Colors.checkOn[1] * 0.3, Colors.checkOn[2] * 0.3, Colors.checkOn[3] * 0.3, 1)
            cbBox:SetBackdropBorderColor(unpack(Colors.checkOn))
            cbCheck:Show()
        else
            cbBox:SetBackdropColor(0.1, 0.1, 0.1, 1)
            cbBox:SetBackdropBorderColor(unpack(Colors.checkOff))
            cbCheck:Hide()
        end
    end

    local function ToggleDismiss()
        dismissed = not dismissed
        UpdateCheckbox()
    end

    cbBox:EnableMouse(true)
    cbBox:SetScript("OnMouseUp", ToggleDismiss)

    local openBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    openBtn:SetSize(140, 28)
    openBtn:SetPoint("BOTTOMRIGHT", -16, 16)
    openBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    openBtn:SetBackdropColor(unpack(Colors.btnBg))
    openBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))
    local openText = openBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    openText:SetPoint("CENTER")
    openText:SetText("Open Changelog")

    local laterBtn = CreateFrame("Button", nil, f, "BackdropTemplate")
    laterBtn:SetSize(90, 28)
    laterBtn:SetPoint("RIGHT", openBtn, "LEFT", -8, 0)
    laterBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    laterBtn:SetBackdropColor(unpack(Colors.btnBg))
    laterBtn:SetBackdropBorderColor(unpack(Colors.btnBorder))
    local laterText = laterBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    laterText:SetPoint("CENTER")
    laterText:SetText("Close")

    local function ClosePopup()
        SetChangelogDismissed(dismissed)
        f:Hide()
    end

    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 0.3, 0.3, 1) end)
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(Colors.textDim)) end)
    closeBtn:SetScript("OnClick", ClosePopup)

    openBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(Colors.btnBgHover))
        self:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
    end)
    openBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(Colors.btnBg))
        self:SetBackdropBorderColor(unpack(Colors.btnBorder))
    end)
    openBtn:SetScript("OnClick", function()
        SetChangelogDismissed(dismissed)
        f:Hide()
        DSA:ShowChangelog()
    end)

    laterBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(unpack(Colors.btnBgHover))
        self:SetBackdropBorderColor(unpack(Colors.btnBorderHov))
    end)
    laterBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(unpack(Colors.btnBg))
        self:SetBackdropBorderColor(unpack(Colors.btnBorder))
    end)
    laterBtn:SetScript("OnClick", ClosePopup)

    f:SetScript("OnShow", function()
        dismissed = NT_DispelSoundsDB and NT_DispelSoundsDB.changelogDismissedVersion == ADDON_VERSION or false
        UpdateCheckbox()
    end)

    changelogPopup = f
    return f
end

local function CreateOptionsPanel()
    if panel then return panel end

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
    title:SetPoint("LEFT", SIDEBAR_WIDTH + 12, 0)
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
    closeBtn:SetScript("OnEnter", function() closeTex:SetTextColor(1, 0.3, 0.3, 1) end)
    closeBtn:SetScript("OnLeave", function() closeTex:SetTextColor(unpack(Colors.textDim)) end)
    closeBtn:SetScript("OnClick", function() panel:Hide() end)

    -- ========================================================================
    -- SIDEBAR
    -- ========================================================================
    local sidebar = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    sidebar:SetWidth(SIDEBAR_WIDTH)
    sidebar:SetPoint("TOPLEFT", 0, -HEADER_HEIGHT)
    sidebar:SetPoint("BOTTOMLEFT", 0, 0)
    sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8x8" })
    sidebar:SetBackdropColor(unpack(Colors.sidebarBg))

    -- Sidebar separator line
    local sidebarSep = sidebar:CreateTexture(nil, "ARTWORK")
    sidebarSep:SetWidth(1)
    sidebarSep:SetPoint("TOPRIGHT", 0, 0)
    sidebarSep:SetPoint("BOTTOMRIGHT", 0, 0)
    sidebarSep:SetColorTexture(unpack(Colors.separator))

    -- ========================================================================
    -- CONTENT AREA
    -- ========================================================================
    local contentArea = CreateFrame("Frame", nil, panel)
    contentArea:SetPoint("TOPLEFT", SIDEBAR_WIDTH, -HEADER_HEIGHT)
    contentArea:SetPoint("BOTTOMRIGHT", 0, 0)

    -- ========================================================================
    -- BUILD PAGES
    -- ========================================================================
    local pages = {}
    pages.options   = BuildOptionsPage(contentArea)
    pages.changelog = BuildChangelogPage(contentArea)
    pages.profiles  = BuildProfilesPage(contentArea)
    pages.author    = BuildAuthorPage(contentArea)

    -- ========================================================================
    -- SIDEBAR BUTTONS
    -- ========================================================================
    local navButtons = {}
    local activePage = nil

    local function CreateNavButton(text, pageKey, index)
        local btn = CreateFrame("Button", nil, sidebar)
        btn:SetSize(SIDEBAR_WIDTH - 1, SIDEBAR_BTN_H)
        btn:SetPoint("TOPLEFT", 0, -(index - 1) * SIDEBAR_BTN_H - 8)

        local bg = btn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0, 0, 0, 0)
        btn._bg = bg

        local accentBar = btn:CreateTexture(nil, "ARTWORK")
        accentBar:SetSize(2, SIDEBAR_BTN_H)
        accentBar:SetPoint("LEFT", 0, 0)
        accentBar:SetColorTexture(unpack(Colors.accent))
        accentBar:Hide()
        btn._accent = accentBar

        local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        label:SetPoint("LEFT", 12, 0)
        label:SetText(text)
        label:SetTextColor(unpack(Colors.textDim))
        btn._label = label
        btn._active = false

        btn.SetActive = function(self, active)
            self._active = active
            if active then
                self._accent:Show()
                self._bg:SetColorTexture(unpack(Colors.sidebarBtnA))
                self._label:SetTextColor(unpack(Colors.text))
            else
                self._accent:Hide()
                self._bg:SetColorTexture(0, 0, 0, 0)
                self._label:SetTextColor(unpack(Colors.textDim))
            end
        end

        btn:SetScript("OnEnter", function(self)
            if not self._active then
                self._bg:SetColorTexture(unpack(Colors.sidebarBtnH))
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self._active then
                self._bg:SetColorTexture(0, 0, 0, 0)
            end
        end)
        btn:SetScript("OnClick", function()
            showPageFn(pageKey)
        end)

        return btn
    end

    navButtons.options   = CreateNavButton("Options",   "options",   1)
    navButtons.changelog = CreateNavButton("Changelog", "changelog", 2)
    navButtons.profiles  = CreateNavButton("Profiles",  "profiles",  3)
    navButtons.author    = CreateNavButton("Author",    "author",    4)

    -- ========================================================================
    -- PAGE SWITCHING
    -- ========================================================================
    showPageFn = function(pageKey)
        for key, page in pairs(pages) do
            page:Hide()
            if navButtons[key] then navButtons[key]:SetActive(false) end
        end
        if pages[pageKey] then
            pages[pageKey]:Show()
            if pages[pageKey].Refresh then pages[pageKey].Refresh() end
        end
        if navButtons[pageKey] then navButtons[pageKey]:SetActive(true) end
        activePage = pageKey
    end

    -- ========================================================================
    -- OnShow: show active page (or default to options)
    -- ========================================================================
    panel:SetScript("OnShow", function()
        showPageFn(activePage or "options")
    end)

    -- Start on options page
    showPageFn("options")

    panel:Hide()
    return panel
end

-- ============================================================================
-- PUBLIC: Show Changelog
-- ============================================================================

function DSA:ShowChangelog()
    local p = CreateOptionsPanel()
    p:Show()
    if showPageFn then showPageFn("changelog") end
end

function DSA:ShowChangelogPopup()
    local popup = CreateChangelogPopup()
    popup:Show()
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
-- SETTINGS REGISTRATION (Interface > AddOns)
-- ============================================================================

-- ============================================================================
-- SETTINGS REGISTRATION (Interface > AddOns)
-- Registers a lightweight placeholder that opens the real standalone panel.
-- ============================================================================

local function RegisterSettings()
    local placeholder = CreateFrame("Frame", "NT_DispelSoundsSettingsPlaceholder", UIParent)
    placeholder:SetSize(400, 300)

    local info = placeholder:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    info:SetPoint("TOP", 0, -40)
    info:SetWidth(360)
    info:SetJustifyH("CENTER")
    info:SetText("|cff00ccffNT_DispelSounds|r v" .. ADDON_VERSION
        .. "\n\n|cffffffffClick the button below or type |cffffff00/dsa|cffffffff to open settings.|r")

    local openBtn = CreateFrame("Button", nil, placeholder, "BackdropTemplate")
    openBtn:SetSize(160, 32)
    openBtn:SetPoint("CENTER", 0, -20)
    openBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        edgeFile = "Interface\\Buttons\\WHITE8x8",
        edgeSize = 1,
    })
    openBtn:SetBackdropColor(0.15, 0.15, 0.15, 1)
    openBtn:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)

    local btnLabel = openBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    btnLabel:SetPoint("CENTER")
    btnLabel:SetText("|cffffff00Open Options|r")

    openBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.22, 0.22, 0.22, 1)
        self:SetBackdropBorderColor(1, 0.82, 0, 1)
    end)
    openBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.15, 0.15, 0.15, 1)
        self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    end)
    openBtn:SetScript("OnClick", function()
        -- Close Blizzard settings first so our panel isn't hidden behind it
        if SettingsPanel and SettingsPanel:IsShown() then
            HideUIPanel(SettingsPanel)
        end
        DSA:ToggleOptions()
    end)

    local category = Settings.RegisterCanvasLayoutCategory(placeholder, ADDON_DISPLAY_NAME)
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
