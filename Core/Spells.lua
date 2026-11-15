local _, ns = ...

local Spells = {}
ns.Spells = Spells

local EMPTY = {}
local FALLBACK_ICON = 134400

local byKey = {}
local rankToKey = {}
local classLists = {}
local raceLists = {}
local iconCache = {}

local function Register(entry, class, race)
    local info = {
        key = entry.id,
        cd = entry.cd,
        cat = entry.cat,
        default = entry.on == true,
        talent = entry.talent == true,
        pet = entry.pet == true,
        resets = entry.resets,
        class = class,
        race = race,
        ranks = { entry.id },
    }
    for _, rank in ipairs(entry.ranks or EMPTY) do
        info.ranks[#info.ranks + 1] = rank
    end
    for _, rank in ipairs(info.ranks) do
        rankToKey[rank] = entry.id
    end
    byKey[entry.id] = info
    return entry.id
end

local function BuildList(entries, class, race)
    local keys = {}
    for i, entry in ipairs(entries) do
        keys[i] = Register(entry, class, race)
    end
    return keys
end

local function ExpandClassResets(info)
    if info.resets ~= "class" then return end
    local resets = {}
    for _, key in ipairs(classLists[info.class]) do
        if key ~= info.key then
            resets[#resets + 1] = key
        end
    end
    info.resets = resets
end

for class, entries in pairs(ns.SpellData.classes) do
    classLists[class] = BuildList(entries, class, nil)
end

for race, entries in pairs(ns.SpellData.races) do
    raceLists[race] = BuildList(entries, nil, race)
end

for _, info in pairs(byKey) do
    ExpandClassResets(info)
end

function Spells.Get(key)
    return byKey[key]
end

function Spells.KeyFor(spellID)
    return rankToKey[spellID]
end

function Spells.ClassList(class)
    return classLists[class] or EMPTY
end

function Spells.RaceList(race)
    return raceLists[race] or EMPTY
end

function Spells.Name(key)
    return C_Spell.GetSpellName(key) or ("#" .. key)
end

function Spells.Icon(key)
    local icon = iconCache[key]
    if not icon then
        icon = C_Spell.GetSpellTexture(key) or FALLBACK_ICON
        iconCache[key] = icon
    end
    return icon
end

function Spells.IsEnabled(key)
    local override = ns.db.spells[key]
    if override ~= nil then return override end
    return byKey[key].default
end

local function StoreChoice(key, enabled)
    if enabled == byKey[key].default then
        ns.db.spells[key] = nil
    else
        ns.db.spells[key] = enabled
    end
end

function Spells.SetEnabled(key, enabled)
    StoreChoice(key, enabled)
    ns.Fire("SETTING_CHANGED", "spells")
end

function Spells.ResetGroup(keys)
    for _, key in ipairs(keys) do
        ns.db.spells[key] = nil
    end
    ns.Fire("SETTING_CHANGED", "spells")
end

function Spells.SetGroup(keys, enabled)
    for _, key in ipairs(keys) do
        StoreChoice(key, enabled)
    end
    ns.Fire("SETTING_CHANGED", "spells")
end

local function IsShownFor(member, key)
    if not Spells.IsEnabled(key) then return false end
    if member.synced then
        return member.known[key] == true
    end
    return not byKey[key].talent or member.cds[key] ~= nil
end

local function Collect(member, keys, out)
    for i = 1, #keys do
        local key = keys[i]
        if IsShownFor(member, key) then
            out[#out + 1] = key
        end
    end
end

function Spells.CollectFor(member, out)
    wipe(out)
    Collect(member, Spells.ClassList(member.class), out)
    Collect(member, Spells.RaceList(member.race), out)
    return out
end
