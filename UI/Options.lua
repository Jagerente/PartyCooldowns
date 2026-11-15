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
local SETTINGS_GLYPH_HEIGHT = 20
local TAB_PAD, TAB_GAP = 8, 6
local PAGE_WIDTH = WIDTH - MARGIN * 2
local CONTENT_INSET = 8
local SECTION_GAP = 10
local PICKER_HEIGHT = 150
local SLIDER_GAP = 8
local SPELL_ROW_HEIGHT = 26
local GROUP_HEADER_HEIGHT = 20
local CLASS_TAB_GAP, CLASS_TAB_BAR_SPACE = 6, 6
local MEMBER_ROW_HEIGHT = 24
local STATUS_INTERVAL = 1
local RESET_CONFIRM_SECONDS = 3
local RACE_IDS = { Human = 1, Orc = 2, Dwarf = 3, NightElf = 4, Scourge = 5, Tauren = 6, Gnome = 7, Troll = 8 }
local RACIAL_TAB = "RACIAL"
local TALENT_COLOR = CreateColor(unpack(C.talent))

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

local function AddToggle(page, key, label, desc)
    local get, set = Setting(key)
    return page.stack:Add(Track(page, W.Toggle(page.content, PAGE_WIDTH, { label = label, desc = desc, get = get, set = set })))
end

local function NewSlider(page, parent, width, key, label, min, max)
    local get, set = Setting(key)
    return Track(page, W.Slider(parent, width, { label = label, min = min, max = max, step = 1, get = get, set = set }))
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

local function NewPage(id)
    local scroll = W.Scroll(window.body)
    scroll:SetAllPoints(window.body)
    scroll:Hide()
    local page = { id = id, scroll = scroll, content = scroll.content, widgets = {} }
    page.stack = W.Stack(page.content, CONTENT_INSET)
    pages[id] = page
    return page
end

local function RefreshPage(page)
    for _, widget in ipairs(page.widgets) do
        widget:Refresh()
    end
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
    AddHeading(page, "SECTION_BEHAVIOR")
    AddToggle(page, "enabled", "ENABLE", "ENABLE_DESC")
    AddToggle(page, "showSelf", "SHOW_SELF", "SHOW_SELF_DESC")
    AddToggle(page, "showUnsynced", "SHOW_UNSYNCED", "SHOW_UNSYNCED_DESC")
    AddToggle(page, "hideReady", "HIDE_READY", "HIDE_READY_DESC")
    AddToggle(page, "tooltips", "TOOLTIPS", "TOOLTIPS_DESC")
    page.stack:Add(Track(page, W.Toggle(page.content, PAGE_WIDTH, {
        label = "MINIMAP_BUTTON", desc = "MINIMAP_BUTTON_DESC",
        get = function() return not ns.db.minimap.hide end,
        set = ns.MinimapButton.SetShown,
    })))

    local getProvider, setProvider = Setting("provider")
    page.stack:Add(Track(page, W.Segmented(page.content, PAGE_WIDTH, {
        label = "SECTION_FRAMES", count = #ns.Anchors.PROVIDER_ORDER,
        items = LocalizedItems(ns.Anchors.PROVIDER_ORDER, "PROVIDER_"),
        get = getProvider, set = setProvider,
    })), SECTION_GAP)

    local getLocale, setLocale = Setting("locale")
    page.stack:Add(Track(page, W.Segmented(page.content, PAGE_WIDTH, {
        label = "LANGUAGE", count = #ns.LANGUAGES,
        items = LocalizedItems(ns.LANGUAGES, "LANGUAGE_"),
        get = getLocale, set = setLocale,
    })), 8)
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
    return L["SIDE_" .. side] .. "  ·  " .. L[alignKey]
end

local function AddSlider(page, key, label, min, max, gap)
    return page.stack:Add(NewSlider(page, page.content, PAGE_WIDTH, key, label, min, max), gap or SLIDER_GAP)
end

local function BuildDisplay()
    local page = NewPage("display")
    AddHeading(page, "SECTION_POSITION")
    page.stack:Add(Track(page, W.AnchorPicker(page.content, PAGE_WIDTH, PICKER_HEIGHT, {
        get = function() return ns.db.side, ns.db.align end,
        set = ChangeAnchor,
        describe = DescribeAnchor,
        hint = "PICKER_HINT",
    })), 4)
    AddSlider(page, "offsetX", "OFFSET_X", -150, 150, 12)
    AddSlider(page, "offsetY", "OFFSET_Y", -150, 150)

    AddHeading(page, "SECTION_ICONS")
    AddSlider(page, "size", "ICON_SIZE", 14, 64, 4)
    AddSlider(page, "spacing", "SPACING", 0, 16)
    AddSlider(page, "perRow", "PER_ROW", 1, 12)

    AddHeading(page, "SECTION_TIMER")
    AddToggle(page, "timerText", "TIMER_TEXT", "TIMER_TEXT_DESC")
    AddToggle(page, "timerDecimals", "TIMER_DECIMALS", "TIMER_DECIMALS_DESC")
    AddHeading(page, "SECTION_STYLE")
    AddToggle(page, "swipe", "SWIPE", "SWIPE_DESC")
    AddToggle(page, "desaturate", "DESATURATE", "DESATURATE_DESC")
    AddToggle(page, "pulse", "PULSE", "PULSE_DESC")
