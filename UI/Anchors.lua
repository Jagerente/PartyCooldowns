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

local function FromHeader(header, unit)
    if not header or not header:IsVisible() then return nil end
    local index = 1
    local child = header:GetAttribute("child1")
    while child do
        if Matches(child, unit) then return child end
        index = index + 1
        child = header:GetAttribute("child" .. index)
    end
end

local function FromEllesmere(unit)
    local selfButton = _G.ERFPartySelfButton
    if unit == "player" and Matches(selfButton, unit) then return selfButton end
    return FromHeader(_G.ERFPartyHeader, unit)
end

local function FromElvUI(unit)
    local header = _G.ElvUF_PartyGroup1
    if not header or not header:IsVisible() then return nil end
    local child = FromHeader(header, unit)
    if child then return child end
    local playerFrame = _G.ElvUF_Player
    if unit == "player" and Matches(playerFrame, unit) then return playerFrame end
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

local PROVIDERS = { FromEllesmere, FromElvUI, FromCompact, FromBlizzard }

function Anchors.Resolve(unit)
    for _, find in ipairs(PROVIDERS) do
        local frame = find(unit)
        if frame then return frame end
    end
    local mock = mocks and mocks[unit]
    if mock and mock:IsVisible() then return mock end
end

function Anchors.SetMocks(map)
    mocks = map
end
