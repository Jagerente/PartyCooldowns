local _, ns = ...

local Self = {}
ns.Self = Self

local GetTime = GetTime
local format, concat, abs = string.format, table.concat, math.abs

local GCD_LIMIT = 1.6
local DRIFT = 0.25
local MAX_PAYLOAD = 190
local VERIFY_DELAY = 0.15
local PET_BANK = Enum.SpellBookSpellBank and Enum.SpellBookSpellBank.Pet

local knownRank = {}
local parts = {}
local customKeys = {}

local function Member()
    local guid = ns.Roster.PlayerGUID()
    return guid and ns.Members.Ensure(guid)
end

local function IsKnown(spellID, isPet)
    if isPet then
        return PET_BANK ~= nil and C_SpellBook.IsSpellKnown(spellID, PET_BANK)
    end
    return C_SpellBook.IsSpellKnown(spellID)
end

local function HighestKnownRank(info)
    local ranks = info.ranks
    for i = #ranks, 1, -1 do
        if IsKnown(ranks[i], info.pet) then
            return ranks[i]
        end
    end
end

local function KnownCustomRank(info)
    local spell = C_Spell.GetSpellInfo(ns.Spells.Name(info.key))
    local rank = spell and spell.spellID
    if rank and IsKnown(rank) then
        ns.Spells.AddRank(info.key, rank)
        return rank
    end
    return HighestKnownRank(info)
end

local function ReadCooldown(spellID)
    local info = C_Spell.GetSpellCooldown(spellID)
    if not info or info.isEnabled == false or info.isOnGCD == true then return nil end
    if info.isActive == false then return 0, 0 end
    local start, duration = info.startTime, info.duration
    if ns.IsSecret(start) or ns.IsSecret(duration) then return nil end
    if duration <= GCD_LIMIT then return 0, 0 end
    return start, duration
end

local function Number(value)
    return (format("%.1f", value):gsub("%.0$", ""))
end

local function ScanSpell(key, member, findRank)
    local rank = ns.Spells.IsAvailable(member, key) and findRank(ns.Spells.Get(key)) or nil
    member.known[key] = rank ~= nil or nil
    if knownRank[key] == rank then return false end
    knownRank[key] = rank
    return true
end

local function ScanList(keys, member, changed, custom)
    local findRank = custom and KnownCustomRank or HighestKnownRank
    for _, key in ipairs(keys) do
        if ns.Spells.Get(key).custom == custom and ScanSpell(key, member, findRank) then
            changed = true
        end
    end
    return changed
end

local function ForgetRemovedSpells(member)
    local changed = false
    for key in pairs(knownRank) do
        if not ns.Spells.Get(key) then
            knownRank[key] = nil
            changed = true
        end
    end
    for key in pairs(member.known) do
        if not ns.Spells.Get(key) then
            member.known[key] = nil
            member.cds[key] = nil
        end
    end
    return changed
end

function Self.RefreshKnown()
    local member = Member()
    if not member or not member.class then return end
    member.synced = true
    member.durations = ns.charDB.learned
    local builtinChanged = ScanList(ns.Spells.ClassList(member.class), member, false, false)
    builtinChanged = ScanList(ns.Spells.RaceList(member.race), member, builtinChanged, false)
    local customChanged = ForgetRemovedSpells(member)
    customChanged = ScanList(ns.Spells.CustomKeys(customKeys), member, customChanged, true)
    if builtinChanged then
        ns.Comm.QueueHello()
    elseif customChanged then
        ns.Comm.QueueCustomKnown()
    end
    if builtinChanged or customChanged then
        ns.Fire("MEMBER_CHANGED", member.guid)
    end
end

local function QueueReset(key)
    ns.Comm.QueueCooldown(key)
end

