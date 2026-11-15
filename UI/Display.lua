local _, ns = ...

local UI = ns.UI
local Icon = ns.Icon

local Display = {}
ns.Display = Display

local GetTime = GetTime
local ceil, floor, min = math.ceil, math.floor, math.min

local TICK_INTERVAL = 0.1
local VALIDATE_INTERVAL = 1
local LEVEL_ABOVE_ANCHOR = 10

local ANCHOR_POINTS = {
    RIGHT = { START = { "TOPLEFT", "TOPRIGHT" }, CENTER = { "LEFT", "RIGHT" }, END = { "BOTTOMLEFT", "BOTTOMRIGHT" } },
    LEFT = { START = { "TOPRIGHT", "TOPLEFT" }, CENTER = { "RIGHT", "LEFT" }, END = { "BOTTOMRIGHT", "BOTTOMLEFT" } },
    TOP = { START = { "BOTTOMLEFT", "TOPLEFT" }, CENTER = { "BOTTOM", "TOP" }, END = { "BOTTOMRIGHT", "TOPRIGHT" } },
    BOTTOM = { START = { "TOPLEFT", "BOTTOMLEFT" }, CENTER = { "TOP", "BOTTOM" }, END = { "TOPRIGHT", "BOTTOMRIGHT" } },
}

Display.ANCHOR_POINTS = ANCHOR_POINTS

local GROWTH = {
    RIGHT = { "TOPLEFT", 1, -1 },
    LEFT = { "TOPRIGHT", -1, -1 },
    TOP = { "BOTTOMLEFT", 1, 1 },
    BOTTOM = { "TOPLEFT", 1, -1 },
}

local bars = {}
local running = {}
local stale = {}
local keys = {}
local hookedAnchors = {}

local driver = CreateFrame("Frame")
driver:Hide()
local sinceTick = 0

local function StartDriver()
    if not driver:IsShown() then
        sinceTick = TICK_INTERVAL
        driver:Show()
    end
end

local function CreateBar(unit)
    local bar = CreateFrame("Frame", nil, UIParent)
    bar:SetSize(1, 1)
    bar:Hide()
    bar.unit = unit
    bar.icons = {}
    bars[unit] = bar
    return bar
end

local function StopIcons(bar, from, keepVisible)
    for i = from, #bar.icons do
        local button = bar.icons[i]
        running[button] = nil
        if not keepVisible then button:Hide() end
    end
end

local function HideBar(bar, waitingForAnchor)
    bar.waitingForAnchor = waitingForAnchor
    bar.anchor = nil
    StopIcons(bar, 1, true)
    UI.FadeOut(bar, 0.12)
end

local function ShouldShow(unit, member)
    local db = ns.db
    if not db.enabled or not member or not member.class then return false end
    if unit == "player" and not db.showSelf then return false end
    return ns.TestMode.active or ns.Roster.InParty()
end

local function CollectKeys(member, now)
    ns.Spells.CollectFor(member, keys)
    local db = ns.db
    local hideUnknown = not member.synced and not db.showUnsynced
    if not db.hideReady and not hideUnknown then return keys end
    local count = 0
    for i = 1, #keys do
        local key = keys[i]
        if ns.Members.Remaining(member, key, now) > 0 then
            count = count + 1
            keys[count] = key
        end
    end
    for i = #keys, count + 1, -1 do
        keys[i] = nil
    end
    return keys
end

local function HookAnchor(anchor)
    if hookedAnchors[anchor] then return end
    hookedAnchors[anchor] = true
    anchor:HookScript("OnShow", Display.QueueRefresh)
    anchor:HookScript("OnHide", Display.QueueRefresh)
end

