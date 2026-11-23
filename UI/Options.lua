local _, ns = ...

local UI = ns.UI
local L = ns.L
local C = UI.COLORS
local T = UI.TEXT
local W = ns.Widgets

local Options = {}
ns.Options = Options

local WIDTH, HEIGHT = 380, 560
local MARGIN = 14
local HEADER_HEIGHT, TABS_HEIGHT, BODY_GAP = 38, 26, 10
local HEADER_GLYPH_HEIGHT, HEADER_GLYPH_GAP = 16, 8
local SETTINGS_PANEL_INSET = 16
local TAB_PAD, TAB_GAP = 8, 6
local PAGE_WIDTH = WIDTH - MARGIN * 2
local CONTENT_INSET = 8
local SECTION_GAP = 10
local CONTROL_GAP = 8
local COLUMN_GAP = 12
local TOGGLE_COLUMNS = 2
local TOGGLE_HEIGHT, SLIDER_HEIGHT = 24, 34
local PICKER_HEIGHT = 128
local SPELL_ROW_HEIGHT = 26
local GROUP_HEADER_HEIGHT = 20
local REMOVE_BUTTON_SIZE = 20
local CUSTOM_INPUT_HEIGHT = 22
local CUSTOM_GAP = 4
local CLASS_TAB_GAP, CLASS_TAB_BAR_SPACE = 6, 6
local MEMBER_ROW_HEIGHT = 24
local PARTY_SLOTS = 4
local RESET_CONFIRM_SECONDS = 3
local RACIAL_TAB = "RACIAL"
local SKINS = { "flat", "blizzard" }
local ASK_CHANNELS = { "party", "whisper" }
local TALENT_COLOR = CreateColor(unpack(C.talent))
local RACE_TAG_COLOR = CreateColor(unpack(C.faint))

local window
local pages = {}
local tabButtons = {}
local currentPage
local previewStartedHere = false

local function Setting(key)
    return function() return ns.db[key] end, function(value) ns.Set(key, value) end
end