function Self.Verify(key)
    local spellID = knownRank[key]
    local member = Member()
    if not spellID or not member or ns.Spells.Get(key).pet then return end
    local start, duration = ReadCooldown(spellID)
    if not start then return end
    local entry = member.cds[key]
    if duration == 0 then
        if entry and entry.start + entry.duration - GetTime() > DRIFT then
            ns.Members.ClearCooldown(member, key)
            ns.Comm.QueueCooldown(key)
        end
        return
    end
    member.durations[key] = duration
    if entry and abs(entry.start - start) < DRIFT and abs(entry.duration - duration) < DRIFT then return end
    ns.Members.StartCooldown(member, key, start, duration)
    ns.Comm.QueueCooldown(key)
end

function Self.Reconcile()
    for key in pairs(knownRank) do
        Self.Verify(key)
    end
end

local function OnCast(_, _, _, _, spellID)
    if ns.IsSecret(spellID) then return end
    local key = ns.Spells.KeyFor(spellID)
    local member = Member()
    if not key or not member or not ns.Spells.IsAvailable(member, key) then return end
    if not knownRank[key] then
        Self.RefreshKnown()
    end
    local duration = ns.Members.Duration(member, key)
    if duration > 0 then
        ns.Members.StartCooldown(member, key, GetTime(), duration)
        ns.Comm.QueueCooldown(key)
    end
    ns.Members.ApplyResets(member, key, QueueReset)
    C_Timer.After(VERIFY_DELAY, function() Self.Verify(key) end)
end

local function Append(item, length)
    if length + #item + 1 > MAX_PAYLOAD then return length, false end
    parts[#parts + 1] = item
    return length + #item + 1, true
end

local function EncodeKnownPart(custom)
    local member = Member()
    if not member then return "" end
    wipe(parts)
    local length = 0
    for key in pairs(member.known) do
        if ns.Spells.IsCustom(key) == custom then
            local duration = member.durations[key]
            local item = duration and (key .. ":" .. Number(duration)) or tostring(key)
            local ok
            length, ok = Append(item, length)
            if not ok then break end
        end
    end
    return concat(parts, ",")
end

function Self.EncodeKnown()
    return EncodeKnownPart(false)
end

function Self.EncodeCustomKnown()
    return EncodeKnownPart(true)
end

local function AppendActive(member, now, length, custom)
    for key, entry in pairs(member.cds) do
        local remaining = entry.start + entry.duration - now
        if remaining > 0 and ns.Spells.IsCustom(key) == custom then
            local ok
            length, ok = Append(key .. ":" .. Number(entry.duration) .. ":" .. Number(remaining), length)
            if not ok then return length, false end
        end
    end
    return length, true
end

function Self.EncodeActive()
    local member = Member()
    if not member then return "" end
    wipe(parts)
    local now = GetTime()
    local length, ok = AppendActive(member, now, 0, false)
    if ok then AppendActive(member, now, length, true) end
    return concat(parts, ",")
end

function Self.EncodeCooldown(key)
    local member = Member()
    if not member then return tostring(key) end
    local entry = member.cds[key]
    local remaining = entry and math.max(0, entry.start + entry.duration - GetTime()) or 0
    local duration = entry and entry.duration or ns.Members.Duration(member, key)
    return key .. ":" .. Number(duration) .. ":" .. Number(remaining)
end

local castFrame = CreateFrame("Frame")
castFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet")
castFrame:SetScript("OnEvent", OnCast)

local function QueueRefresh()
    ns.Schedule("self.known", 0.2, Self.RefreshKnown)
end

local function QueueReconcile()
    ns.Schedule("self.reconcile", 0.1, Self.Reconcile)
end

ns.Listen("ROSTER_CHANGED", function()
    if not next(knownRank) then
        Self.RefreshKnown()
        QueueReconcile()
    end
end)

ns.Listen("CUSTOM_SPELLS_CHANGED", Self.RefreshKnown)
ns.RegisterEvent("SPELLS_CHANGED", QueueRefresh)
ns.RegisterEvent("UNIT_PET", function(unit)
    if unit == "player" then QueueRefresh() end
end)
ns.RegisterEvent("SPELL_UPDATE_COOLDOWN", QueueReconcile)
ns.RegisterEvent("PLAYER_REGEN_ENABLED", QueueReconcile)
