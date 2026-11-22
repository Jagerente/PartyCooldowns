local _, ns = ...

local DEFAULTS = {
    enabled = true,
    locale = "auto",
    provider = "auto",
    side = "RIGHT",
    align = "CENTER",
    offsetX = 4,
    offsetY = 0,
    size = 28,
    spacing = 3,
    perRow = 6,
    showSelf = false,
    showUnsynced = true,
    hideReady = false,
    tooltips = true,
    timerText = true,
    timerDecimals = true,
    swipe = true,
    desaturate = true,
    pulse = true,
    skin = "flat",
    minimap = { hide = false, angle = 200 },
    spells = {},
    custom = {},
}

local CHAR_DEFAULTS = {
    learned = {},
}

ns.DEFAULTS = DEFAULTS

local function ApplyDefaults(target, defaults)
    for key, value in pairs(defaults) do
        if type(value) == "table" then
            target[key] = ApplyDefaults(type(target[key]) == "table" and target[key] or {}, value)
        elseif target[key] == nil then
            target[key] = value
        end
    end
    return target
end

ns.Listen("INIT", function()
    PartyCooldownsDB = ApplyDefaults(PartyCooldownsDB or {}, DEFAULTS)
    PartyCooldownsCharDB = ApplyDefaults(PartyCooldownsCharDB or {}, CHAR_DEFAULTS)
    ns.db = PartyCooldownsDB
    ns.charDB = PartyCooldownsCharDB
    ns.Fire("DB_READY")
end)

function ns.Get(key)
    return ns.db[key]
end

function ns.Set(key, value)
    if ns.db[key] == value then return end
    ns.db[key] = value
    ns.Fire("SETTING_CHANGED", key, value)
end

function ns.ResetSettings()
    local custom = ns.db.custom
    wipe(ns.db)
    ApplyDefaults(ns.db, DEFAULTS)
    ns.db.custom = custom
    ns.Fire("SETTING_CHANGED")
end