local function Track(page, widget)
    page.widgets[#page.widgets + 1] = widget
    return widget
end

local function NewToggle(page, parent, width, key, label, desc)
    local get, set = Setting(key)
    return Track(page, W.Toggle(parent, width, { label = label, desc = desc, get = get, set = set }))
end

local function AddToggle(page, key, label, desc)
    return page.stack:Add(NewToggle(page, page.content, PAGE_WIDTH, key, label, desc))
end

local function NewSlider(page, parent, width, spec)
    local get, set = Setting(spec.key)
    return Track(page, W.Slider(parent, width, { label = spec.label, min = spec.min, max = spec.max, step = 1, get = get, set = set }))
end

local function AddColumns(page, height, gap, columns, specs, create)
    local row = CreateFrame("Frame", nil, page.content)
    row:SetSize(PAGE_WIDTH, height)
    page.stack:Add(row, gap)
    local width = (PAGE_WIDTH - COLUMN_GAP * (columns - 1)) / columns
    local widgets = {}
    for index, spec in ipairs(specs) do
        widgets[index] = create(page, row, width, spec)
        widgets[index]:SetPoint("TOPLEFT", (index - 1) * (width + COLUMN_GAP), 0)
    end
    return widgets
end

local function AddSliders(page, gap, specs)
    return AddColumns(page, SLIDER_HEIGHT, gap, #specs, specs, NewSlider)
end

local function NewColumnToggle(page, row, width, spec)
    return NewToggle(page, row, width, spec.key, spec.label)
end

local function AddToggleRow(page, specs)
    return AddColumns(page, TOGGLE_HEIGHT, 0, TOGGLE_COLUMNS, specs, NewColumnToggle)
end

local function AddHeading(page, key)
    return page.stack:Add(W.Heading(page.content, PAGE_WIDTH, key), #page.stack.frames > 0 and SECTION_GAP or 0)
end

local function LocalizedItems(values, prefix)
    return function()
        local items = {}
        for i, value in ipairs(values) do
            items[i] = { value = value, text = L[prefix .. value] }
        end
        return items
    end
end

local function AddSegmented(page, key, label, values, prefix, gap)
    local get, set = Setting(key)
    return page.stack:Add(Track(page, W.Segmented(page.content, PAGE_WIDTH, {
        label = label, count = #values,
        items = LocalizedItems(values, prefix),
        get = get, set = set,
    })), gap)
end

local function NewPage(id)
    local scroll = W.Scroll(window.body)
    scroll:SetAllPoints(window.body)
    scroll:Hide()
    local page = { id = id, scroll = scroll, content = scroll.content, widgets = {}, dependents = {} }
    page.stack = W.Stack(page.content, CONTENT_INSET)
    pages[id] = page
    return page
end

local function ShowWhile(page, key, widget)
    page.dependents[#page.dependents + 1] = { key = key, widget = widget }
end

local function PaintDependents(page)
    if #page.dependents == 0 then return end
    for _, entry in ipairs(page.dependents) do
        entry.widget:SetShown(ns.db[entry.key])
    end
    page.stack:Reflow()
end

local function RefreshPage(page)
    for _, widget in ipairs(page.widgets) do
        widget:Refresh()
    end
    PaintDependents(page)
    if page.OnShow then page:OnShow() end
end

local function AddResetButton(page)
    local button
    local function Disarm()
        button.armed = false
        button.text:SetText(L.RESET)
        button:Fit()
    end
    button = W.Button(page.content, "RESET", function(self)
        if self.armed then
            Disarm()
            ns.ResetSettings()
            return
        end
        self.armed = true
        self.text:SetText(L.RESET_CONFIRM)
        self:Fit()
        C_Timer.After(RESET_CONFIRM_SECONDS, function()
            if self.armed then Disarm() end
        end)
    end, "danger")
    page.stack:Add(button, 16)
end

local function BuildGeneral()
    local page = NewPage("general")
    AddHeading(page, "SECTION_TRACKING")
    AddToggle(page, "enabled", "ENABLE")
    AddToggle(page, "showSelf", "SHOW_SELF", "SHOW_SELF_DESC")
    AddToggle(page, "showUnsynced", "SHOW_UNSYNCED", "SHOW_UNSYNCED_DESC")
    AddToggle(page, "hideReady", "HIDE_READY")

    AddHeading(page, "SECTION_ASK")
    AddToggle(page, "askOnClick", "ASK_ON_CLICK", "ASK_ON_CLICK_DESC")
    ShowWhile(page, "askOnClick", AddSegmented(page, "askChannel", "ASK_CHANNEL", ASK_CHANNELS, "ASK_CHANNEL_", 4))

    AddHeading(page, "SECTION_OTHER")
    AddToggle(page, "tooltips", "TOOLTIPS")
    page.stack:Add(Track(page, W.Toggle(page.content, PAGE_WIDTH, {
        label = "MINIMAP_BUTTON",
        get = function() return not ns.db.minimap.hide end,
        set = ns.MinimapButton.SetShown,
    })))
    AddSegmented(page, "provider", "SECTION_FRAMES", ns.Anchors.PROVIDER_ORDER, "PROVIDER_", CONTROL_GAP)
    AddSegmented(page, "locale", "LANGUAGE", ns.LANGUAGES, "LANGUAGE_", CONTROL_GAP)
    AddResetButton(page)
end

local function ToLocal(side, x, y)
    if side == "RIGHT" then return x, y end
    if side == "LEFT" then return -x, y end
    if side == "TOP" then return y, x end
    return -y, x
end

local function FromLocal(side, gap, along)
    if side == "RIGHT" then return gap, along end
    if side == "LEFT" then return -gap, along end
    if side == "TOP" then return along, gap end
    return along, -gap
end

local function ChangeAnchor(side, align)
    local db = ns.db
    if db.side ~= side then
        local gap, along = ToLocal(db.side, db.offsetX, db.offsetY)
        db.offsetX, db.offsetY = FromLocal(side, gap, along)
        db.side = side
    end
    db.align = align
    ns.Fire("SETTING_CHANGED", "side")
end

local function DescribeAnchor(side, align)
    local alignKey = "ALIGN_CENTER"
    if align ~= "CENTER" then
        local vertical = side == "LEFT" or side == "RIGHT"
        alignKey = "ALIGN_" .. align .. (vertical and "_V" or "_H")
    end
    return L["SIDE_" .. side] .. ", " .. L[alignKey]
end

local function BuildDisplay()
    local page = NewPage("display")
    AddHeading(page, "SECTION_POSITION")
    page.stack:Add(Track(page, W.AnchorPicker(page.content, PAGE_WIDTH, PICKER_HEIGHT, {
        get = function() return ns.db.side, ns.db.align end,
        set = ChangeAnchor,
        describe = DescribeAnchor,
    })), 4)
    AddSliders(page, CONTROL_GAP, { { key = "offsetX", label = "OFFSET_X", min = -150, max = 150 } })
    AddSliders(page, CONTROL_GAP, { { key = "offsetY", label = "OFFSET_Y", min = -150, max = 150 } })

    AddHeading(page, "SECTION_ICONS")
    AddSegmented(page, "skin", "ICON_SKIN", SKINS, "SKIN_", 4)
    AddSliders(page, CONTROL_GAP, {
        { key = "size", label = "ICON_SIZE", min = 14, max = 64 },
        { key = "spacing", label = "SPACING", min = 0, max = 16 },
        { key = "perRow", label = "PER_ROW", min = 1, max = 12 },
    })

    AddHeading(page, "SECTION_TIMER")
    local timer = AddToggleRow(page, {
        { key = "timerText", label = "TIMER_TEXT" },
        { key = "timerDecimals", label = "TIMER_DECIMALS" },
    })
    ShowWhile(page, "timerText", timer[2])
    AddToggleRow(page, {
        { key = "swipe", label = "SWIPE" },
        { key = "desaturate", label = "DESATURATE" },
    })
    AddToggleRow(page, { { key = "pulse", label = "PULSE" } })
end

local function RaceID(race, faction)
    local ids = ns.SpellData.RACE_IDS[race]
    if not ids then return nil end
    return ids[faction] or ids.Alliance or ids.Horde
end

local function RaceName(race, faction)
    local id = RaceID(race, faction)
    local info = id and C_CreatureInfo and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(id)
    return info and info.raceName or race
end

local function PlayerFaction()
    return ns.Plain((UnitFactionGroup("player")))
end

local function RaceTag(info)
    if info.faction then
        return RaceName(info.race, info.faction)
    end
    if not info.raceList then return nil end
    local names = {}
    for i, race in ipairs(info.raceList) do
        names[i] = RaceName(race)
    end
    return table.concat(names, ", ")
end

local function TaggedName(key)
    local info = ns.Spells.Get(key)
    local name = ns.Spells.Name(key)
    if info.talent then
        name = name .. "  " .. TALENT_COLOR:WrapTextInColorCode(L.TALENT_TAG)
    end
    local raceTag = RaceTag(info)
    if raceTag then
        name = name .. "  " .. RACE_TAG_COLOR:WrapTextInColorCode(raceTag)
    end
    return name
end

local ClassName = UI.ClassName

local function CreateRemoveButton(row)
    local button = CreateFrame("Button", nil, row)
    button:SetSize(REMOVE_BUTTON_SIZE, REMOVE_BUTTON_SIZE)
    local cross = UI.Text(button, 16, C.muted)
    cross:SetPoint("CENTER", 0, 1)
    cross:SetText("×")
    button:SetScript("OnClick", function() ns.Custom.Remove(row.key) end)
    button:SetScript("OnEnter", function() cross:SetTextColor(unpack(C.bad)) end)
    button:SetScript("OnLeave", function() cross:SetTextColor(unpack(C.muted)) end)
    button:Hide()
    return button
end

local function CreateSpellRow(parent)
    local row = CreateFrame("Button", nil, parent)
    row:SetSize(PAGE_WIDTH, SPELL_ROW_HEIGHT)
    W.RowHover(row)

    local iconFrame = CreateFrame("Frame", nil, row)
    iconFrame:SetSize(20, 20)
    iconFrame:SetPoint("LEFT")
    UI.Fill(iconFrame, { 0, 0, 0, 1 })
    row.icon = iconFrame:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", 1, -1)
    row.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.switch = W.CreateSwitch(row)
    row.switch:SetPoint("RIGHT")
    row.remove = CreateRemoveButton(row)
    row.remove:SetPoint("RIGHT", row.switch, "LEFT", -8, 0)
    row.name = UI.Text(row, T.body, C.text)
    row.name:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    row.name:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(self)
        local enabled = not ns.Spells.IsEnabled(self.key)
        ns.Spells.SetEnabled(self.key, enabled)
        W.SetSwitch(self.switch, enabled, true)
        self:Paint()
    end)
    row:HookScript("OnEnter", function(self)
        W.SetSwitchHover(self.switch, true)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetSpellByID(self.key)
        GameTooltip:Show()
    end)
    row:HookScript("OnLeave", function(self)
        W.SetSwitchHover(self.switch, false)
        if GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end)

    function row:Paint()
        local enabled = ns.Spells.IsEnabled(self.key)
        self.icon:SetDesaturated(not enabled)
        self.icon:SetAlpha(enabled and 1 or 0.6)
        self.name:SetTextColor(unpack(enabled and C.text or C.muted))
    end

    function row:SetSpell(key, removable)
        self.key = key
        self.remove:SetShown(removable)
        self.name:SetPoint("RIGHT", removable and self.remove or self.switch, "LEFT", removable and -6 or -12, 0)
        self.icon:SetTexture(ns.Spells.Icon(key))
        self.name:SetText(TaggedName(key))
        W.SetSwitch(self.switch, ns.Spells.IsEnabled(key), false)
        self:Paint()
    end
    return row
end

local function CreateGroupHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(PAGE_WIDTH, GROUP_HEADER_HEIGHT)
    header.text = UI.BoldText(header, T.label, C.accent)
    header.text:SetPoint("BOTTOMLEFT", 0, 4)
    return header
end

local function SpellGroups(tab)
    local groups = {}
    if tab == RACIAL_TAB then
        for _, race in ipairs(ns.SpellData.RACE_ORDER) do
            groups[#groups + 1] = { title = RaceName(race, PlayerFaction()), keys = ns.Spells.RaceList(race), color = C.accent }
        end
        return groups
    end
    local byCategory = {}
    for _, key in ipairs(ns.Spells.ClassList(tab)) do
        local info = ns.Spells.Get(key)
        if not info.custom then
            byCategory[info.cat] = byCategory[info.cat] or {}
            table.insert(byCategory[info.cat], key)
        end
    end
    for _, cat in ipairs(ns.CATEGORIES) do
        if byCategory[cat] then
            groups[#groups + 1] = { title = L["CAT_" .. cat], keys = byCategory[cat], color = UI.CATEGORY_COLORS[cat] }
        end
    end
    groups[#groups + 1] = { title = L.CUSTOM_SPELLS, keys = ns.Custom.KeysFor(tab, {}), color = C.accent, custom = true }
    return groups
end

local function GroupKeys(tab)
    local keys = {}
    for _, group in ipairs(SpellGroups(tab)) do
        for _, key in ipairs(group.keys) do
            keys[#keys + 1] = key
        end
    end
    return keys
end

local function CreateClassTab(page, parent, tab, index, size)
    local button = CreateFrame("Button", nil, parent)
    button:SetSize(size, size + CLASS_TAB_BAR_SPACE)
    button:SetPoint("TOPLEFT", (index - 1) * (size + CLASS_TAB_GAP), 0)
    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetSize(size, size)
    icon:SetPoint("TOP")
    if tab == RACIAL_TAB then
        icon:SetTexture(ns.Spells.Icon(20594))
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    else
        UI.SetClassIcon(icon, tab)
    end
    button.icon = icon
    button.bar = button:CreateTexture(nil, "OVERLAY")
    button.bar:SetHeight(2)
    button.bar:SetPoint("BOTTOMLEFT")
    button.bar:SetPoint("BOTTOMRIGHT")
    button.bar:SetColorTexture(unpack(C.accent))
    button.tab = tab
    button:SetScript("OnClick", function(self) page:Select(self.tab) end)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(self.tab == RACIAL_TAB and L.RACIALS or ClassName(self.tab))
        GameTooltip:Show()
        self.icon:SetAlpha(1)
    end)
    button:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
        if page.tab ~= self.tab then self.icon:SetAlpha(0.4) end
    end)
    return button
end

local function CreateCustomMessage(parent)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetWidth(PAGE_WIDTH)
    local text = UI.Text(frame, T.label, C.muted)
    text:SetPoint("TOPLEFT")
    text:SetWidth(PAGE_WIDTH)
    text:SetWordWrap(true)
    text:SetJustifyH("LEFT")
    text:SetSpacing(3)
    local function Fit()
        frame:SetHeight(math.floor(text:GetStringHeight() + 4))
    end
    function frame:SetMessage(message, color)
        text:SetText(message)
        text:SetTextColor(unpack(color))
        Fit()
    end
    frame:SetScript("OnShow", Fit)
    frame:Hide()
    return frame
end

local function DescribeAddError(errorKey, key)
    if errorKey == "CUSTOM_ERROR_LIMIT" then
        return string.format(L.CUSTOM_ERROR_LIMIT, ns.Custom.MAX_SPELLS)
    end
    if not key then return L[errorKey] end
    local info = ns.Spells.Get(key)
    local tab = info.class and ClassName(info.class) or L.RACIALS
    return string.format(L[errorKey], ns.Spells.Name(key), tab)
end

local function CreateCustomInput(page)
    local row = CreateFrame("Frame", nil, page.content)
    row:SetSize(PAGE_WIDTH, CUSTOM_INPUT_HEIGHT)
    local function Submit() page:AddCustom() end
    local add = W.Button(row, "CUSTOM_ADD", Submit)
    add:SetPoint("RIGHT")
    row.input = W.TextInput(row, {
        placeholder = "CUSTOM_PLACEHOLDER",
        onSubmit = Submit,
        onChange = function() page:ShowCustomHint() end,
    })
    row.input:SetPoint("LEFT")
    row.input:SetPoint("RIGHT", add, "LEFT", -6, 0)
    row:Hide()
    return row
end

local function BuildSpells()
    local page = NewPage("spells")

    page.tabs = {}
    local tabs = {}
    for _, class in ipairs(ns.SpellData.CLASS_ORDER) do tabs[#tabs + 1] = class end
    tabs[#tabs + 1] = RACIAL_TAB
    local size = (PAGE_WIDTH - (#tabs - 1) * CLASS_TAB_GAP) / #tabs
    local tabsRow = CreateFrame("Frame", nil, page.content)
    tabsRow:SetSize(PAGE_WIDTH, size + CLASS_TAB_BAR_SPACE)
    page.stack:Add(tabsRow)
    for index, tab in ipairs(tabs) do
        page.tabs[index] = CreateClassTab(page, tabsRow, tab, index, size)
    end

    local titleRow = CreateFrame("Frame", nil, page.content)
    titleRow:SetSize(PAGE_WIDTH, 24)
    page.stack:Add(titleRow, 10)
    page.title = UI.BoldText(titleRow, T.title, C.text)
    page.title:SetPoint("LEFT")

    page.stack:Add(W.ButtonGroup(page.content, {
        { key = "BTN_ENABLE_ALL", onClick = function()
            ns.Spells.SetGroup(GroupKeys(page.tab), true)
            page:Select(page.tab)
        end },
        { key = "BTN_DISABLE_ALL", onClick = function()
            ns.Spells.SetGroup(GroupKeys(page.tab), false)
            page:Select(page.tab)
        end },
        { key = "BTN_DEFAULTS", onClick = function()
            ns.Spells.ResetGroup(GroupKeys(page.tab))
            page:Select(page.tab)
        end },
    }, PAGE_WIDTH), 6)

    page.rows = {}
    page.headers = {}
    page.firstListIndex = #page.stack.frames + 1
    page.customInput = CreateCustomInput(page)
    page.customMessage = CreateCustomMessage(page.content)

    function page:ShowCustomHint()
        self.customMessage:SetMessage(L.CUSTOM_HINT, C.muted)
    end

    function page:AddCustom()
        local input = self.customInput.input
        local ok, errorKey, key = ns.Custom.Add(input:GetText(), self.tab)
        if not ok then
            self.customMessage:SetMessage(DescribeAddError(errorKey, key), C.bad)
            return
        end
        input:SetText("")
        input:ClearFocus()
        self:ShowCustomHint()
    end

    local function Append(frame, gap)
        frame.stackGap = gap
        frame:Show()
        page.stack.frames[#page.stack.frames + 1] = frame
    end

    function page:Select(tab, keepScroll)
        if self.tab ~= tab then
            self.customInput.input:SetText("")
            self:ShowCustomHint()
        end
        self.tab = tab
        for _, button in ipairs(self.tabs) do
            local selected = button.tab == tab
            button.icon:SetAlpha(selected and 1 or 0.4)
            button.bar:SetShown(selected)
        end
        if tab == RACIAL_TAB then
            self.title:SetText(L.RACIALS)
            self.title:SetTextColor(unpack(C.text))
        else
            self.title:SetText(ClassName(tab))
            self.title:SetTextColor(UI.ClassColor(tab))
        end
        for i = #self.stack.frames, self.firstListIndex, -1 do
            self.stack.frames[i]:Hide()
            self.stack.frames[i] = nil
        end
        local rowIndex = 0
        for groupIndex, group in ipairs(SpellGroups(tab)) do
            local header = self.headers[groupIndex] or CreateGroupHeader(self.content)
            self.headers[groupIndex] = header
            header.text:SetText(group.title)
            header.text:SetTextColor(unpack(group.color))
            Append(header, groupIndex == 1 and 2 or 6)
            if group.custom then
                Append(self.customInput, CUSTOM_GAP)
                Append(self.customMessage, CUSTOM_GAP)
            end
            for _, key in ipairs(group.keys) do
                rowIndex = rowIndex + 1
                local row = self.rows[rowIndex] or CreateSpellRow(self.content)
                self.rows[rowIndex] = row
                row:SetSpell(key, group.custom == true)
                Append(row, 0)
            end
        end
        self.stack:Reflow()
        if not keepScroll then
            self.scroll:ScrollTo(0, false)
        end
    end

    function page:OnShow()
        self:Select(self.tab or select(2, UnitClass("player")) or "MAGE")
    end
    W.OnLocale(function()
        if page.tab then
            page:ShowCustomHint()
            page:Select(page.tab, true)
        end
    end)
    ns.Listen("CUSTOM_SPELLS_CHANGED", function(isLocal)
        if isLocal and page.tab and currentPage == page and window:IsShown() then
            page:Select(page.tab, true)
        end
    end)
end

local function CreateMemberRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(PAGE_WIDTH, MEMBER_ROW_HEIGHT)
    row.name = UI.Text(row, T.body, C.text)
    row.name:SetPoint("LEFT")
    row.status = UI.Text(row, T.label, C.muted)
    row.status:SetPoint("RIGHT")
    return row
end

local function PartyMember(index)
    local guid = ns.Roster.InParty() and ns.Roster.GUID("party" .. index)
    local member = guid and ns.Members.Get(guid)
    return member and member.class and member or nil
end

local function PaintMember(row, member)
    row.name:SetText(member.name or "?")
    row.name:SetTextColor(UI.ClassColor(member.class))
    row.status:SetText(member.synced and L.SYNC_MEMBER_SYNCED or L.SYNC_MEMBER_NONE)
    row.status:SetTextColor(unpack(member.synced and C.good or C.muted))
end

local function BuildSync()
    local page = NewPage("sync")
    local solo = page.stack:Add(W.Paragraph(page.content, PAGE_WIDTH, "SYNC_STATUS_SOLO"))
    local rows = {}
    for index = 1, PARTY_SLOTS do
        rows[index] = page.stack:Add(CreateMemberRow(page.content))
    end
    local paused = page.stack:Add(W.Paragraph(page.content, PAGE_WIDTH, "SYNC_STATUS_LOCKED"), CONTROL_GAP)
    paused.text:SetTextColor(unpack(C.warn))
    local resync = page.stack:Add(W.Button(page.content, "SYNC_REQUEST", function() ns.Comm.RequestSync() end), SECTION_GAP)

    function page:OnShow()
        local inParty = ns.Roster.InParty()
        for index, row in ipairs(rows) do
            local member = PartyMember(index)
            row:SetShown(member ~= nil)
            if member then PaintMember(row, member) end
        end
        solo:SetShown(not inParty)
        paused:SetShown(inParty and ns.Comm.IsBlocked())
        resync:SetShown(inParty)
        self.stack:Reflow()
    end

    local function RepaintIfVisible()
        if currentPage == page and window:IsShown() then page:OnShow() end
    end
    ns.Listen("MEMBER_CHANGED", RepaintIfVisible)
    ns.Listen("ROSTER_CHANGED", RepaintIfVisible)
    ns.Listen("COMM_BLOCK_CHANGED", RepaintIfVisible)
    W.AfterLocale(RepaintIfVisible)
end

local function BuildAbout()
    ns.About.Build(NewPage("about"), PAGE_WIDTH)
end

local DEFAULT_PAGE = "general"
local TABS = {
    { id = "general", key = "NAV_GENERAL", build = BuildGeneral },
    { id = "display", key = "NAV_DISPLAY", build = BuildDisplay },
    { id = "spells", key = "NAV_SPELLS", build = BuildSpells },
    { id = "sync", key = "NAV_SYNC", build = BuildSync },
    { id = "about", key = "NAV_ABOUT", build = BuildAbout },
}

local function FindTab(id)
    for _, entry in ipairs(TABS) do
        if entry.id == id then return entry end
    end
end

local underline = { x = 0, width = 0, motion = {} }

local function SetUnderline(x, width)
    underline.x, underline.width = x, width
    window.tabUnderline:SetPoint("BOTTOMLEFT", window.tabBar, "BOTTOMLEFT", x, 0)
    window.tabUnderline:SetWidth(math.max(1, width))
end

local function MoveUnderline(button, animate)
    local toX, toWidth = button.offset + TAB_PAD, button:GetWidth() - TAB_PAD * 2
    if not animate then
        UI.SnapTween(underline.motion, 1, function() SetUnderline(toX, toWidth) end)
        return
    end
    local fromX, fromWidth = underline.x, underline.width
    underline.motion.tweenValue = 0
    UI.Tween(underline.motion, 1, 0.2, function(_, t)
        SetUnderline(UI.Lerp(fromX, toX, t), UI.Lerp(fromWidth, toWidth, t))
    end)
end

local function ShowPage(id, animate)
    if not FindTab(id) then id = DEFAULT_PAGE end
    local page = pages[id]
    if not page then
        FindTab(id).build()
        page = pages[id]
    end
    if currentPage and currentPage ~= page then
        currentPage.scroll:Hide()
    end
    currentPage = page
    RefreshPage(page)
    page.scroll:ScrollTo(0, false)
    if animate then
        UI.FadeIn(page.scroll, 0.14)
    else
        page.scroll:Show()
        page.scroll:SetAlpha(1)
    end
    for index, entry in ipairs(TABS) do
        local button = tabButtons[index]
        local selected = entry.id == id
        button.text:SetTextColor(unpack(selected and C.text or C.muted))
        if selected then MoveUnderline(button, animate) end
    end
    ns.db.lastPage = id
end

local function LayoutTabs()
    local x = 0
    for _, button in ipairs(tabButtons) do
        button:SetWidth(math.ceil(button.text:GetStringWidth()) + TAB_PAD * 2)
        button:ClearAllPoints()
        button:SetPoint("BOTTOMLEFT", x, 0)
        button.offset = x
        x = x + button:GetWidth() + TAB_GAP
    end
    if currentPage then
        for index, entry in ipairs(TABS) do
            if entry.id == currentPage.id then MoveUnderline(tabButtons[index], false) end
        end
    end
end

local function CreateTabs()
    local bar = CreateFrame("Frame", nil, window)
    bar:SetPoint("TOPLEFT", MARGIN - TAB_PAD, -HEADER_HEIGHT)
    bar:SetPoint("TOPRIGHT", -MARGIN, -HEADER_HEIGHT)
    bar:SetHeight(TABS_HEIGHT)
    window.tabBar = bar
    local baseline = bar:CreateTexture(nil, "BACKGROUND")
    baseline:SetColorTexture(1, 1, 1, 0.05)
    baseline:SetHeight(1)
    baseline:SetPoint("BOTTOMLEFT", TAB_PAD, 0)
    baseline:SetPoint("BOTTOMRIGHT")
    local line = bar:CreateTexture(nil, "OVERLAY")
    line:SetColorTexture(unpack(C.accent))
    line:SetHeight(2)
    window.tabUnderline = line

    for index, entry in ipairs(TABS) do
        local button = CreateFrame("Button", nil, bar)
        button:SetHeight(TABS_HEIGHT)
        button.text = UI.Text(button, T.body, C.muted)
        button.text:SetPoint("CENTER", 0, 1)
        W.Bind(button.text, entry.key)
        button:SetScript("OnClick", function() ShowPage(entry.id, true) end)
        button:SetScript("OnEnter", function(self) self.text:SetTextColor(unpack(C.text)) end)
        button:SetScript("OnLeave", function(self)
            if currentPage ~= pages[entry.id] then self.text:SetTextColor(unpack(C.muted)) end
        end)
        tabButtons[index] = button
    end
    LayoutTabs()
    W.AfterLocale(LayoutTabs)
end

local function CreatePreviewToggle(header)
    local toggle = CreateFrame("Button", nil, header)
    toggle:SetHeight(24)
    local switch = W.CreateSwitch(toggle)
    switch:SetPoint("RIGHT")
    local label = UI.Text(toggle, T.label, C.muted)
    label:SetPoint("RIGHT", switch, "LEFT", -8, 0)
    W.Bind(label, "PREVIEW")
    local function Fit() toggle:SetWidth(label:GetStringWidth() + 8 + 26) end
    Fit()
    W.OnLocale(Fit)
    toggle:SetScript("OnClick", function()
        previewStartedHere = not ns.TestMode.active
        ns.TestMode.Toggle()
    end)
    toggle:SetScript("OnEnter", function()
        label:SetTextColor(unpack(C.text))
        W.SetSwitchHover(switch, true)
    end)
    toggle:SetScript("OnLeave", function()
        label:SetTextColor(unpack(C.muted))
        W.SetSwitchHover(switch, false)
    end)
    ns.Listen("TEST_MODE_CHANGED", function(active) W.SetSwitch(switch, active, true) end)
    W.SetSwitch(switch, ns.TestMode.active, false)
    return toggle
end

local function CreateHeader()
    local header = CreateFrame("Frame", nil, window)
    header:SetPoint("TOPLEFT")
    header:SetPoint("TOPRIGHT")
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    W.DragHandle(header, function() window:StartMoving() end, function() window:StopMovingOrSizing() end)

    local glyph = UI.AddonGlyph(header, HEADER_GLYPH_HEIGHT)
    glyph:SetPoint("LEFT", MARGIN, -2)
    local title = UI.BoldText(header, T.title, C.text)
    title:SetPoint("LEFT", glyph, "RIGHT", HEADER_GLYPH_GAP, 0)
    title:SetText(ns.TITLE)
    local version = UI.Text(header, T.caption, C.faint)
    version:SetPoint("BOTTOMLEFT", title, "BOTTOMRIGHT", 6, 0)
    version:SetText(ns.VERSION)

    local close = CreateFrame("Button", nil, header)
    close:SetSize(24, 24)
    close:SetPoint("RIGHT", -MARGIN + 6, -2)
    local cross = UI.Text(close, 18, C.muted)
    cross:SetPoint("CENTER", 0, 1)
    cross:SetText("×")
    close:SetScript("OnClick", Options.Close)
    close:SetScript("OnEnter", function() cross:SetTextColor(unpack(C.text)) end)
    close:SetScript("OnLeave", function() cross:SetTextColor(unpack(C.muted)) end)

    local preview = CreatePreviewToggle(header)
    preview:SetPoint("RIGHT", close, "LEFT", -12, 0)
end

local function CreateAnimations()
    local open = window:CreateAnimationGroup()
    local fadeIn = open:CreateAnimation("Alpha")
    fadeIn:SetFromAlpha(0)
    fadeIn:SetToAlpha(1)
    fadeIn:SetDuration(0.16)
    fadeIn:SetSmoothing("OUT")
    local grow = open:CreateAnimation("Scale")
    grow:SetScaleFrom(0.97, 0.97)
    grow:SetScaleTo(1, 1)
    grow:SetDuration(0.18)
    grow:SetSmoothing("OUT")
    window.openAnimation = open

    local close = window:CreateAnimationGroup()
    local fadeOut = close:CreateAnimation("Alpha")
    fadeOut:SetFromAlpha(1)
    fadeOut:SetToAlpha(0)
    fadeOut:SetDuration(0.12)
    fadeOut:SetSmoothing("IN")
    close:SetScript("OnFinished", function() window:Hide() end)
    window.closeAnimation = close
end

local function CreateWindow()
    window = CreateFrame("Frame", "PartyCooldownsOptionsFrame", UIParent)
    window:SetSize(WIDTH, HEIGHT)
    window:SetPoint("CENTER")
    window:SetFrameStrata("DIALOG")
    window:SetToplevel(true)
    window:SetMovable(true)
    window:SetClampedToScreen(true)
    window:EnableMouse(true)
    window:Hide()
    UI.Fill(window, C.window)
    tinsert(UISpecialFrames, window:GetName())

    CreateHeader()
    CreateTabs()

    local body = CreateFrame("Frame", nil, window)
    body:SetPoint("TOPLEFT", MARGIN - CONTENT_INSET, -HEADER_HEIGHT - TABS_HEIGHT - BODY_GAP)
    body:SetPoint("BOTTOMRIGHT", -MARGIN + CONTENT_INSET, MARGIN)
    window.body = body

    CreateAnimations()
    window:SetScript("OnHide", function()
        if previewStartedHere then
            ns.TestMode.Stop()
            previewStartedHere = false
        end
    end)
end

function Options.Open(pageId)
    if not window then CreateWindow() end
    window.closeAnimation:Stop()
    if not window:IsShown() then
        window:Show()
        window.openAnimation:Restart()
        if not ns.TestMode.active and not ns.Roster.InParty() then
            previewStartedHere = true
            ns.TestMode.Start()
        end
    end
    ShowPage(pageId or currentPage and currentPage.id or ns.db.lastPage or DEFAULT_PAGE, false)
end

function Options.Close()
    if not window or not window:IsShown() then return end
    window.openAnimation:Stop()
    window.closeAnimation:Restart()
end

function Options.Toggle(pageId)
    if window and window:IsShown() and not pageId then
        Options.Close()
    else
        Options.Open(pageId)
    end
end

ns.Listen("SETTING_CHANGED", function(key)
    if window and window:IsShown() and currentPage and key ~= "spells" then
        for _, widget in ipairs(currentPage.widgets) do
            widget:Refresh()
        end
        PaintDependents(currentPage)
    end
end)

local function RegisterSettingsCategory()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    panel:Hide()
    local open = W.Button(panel, "SETTINGS_OPEN", function() Options.Open() end, "primary")
    open:SetPoint("TOPLEFT", SETTINGS_PANEL_INSET, -SETTINGS_PANEL_INSET)
    local category = Settings.RegisterCanvasLayoutCategory(panel, ns.TITLE)
    Settings.RegisterAddOnCategory(category)
end

ns.Listen("LOGIN", RegisterSettingsCategory)
