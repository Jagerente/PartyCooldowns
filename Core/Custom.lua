local _, ns = ...

local Custom = {}
ns.Custom = Custom

local MAX_SPELLS = 20
Custom.MAX_SPELLS = MAX_SPELLS

local wants = {}

local function IsValidEntry(entry)
    return type(entry) == "table" and type(entry.id) == "number" and type(entry.class) == "string"
        and ns.SpellData.classes[entry.class] ~= nil and not ns.Spells.IsBuiltin(entry.id)
end

local function Sanitize()
    local list = ns.db.custom
    for i = #list, 1, -1 do
        if not IsValidEntry(list[i]) then
            table.remove(list, i)
        end
    end
end

local function Rebuild(isLocal)
    local entries, seen = {}, {}
    for _, entry in ipairs(ns.db.custom) do
        entries[#entries + 1] = { id = entry.id, class = entry.class }
        seen[entry.id] = true
    end
    for _, ids in pairs(wants) do
        for id in pairs(ids) do
            if not seen[id] then
                seen[id] = true
                entries[#entries + 1] = { id = id }
            end
        end
    end
    ns.Spells.SetCustom(entries)
    ns.Fire("CUSTOM_SPELLS_CHANGED", isLocal == true)
end

local function Find(spellID)
    for index, entry in ipairs(ns.db.custom) do
        if entry.id == spellID then return index, entry end
    end
end

function Custom.KeysFor(class, out)
    wipe(out)
    for _, entry in ipairs(ns.db.custom) do
        if entry.class == class then
            out[#out + 1] = entry.id
        end
    end
    return out
end

function Custom.IsLocal(spellID)
    return Find(spellID) ~= nil
end

function Custom.Resolve(text)
    text = strtrim(text or "")
    if text == "" then return nil end
    local id = tonumber(text:match("spell:(%d+)") or text:match("^#?(%d+)$"))
    if id then return id end
    local info = C_Spell.GetSpellInfo(text)
    return info and info.spellID
end

function Custom.Add(text, class)
    local spellID = Custom.Resolve(text)
    if not spellID or not C_Spell.DoesSpellExist(spellID) then
        return false, "CUSTOM_ERROR_NOT_FOUND"
    end
    local key = ns.Spells.KeyFor(spellID)
    if key and ns.Spells.IsBuiltin(spellID) then
        return false, "CUSTOM_ERROR_BUILTIN", key
    end
    if Custom.IsLocal(spellID) or (key and Custom.IsLocal(key)) then
        return false, "CUSTOM_ERROR_ADDED", key or spellID
    end
    if #ns.db.custom >= MAX_SPELLS then
        return false, "CUSTOM_ERROR_LIMIT"
    end
    table.insert(ns.db.custom, { id = spellID, class = class })
    Rebuild(true)
    ns.Comm.QueueWatch()
    return true, nil, spellID
end

function Custom.Remove(spellID)
    local index = Find(spellID)
    if not index then return end
    table.remove(ns.db.custom, index)
    ns.db.spells[spellID] = nil
    Rebuild(true)
    ns.Comm.QueueWatch()
end

function Custom.HasLocal()
    return #ns.db.custom > 0
end

function Custom.EncodeWatch()
    local ids = {}
    for i, entry in ipairs(ns.db.custom) do
        ids[i] = entry.id
    end
    return table.concat(ids, ",")
end

local function SameSet(a, b)
    for key in pairs(a) do
        if not b[key] then return false end
    end
    for key in pairs(b) do
        if not a[key] then return false end
    end
    return true
end

function Custom.SetWants(guid, ids)
    local previous = wants[guid] or {}
    if SameSet(previous, ids) then return false end
    local copy = {}
    for id in pairs(ids) do
        if not ns.Spells.IsBuiltin(id) then
            copy[id] = true
        end
    end
    wants[guid] = next(copy) and copy or nil
    Rebuild(false)
    return true
end

local function ForgetDepartedWants()
    if ns.TestMode.active then return end
    local changed = false
    for guid in pairs(wants) do
        if not ns.Roster.Unit(guid) then
            wants[guid] = nil
            changed = true
        end
    end
    if changed then Rebuild(false) end
end

ns.Listen("DB_READY", function()
    Sanitize()
    Rebuild(true)
end)

ns.Listen("ROSTER_CHANGED", ForgetDepartedWants)
