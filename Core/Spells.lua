local _, ns = ...

local Spells = {}
ns.Spells = Spells

local EMPTY = {}
local FALLBACK_ICON = 134400
local MS_PER_SECOND = 1000

local byKey = {}
local rankToKey = {}
local builtinClassLists = {}
local classLists = {}
local raceLists = {}
local iconCache = {}

local function NameSet(names)
    if not names then return nil end
    local set = {}
    for _, name in ipairs(names) do
        set[name] = true
    end
    return set
end

local function Register(entry, class, race)
    local info = {
        key = entry.id,
        cd = entry.cd,
        cat = entry.cat,
        default = entry.on == true,
        talent = entry.talent == true,
        pet = entry.pet == true,
        custom = false,
        resets = entry.resets,
        class = class,
        race = race,
        races = NameSet(entry.races),
        raceList = entry.races,
        faction = entry.faction,
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
    for _, key in ipairs(builtinClassLists[info.class]) do
        if key ~= info.key then
            resets[#resets + 1] = key
        end
    end
    info.resets = resets
end

for class, entries in pairs(ns.SpellData.classes) do
    builtinClassLists[class] = BuildList(entries, class, nil)
    classLists[class] = builtinClassLists[class]
end

for race, entries in pairs(ns.SpellData.races) do
    raceLists[race] = BuildList(entries, nil, race)
end

for _, info in pairs(byKey) do
    ExpandClassResets(info)
end

local function BaseCooldown(spellID)
    local milliseconds = GetSpellBaseCooldown and GetSpellBaseCooldown(spellID)
    if type(milliseconds) ~= "number" or milliseconds <= 0 then return 0 end
    return milliseconds / MS_PER_SECOND
end

local function RegisterCustom(spellID)
    local info = {
        key = spellID,
        cd = BaseCooldown(spellID),
        default = true,
        custom = true,
        ranks = { spellID },
    }
    byKey[spellID] = info
    rankToKey[spellID] = spellID
    return info
end

local function UnregisterCustom(info)
    for _, rank in ipairs(info.ranks) do
        if rankToKey[rank] == info.key then
            rankToKey[rank] = nil
        end
    end
    byKey[info.key] = nil
end

local function IsBuiltin(spellID)
    local key = rankToKey[spellID]
    return key ~= nil and not byKey[key].custom
end

local function RebuildClassLists(entries)
    for class, builtin in pairs(builtinClassLists) do
        local list = {}
        for i = 1, #builtin do
            list[i] = builtin[i]
        end
        classLists[class] = list
    end
    for _, entry in ipairs(entries) do
        local list = entry.class and classLists[entry.class]
        if list and byKey[entry.id] then
            list[#list + 1] = entry.id
        end
    end
end

function Spells.SetCustom(entries)
    local wanted = {}
    for _, entry in ipairs(entries) do
        wanted[entry.id] = true
    end
    for key, info in pairs(byKey) do
        if info.custom and not wanted[key] then
            UnregisterCustom(info)
        end
    end
    for _, entry in ipairs(entries) do
        if not IsBuiltin(entry.id) then
            local info = byKey[entry.id] or RegisterCustom(entry.id)
            info.class = entry.class
        end
    end
    RebuildClassLists(entries)
end

function Spells.AddRank(key, rank)
    local info = byKey[key]
    if not info or rankToKey[rank] then return end
    rankToKey[rank] = key
    info.ranks[#info.ranks + 1] = rank
end

function Spells.IsBuiltin(spellID)
    return IsBuiltin(spellID)
end

function Spells.IsCustom(key)
    local info = byKey[key]
    return info == nil or info.custom == true
end

function Spells.CustomKeys(out)
    wipe(out)
    for key, info in pairs(byKey) do
        if info.custom then
            out[#out + 1] = key
        end
    end
    return out
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
    if icon then return icon end
    icon = C_Spell.GetSpellTexture(key)
    if not icon then return FALLBACK_ICON end
    iconCache[key] = icon
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

function Spells.IsAvailable(member, key)
    local info = byKey[key]
    if not info then return false end
    if info.class then
        if info.class ~= member.class then return false end
    elseif info.race and info.race ~= member.race then
        return false
    end
    if info.races and not (member.race and info.races[member.race]) then return false end
    if info.faction and member.faction and info.faction ~= member.faction then return false end
    return true
end

local function IsShownFor(member, key)
    if not Spells.IsEnabled(key) or not Spells.IsAvailable(member, key) then return false end
    if member.synced then
        return member.known[key] == true
    end
    local info = byKey[key]
    return not (info.talent or info.custom) or member.cds[key] ~= nil
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
