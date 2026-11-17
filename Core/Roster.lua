local _, ns = ...

local Roster = {}
ns.Roster = Roster

local UNITS = { "player", "party1", "party2", "party3", "party4" }
Roster.UNITS = UNITS

local unitGUID = {}
local guidUnit = {}
local override

local function Second(_, value)
    return value
end

local function ReadUnit(unit)
    local guid = ns.Plain(UnitGUID(unit))
    if not guid then return nil end
    local member = ns.Members.Ensure(guid)
    member.unit = unit
    member.isPlayer = unit == "player"
    member.name = ns.Plain(UnitName(unit)) or member.name
    member.class = ns.Plain(Second(UnitClass(unit))) or member.class
    member.race = ns.Plain(Second(UnitRace(unit))) or member.race
    member.faction = ns.Plain((UnitFactionGroup(unit))) or member.faction
    return guid
end

local function InParty()
    return IsInGroup() and not IsInRaid()
end

local function ForgetDeparted(stillGrouped)
    for guid, member in ns.Members.Each() do
        if not guidUnit[guid] then
            member.unit = nil
            if not stillGrouped then
                ns.Members.Forget(guid)
            end
        end
    end
end

function Roster.Refresh()
    if override then
        ns.Fire("ROSTER_CHANGED")
        return
    end
    wipe(unitGUID)
    wipe(guidUnit)
    local grouped = InParty()
    for _, unit in ipairs(UNITS) do
        local guid = (unit == "player" or grouped) and ReadUnit(unit) or nil
        if guid then
            unitGUID[unit] = guid
            guidUnit[guid] = unit
        end
    end
    ForgetDeparted(grouped)
    ns.Fire("ROSTER_CHANGED")
end

function Roster.GUID(unit)
    if override then return override[unit] end
    return unitGUID[unit]
end

function Roster.Unit(guid)
    if override then
        for unit, overrideGUID in pairs(override) do
            if overrideGUID == guid then return unit end
        end
        return nil
    end
    return guidUnit[guid]
end

function Roster.PlayerGUID()
    return unitGUID.player
end

function Roster.InParty()
    return InParty()
end

function Roster.SetOverride(map)
    override = map
    if not map then
        Roster.Refresh()
    else
        ns.Fire("ROSTER_CHANGED")
    end
end

local function QueueRefresh()
    ns.Schedule("roster", 0.05, Roster.Refresh)
end

ns.Listen("LOGIN", Roster.Refresh)
ns.RegisterEvent("GROUP_ROSTER_UPDATE", QueueRefresh)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", QueueRefresh)
ns.RegisterEvent("UNIT_CONNECTION", QueueRefresh)