local function PlaceBar(bar, anchor, count)
    local db = ns.db
    local size, spacing = db.size, db.spacing
    local columns = min(count, db.perRow)
    local rows = ceil(count / db.perRow)
    bar:SetSize(columns * size + (columns - 1) * spacing, rows * size + (rows - 1) * spacing)
    local points = ANCHOR_POINTS[db.side][db.align]
    bar:ClearAllPoints()
    bar:SetPoint(points[1], anchor, points[2], db.offsetX, db.offsetY)
    bar:SetFrameStrata(anchor:GetFrameStrata())
    bar:SetFrameLevel(anchor:GetFrameLevel() + LEVEL_ABOVE_ANCHOR)
    bar.anchor = anchor
end

local function PlaceIcons(bar, member, now)
    local db = ns.db
    local size, step, perRow = db.size, db.size + db.spacing, db.perRow
    local growth = GROWTH[db.side]
    local corner, dirX, dirY = growth[1], growth[2], growth[3]
    for i = 1, #keys do
        local button = bar.icons[i]
        if not button then
            button = Icon.Create(bar)
            bar.icons[i] = button
        end
        local index = i - 1
        local column, row = index % perRow, floor(index / perRow)
        button:ClearAllPoints()
        button:SetPoint(corner, bar, corner, column * step * dirX, row * step * dirY)
        Icon.Configure(button, size)
        button:Show()
        if Icon.Assign(button, keys[i], member, now) then
            running[button] = bar
            StartDriver()
        else
            running[button] = nil
        end
    end
    StopIcons(bar, #keys + 1)
end

function Display.RefreshUnit(unit)
    if not unit then return end
    local bar = bars[unit] or CreateBar(unit)
    local guid = ns.Roster.GUID(unit)
    local member = guid and ns.Members.Get(guid)
    if not ShouldShow(unit, member) then
        HideBar(bar, false)
        return
    end
    local now = GetTime()
    ns.Members.PruneExpired(member, now)
    CollectKeys(member, now)
    if #keys == 0 then
        HideBar(bar, false)
        return
    end
    local anchor = ns.Anchors.Resolve(unit)
    if not anchor then
        HideBar(bar, true)
        return
    end
    bar.waitingForAnchor = false
    HookAnchor(anchor)
    PlaceBar(bar, anchor, #keys)
    PlaceIcons(bar, member, now)
    UI.FadeIn(bar, 0.15)
end

function Display.RefreshAll()
    for _, unit in ipairs(ns.Roster.UNITS) do
        Display.RefreshUnit(unit)
    end
end

function Display.QueueRefresh()
    ns.Schedule("display.refresh", 0.05, Display.RefreshAll)
end

driver:SetScript("OnUpdate", function(self, elapsed)
    sinceTick = sinceTick + elapsed
    if sinceTick < TICK_INTERVAL then return end
    sinceTick = 0
    local now = GetTime()
    for button, bar in pairs(running) do
        if not Icon.Tick(button, now) then
            running[button] = nil
            stale[bar] = true
        end
    end
    if ns.db.hideReady and next(stale) then
        Display.QueueRefresh()
    end
    wipe(stale)
    if not next(running) then
        self:Hide()
    end
end)

local function Validate()
    for unit, bar in pairs(bars) do
        local outdated
        if bar.anchor then
            outdated = ns.Anchors.Resolve(unit) ~= bar.anchor
        elseif bar.waitingForAnchor then
            outdated = ns.Anchors.Resolve(unit) ~= nil
        end
        if outdated then
            Display.QueueRefresh()
            return
        end
    end
end

local function OnMemberChanged(guid)
    Display.RefreshUnit(ns.Roster.Unit(guid))
end

ns.Listen("ROSTER_CHANGED", Display.QueueRefresh)
ns.Listen("MEMBER_CHANGED", OnMemberChanged)
ns.Listen("COOLDOWN_CHANGED", OnMemberChanged)
ns.Listen("SETTING_CHANGED", Display.QueueRefresh)
ns.Listen("LOGIN", function()
    C_Timer.NewTicker(VALIDATE_INTERVAL, Validate)
    if EditModeManagerFrame then
        EditModeManagerFrame:HookScript("OnHide", Display.QueueRefresh)
        EditModeManagerFrame:HookScript("OnShow", Display.QueueRefresh)
    end
end)
