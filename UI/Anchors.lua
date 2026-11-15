local _, ns = ...

local Anchors = {}
ns.Anchors = Anchors

local COMPACT_MEMBERS = 5
local mocks

local function FrameUnit(frame)
    local unit = frame.unit
    if unit == nil and frame.GetAttribute then
        unit = frame:GetAttribute("unit")
    end
    return ns.Plain(unit)
end

local function Matches(frame, unit)
    return frame ~= nil and frame:IsVisible() and FrameUnit(frame) == unit
end

local function FromEllesmere(unit)
    local selfButton = _G.ERFPartySelfButton
    if unit == "player" and Matches(selfButton, unit) then return selfButton end
    local header = _G.ERFPartyHeader
    if not header or not header:IsVisible() then return nil end
    local index = 1
    local child = header:GetAttribute("child1")
    while child do
        if Matches(child, unit) then return child end
        index = index + 1
        child = header:GetAttribute("child" .. index)
    end
end

local function FromCompact(unit)
    for i = 1, COMPACT_MEMBERS do
        local frame = _G["CompactPartyFrameMember" .. i]
        if Matches(frame, unit) then return frame end
    end
end

local function FromBlizzard(unit)
    if unit == "player" then
        return Matches(PlayerFrame, unit) and PlayerFrame or nil
    end
    local pool = PartyFrame and PartyFrame.PartyMemberFramePool
    if not pool then return nil end
    for frame in pool:EnumerateActive() do
        if Matches(frame, unit) then return frame end
    end
end

local PROVIDERS = {
    ellesmere = FromEllesmere,
    compact = FromCompact,
    blizzard = FromBlizzard,
}

Anchors.PROVIDER_ORDER = { "auto", "ellesmere", "compact", "blizzard" }
local AUTO_ORDER = { "ellesmere", "compact", "blizzard" }

local function FindReal(unit)
    local chosen = PROVIDERS[ns.db.provider]
    if chosen then
        return chosen(unit), ns.db.provider
    end
    for _, name in ipairs(AUTO_ORDER) do
        local frame = PROVIDERS[name](unit)
        if frame then return frame, name end
    end
end

function Anchors.Resolve(unit)
    local frame, provider = FindReal(unit)
    if frame then return frame, provider end
    local mock = mocks and mocks[unit]
    if mock and mock:IsVisible() then
        return mock, "preview"
    end
end

function Anchors.SetMocks(map)
    mocks = map
end