end

local function RaceName(race)
    local info = C_CreatureInfo and C_CreatureInfo.GetRaceInfo and C_CreatureInfo.GetRaceInfo(RACE_IDS[race])
    return info and info.raceName or race
end

local ClassName = UI.ClassName

local function CreateSpellRow(parent, onToggle)
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
    row.name = UI.Text(row, T.body, C.text)
    row.name:SetPoint("LEFT", iconFrame, "RIGHT", 10, 0)
    row.name:SetPoint("RIGHT", row.switch, "LEFT", -12, 0)
    row.name:SetJustifyH("LEFT")

    row:SetScript("OnClick", function(self)
        local enabled = not ns.Spells.IsEnabled(self.key)
        ns.Spells.SetEnabled(self.key, enabled)
        W.SetSwitch(self.switch, enabled, true)
        self:Paint()
        onToggle()
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

    function row:SetSpell(key)
        local info = ns.Spells.Get(key)
        self.key = key
        self.icon:SetTexture(ns.Spells.Icon(key))
        local name = ns.Spells.Name(key)
        if info.talent then
            name = name .. "  " .. TALENT_COLOR:WrapTextInColorCode(L.TALENT_TAG)
        end
        self.name:SetText(name)
        W.SetSwitch(self.switch, ns.Spells.IsEnabled(key), false)
        self:Paint()
    end
    return row
end

local function CreateGroupHeader(parent)
    local header = CreateFrame("Frame", nil, parent)
    header:SetSize(PAGE_WIDTH, GROUP_HEADER_HEIGHT)
    header.text = UI.BoldText(header, T.label, C.faint)
    header.text:SetPoint("BOTTOMLEFT", 0, 4)
    return header
end

local function SpellGroups(tab)
    local groups = {}
    if tab == RACIAL_TAB then
        for _, race in ipairs(ns.SpellData.RACE_ORDER) do
            groups[#groups + 1] = { title = RaceName(race), keys = ns.Spells.RaceList(race), color = C.accent }
        end
        return groups
    end
    local byCategory = {}
    for _, key in ipairs(ns.Spells.ClassList(tab)) do
        local cat = ns.Spells.Get(key).cat
        byCategory[cat] = byCategory[cat] or {}
        table.insert(byCategory[cat], key)
    end
    for _, cat in ipairs(ns.CATEGORIES) do
        if byCategory[cat] then
            groups[#groups + 1] = { title = L["CAT_" .. cat], keys = byCategory[cat], color = UI.CATEGORY_COLORS[cat] }
        end
    end
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
    page.count = UI.Text(titleRow, T.label, C.faint)
    page.count:SetPoint("LEFT", page.title, "RIGHT", 8, -1)

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

    function page:PaintCount()
        local keys = GroupKeys(self.tab)
        local enabled = 0
        for _, key in ipairs(keys) do
            if ns.Spells.IsEnabled(key) then enabled = enabled + 1 end
        end
        self.count:SetText(enabled .. " / " .. #keys)
    end

    local function Append(frame, gap)
        frame.stackGap = gap
        frame:Show()
        page.stack.frames[#page.stack.frames + 1] = frame
    end

    function page:Select(tab)
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
            for _, key in ipairs(group.keys) do
                rowIndex = rowIndex + 1
                local row = self.rows[rowIndex] or CreateSpellRow(self.content, function() page:PaintCount() end)
                self.rows[rowIndex] = row
                row:SetSpell(key)
                Append(row, 0)
            end
        end
        self:PaintCount()
        self.stack:Reflow()
        self.scroll:ScrollTo(0, false)
    end

    function page:OnShow()
        self:Select(self.tab or select(2, UnitClass("player")) or "MAGE")
    end
    W.OnLocale(function()
        if page.tab then page:Select(page.tab) end
    end)
end

local function CreateMemberRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(PAGE_WIDTH, MEMBER_ROW_HEIGHT)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(16, 16)
    row.icon:SetPoint("LEFT")
    row.name = UI.Text(row, T.body, C.text)
    row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.status = UI.Text(row, T.label, C.muted)
    row.status:SetPoint("RIGHT")
    return row
end

local function CountKnown(member)
    local count = 0
    for _ in pairs(member.known) do count = count + 1 end
    return count
end

local function BuildSync()
    local page = NewPage("sync")
    page.stack:Add(W.Paragraph(page.content, PAGE_WIDTH, "SYNC_EXPLAIN"), 4)

    local status = CreateFrame("Frame", nil, page.content)
    status:SetSize(PAGE_WIDTH, 24)
    page.stack:Add(status, 14)
    local statusDot = W.Circle(status, "ARTWORK")
    statusDot:SetSize(7, 7)
    statusDot:SetPoint("LEFT", 0, 0)
    local resync = W.Button(status, "SYNC_REQUEST", function() ns.Comm.RequestSync() end)
    resync:SetPoint("RIGHT")
    local statusText = UI.Text(status, T.body, C.text)
    statusText:SetPoint("LEFT", statusDot, "RIGHT", 8, 0)
    statusText:SetPoint("RIGHT", resync, "LEFT", -12, 0)
    statusText:SetJustifyH("LEFT")

    AddHeading(page, "SYNC_MEMBERS")
    local empty = W.Paragraph(page.content, PAGE_WIDTH, "SYNC_NO_MEMBERS")
    page.stack:Add(empty)
    local rows = {}
    for index = 1, 4 do
        rows[index] = page.stack:Add(CreateMemberRow(page.content))
    end

    local function PaintStatus()
        local color, text
        if not ns.Roster.InParty() then
            color, text = C.faint, L.SYNC_STATUS_SOLO
        elseif ns.Comm.IsBlocked() then
            color, text = C.warn, L.SYNC_STATUS_LOCKED
        else
            color, text = C.good, L.SYNC_STATUS_OK
        end
        statusDot:SetVertexColor(unpack(color))
        statusText:SetText(text)
    end

    local function PaintMembers()
        local shown = 0
        for index = 1, 4 do
            local guid = ns.Roster.InParty() and ns.Roster.GUID("party" .. index)
            local member = guid and ns.Members.Get(guid)
            local row = rows[index]
            if member and member.class then
                shown = shown + 1
                UI.SetClassIcon(row.icon, member.class)
                row.name:SetText(member.name or "?")
                row.name:SetTextColor(UI.ClassColor(member.class))
                if member.synced then
                    row.status:SetText(string.format(L.SYNC_MEMBER_SYNCED, CountKnown(member)))
                    row.status:SetTextColor(unpack(C.good))
                else
                    row.status:SetText(L.SYNC_MEMBER_NONE)
                    row.status:SetTextColor(unpack(C.faint))
                end
                row:Show()
            else
                row:Hide()
            end
        end
        empty:SetShown(shown == 0)
        page.stack:Reflow()
    end

    function page:OnShow()
        PaintStatus()
        PaintMembers()
    end

    local elapsed = 0
    page.scroll:SetScript("OnUpdate", function(_, delta)
        elapsed = elapsed + delta
        if elapsed < STATUS_INTERVAL then return end
        elapsed = 0
        PaintStatus()
    end)
    local function RepaintIfVisible()
        if currentPage == page and window:IsShown() then PaintMembers() end
    end
    ns.Listen("MEMBER_CHANGED", RepaintIfVisible)
    ns.Listen("ROSTER_CHANGED", RepaintIfVisible)
    W.AfterLocale(function()
        if currentPage == page then page:OnShow() end
    end)
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
    toggle:SetScript("OnEnter", function(self)
        label:SetTextColor(unpack(C.text))
        W.SetSwitchHover(switch, true)
        GameTooltip:SetOwner(self, "ANCHOR_BOTTOM")
        GameTooltip:SetText(L.PREVIEW_DESC, 1, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    toggle:SetScript("OnLeave", function()
        label:SetTextColor(unpack(C.muted))
        W.SetSwitchHover(switch, false)
        GameTooltip:Hide()
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
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() window:StartMoving() end)
    header:SetScript("OnDragStop", function() window:StopMovingOrSizing() end)

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
    end
end)

local function RegisterSettingsCategory()
    if not (Settings and Settings.RegisterCanvasLayoutCategory) then return end
    local panel = CreateFrame("Frame")
    panel:Hide()
    local glyph = UI.AddonGlyph(panel, SETTINGS_GLYPH_HEIGHT)
    glyph:SetPoint("TOPLEFT", 16, -16)
    local title = UI.Text(panel, 20, C.text)
    title:SetPoint("LEFT", glyph, "RIGHT", HEADER_GLYPH_GAP, 0)
    title:SetText(ns.TITLE)
    local desc = UI.Text(panel, T.body, C.muted)
    desc:SetPoint("TOPLEFT", glyph, "BOTTOMLEFT", 0, -10)
    W.Bind(desc, "SETTINGS_DESC")
    local open = W.Button(panel, "SETTINGS_OPEN", function() Options.Open() end, "primary")
    open:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
    local category = Settings.RegisterCanvasLayoutCategory(panel, ns.TITLE)
    Settings.RegisterAddOnCategory(category)
end

ns.Listen("LOGIN", RegisterSettingsCategory)
