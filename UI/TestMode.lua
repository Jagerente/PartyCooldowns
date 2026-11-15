local _, ns = ...

local UI = ns.UI
local L = ns.L

local TestMode = { active = false }
ns.TestMode = TestMode

local GetTime = GetTime
local random = math.random

local SIMULATION_INTERVAL = 1
local CAST_CHANCE = 0.06
local START_ACTIVE_CHANCE = 0.5
local MOCK_WIDTH, MOCK_HEIGHT, MOCK_GAP = 132, 40, 14

local CAST = {
    { unit = "player", class = "PALADIN" },
    { unit = "party1", class = "MAGE" },
    { unit = "party2", class = "PRIEST" },
    { unit = "party3", class = "WARRIOR" },
    { unit = "party4", class = "ROGUE" },
}

local overrideMap = {}
local mockMap = {}
local mockColumn
local ticker

local function FakeGUID(index)
    return "PartyCooldowns-Preview-" .. index
end

local function CreateMockFrame(parent, index)
    local frame = CreateFrame("Frame", nil, parent)
    frame:SetSize(MOCK_WIDTH, MOCK_HEIGHT)
    frame:SetPoint("TOPLEFT", 0, -(index - 1) * (MOCK_HEIGHT + MOCK_GAP))
    UI.Fill(frame, { 0, 0, 0, 0.85 })
    frame.health = frame:CreateTexture(nil, "ARTWORK")
    frame.health:SetPoint("TOPLEFT", 1, -1)
    frame.health:SetPoint("BOTTOMRIGHT", -1, 1)
    frame.health:SetColorTexture(1, 1, 1, 1)
    frame.name = UI.Text(frame, 12, UI.COLORS.text)
    frame.name:SetPoint("LEFT", 8, 0)
    return frame
end

local function CreateMockColumn()
    local column = CreateFrame("Frame", nil, UIParent)
    column:SetSize(MOCK_WIDTH, #CAST * (MOCK_HEIGHT + MOCK_GAP))
    column:SetFrameStrata("LOW")
    column:SetMovable(true)
    column:SetClampedToScreen(true)
    column:EnableMouse(true)
    column:RegisterForDrag("LeftButton")
    column:SetScript("OnDragStart", column.StartMoving)
    column:SetScript("OnDragStop", column.StopMovingOrSizing)
    column.hint = UI.Text(column, 11, UI.COLORS.muted)
    column.hint:SetPoint("BOTTOMLEFT", column, "TOPLEFT", 0, 8)
    column.frames = {}
    for index = 1, #CAST do
        column.frames[index] = CreateMockFrame(column, index)
    end
    column:Hide()
    return column
end

local function PlaceMockColumn()
    mockColumn:ClearAllPoints()
    mockColumn:SetPoint("LEFT", UIParent, "LEFT", 220, 60)
end

local function PaintMocks()
    mockColumn.hint:SetText(L.PREVIEW_DRAG_HINT)
    for index, entry in ipairs(CAST) do
        local frame = mockColumn.frames[index]
        local r, g, b = UI.ClassColor(entry.class)
        frame.health:SetVertexColor(r * 0.55, g * 0.55, b * 0.55, 0.9)
        frame.name:SetText(entry.unit == "player" and L.PREVIEW_YOU or (LOCALIZED_CLASS_NAMES_MALE and LOCALIZED_CLASS_NAMES_MALE[entry.class] or entry.class))
        frame.unit = entry.unit
        mockMap[entry.unit] = frame
    end
end

local function SeedMember(index, entry)
    local member = ns.Members.Ensure(FakeGUID(index))
    member.class = entry.class
    member.race = nil
    member.name = entry.unit == "player" and L.PREVIEW_YOU or entry.class
    member.unit = entry.unit
    member.synced = true
    member.version = 1
    wipe(member.known)
    wipe(member.cds)
    local now = GetTime()
    for _, key in ipairs(ns.Spells.ClassList(entry.class)) do
        member.known[key] = true
        if random() < START_ACTIVE_CHANCE then
            local duration = ns.Spells.Get(key).cd
            member.cds[key] = { start = now - random() * duration * 0.8, duration = duration }
        end
    end
    overrideMap[entry.unit] = member.guid
end

local function Simulate()
    local now = GetTime()
    for index in ipairs(CAST) do
        local member = ns.Members.Get(FakeGUID(index))
        if member then
            for key in pairs(member.known) do
                if ns.Members.Remaining(member, key, now) <= 0 and random() < CAST_CHANCE then
                    ns.Members.StartCooldown(member, key, now, ns.Spells.Get(key).cd)
                    ns.Members.ApplyResets(member, key)
                end
            end
        end
    end
end

function TestMode.Start()
    if TestMode.active then return end
    TestMode.active = true
    mockColumn = mockColumn or CreateMockColumn()
    if not mockColumn.placed then
        PlaceMockColumn()
        mockColumn.placed = true
    end
    wipe(overrideMap)
    for index, entry in ipairs(CAST) do
        SeedMember(index, entry)
    end
    PaintMocks()
    ns.Anchors.SetMocks(mockMap)
    ns.Roster.SetOverride(overrideMap)
    mockColumn:SetShown(not ns.Roster.InParty())
    ticker = C_Timer.NewTicker(SIMULATION_INTERVAL, Simulate)
    ns.Fire("TEST_MODE_CHANGED", true)
end

function TestMode.Stop()
    if not TestMode.active then return end
    TestMode.active = false
    if ticker then
        ticker:Cancel()
        ticker = nil
    end
    mockColumn:Hide()
    ns.Anchors.SetMocks(nil)
    for index in ipairs(CAST) do
        ns.Members.Forget(FakeGUID(index))
    end
    ns.Roster.SetOverride(nil)
    ns.Fire("TEST_MODE_CHANGED", false)
end

function TestMode.Toggle()
    if TestMode.active then
        TestMode.Stop()
    else
        TestMode.Start()
    end
end

ns.Listen("LOCALE_CHANGED", function()
    if TestMode.active then PaintMocks() end
end)

ns.Listen("ROSTER_CHANGED", function()
    if TestMode.active then mockColumn:SetShown(not ns.Roster.InParty()) end
end)
