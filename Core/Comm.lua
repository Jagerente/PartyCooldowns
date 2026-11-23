local _, ns = ...

local Comm = {}
ns.Comm = Comm

local PREFIX = "PartyCD"
local PROTOCOL = 1
local SEP = ";"
local MAX_TOKENS = 8
local REFILL_PER_SECOND = 1
local RETRY_DELAY = 1
local GREET_DELAY = 1
local REPLY_DELAY_MIN, REPLY_DELAY_SPREAD = 0.3, 0.9

local MSG_REQUEST, MSG_HELLO, MSG_STATE, MSG_COOLDOWN = "R", "H", "S", "C"
local MSG_WATCH, MSG_CUSTOM_KNOWN = "W", "K"

local Results = Enum.SendAddonMessageResult or {}
local RESULT_SUCCESS = Results.Success or 0
local RESULT_LOCKDOWN = Results.AddOnMessageLockdown or 11
local RETRYABLE = {
    [Results.AddonMessageThrottle or 3] = true,
    [Results.ChannelThrottle or 8] = true,
    [Results.GeneralError or 9] = true,
}

local RESTRICTION_CHAT = Enum.AddOnRestrictionType and Enum.AddOnRestrictionType.Chat or 5
local RESTRICTION_INACTIVE = Enum.AddOnRestrictionState and Enum.AddOnRestrictionState.Inactive or 0

local pending = { request = false, watch = false, hello = false, custom = false, state = false, cooldowns = {} }
local tokens, refilledAt = MAX_TOKENS, 0
local blocked = false
local greeted = {}
local customAnnounced = false

local function Channel()
    if IsInRaid() then return nil end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) and not IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "INSTANCE_CHAT"
    end
    if IsInGroup() then return "PARTY" end
    return nil
end
Comm.Channel = Channel

local function IsLockedDown()
    local check = C_ChatInfo.InChatMessagingLockdown
    return check ~= nil and check() == true
end
Comm.IsLockedDown = IsLockedDown

local function Refill()
    local now = GetTime()
    tokens = math.min(MAX_TOKENS, tokens + (now - refilledAt) * REFILL_PER_SECOND)
    refilledAt = now
end

local function ClearPending()
    pending.request = false
    pending.watch = false
    pending.hello = false
    pending.custom = false
    pending.state = false
    wipe(pending.cooldowns)
end

local function NextMessage()
    if pending.request then return MSG_REQUEST end
    if pending.watch then return MSG_WATCH end
    if pending.hello then return MSG_HELLO end
    if pending.custom then return MSG_CUSTOM_KNOWN end
    if pending.state then return MSG_STATE end
    local key = next(pending.cooldowns)
    if key then return MSG_COOLDOWN, key end
end

local function Consume(kind, key)
    if kind == MSG_REQUEST then
        pending.request = false
    elseif kind == MSG_WATCH then
        pending.watch = false
    elseif kind == MSG_HELLO then
        pending.hello = false
    elseif kind == MSG_CUSTOM_KNOWN then
        pending.custom = false
    elseif kind == MSG_STATE then
        pending.state = false
        wipe(pending.cooldowns)
    else
        pending.cooldowns[key] = nil
    end
end

local function Build(kind, key)
    local head = kind .. SEP .. PROTOCOL .. SEP .. ns.Roster.PlayerGUID()
    local body
    if kind == MSG_WATCH then
        body = ns.Custom.EncodeWatch()
    elseif kind == MSG_HELLO then
        body = ns.Self.EncodeKnown()
    elseif kind == MSG_CUSTOM_KNOWN then
        body = ns.Self.EncodeCustomKnown()
        if body == "" and not customAnnounced then return nil end
    elseif kind == MSG_STATE then
        body = ns.Self.EncodeActive()
    elseif kind == MSG_COOLDOWN then
        body = ns.Self.EncodeCooldown(key)
    end
    if not body then return head end
    return head .. SEP .. body, body
end

local function Send(message)
    local channel = Channel()
    if not channel then return "drop" end
    local result = C_ChatInfo.SendAddonMessage(PREFIX, message, channel)
    if result == nil or result == true or result == RESULT_SUCCESS then return "sent" end
    if result == RESULT_LOCKDOWN then return "locked" end
    if RETRYABLE[result] then return "retry" end
    return "drop"
end

local QueueFlush

local function SendNext(kind, key)
    local message, body = Build(kind, key)
    if not message then return true end
    if tokens < 1 then
        QueueFlush((1 - tokens) / REFILL_PER_SECOND)
        return false
    end
    local outcome = Send(message)
    if outcome == "locked" then
        blocked = true
        return false
    elseif outcome == "retry" then
        QueueFlush(RETRY_DELAY)
        return false
    end
    tokens = tokens - 1
    if kind == MSG_CUSTOM_KNOWN then customAnnounced = body ~= "" end
    return true
end

function Comm.Flush()
    if not Channel() or not ns.Roster.PlayerGUID() then
        ClearPending()
        return
    end
    if IsLockedDown() then
        blocked = true
        return
    end
    blocked = false
    Refill()
    while true do
        local kind, key = NextMessage()
        if not kind or not SendNext(kind, key) then return end
        Consume(kind, key)
    end
end

QueueFlush = function(delay)
    ns.Schedule("comm.flush", delay or 0, Comm.Flush)
end

function Comm.QueueHello()
    pending.hello = true
    pending.custom = true
    QueueFlush()
end

function Comm.QueueCustomKnown()
    pending.custom = true
    QueueFlush()
end

function Comm.QueueWatch()
    pending.watch = true
    QueueFlush()
end

function Comm.QueueState()
    pending.state = true
    QueueFlush()
end

function Comm.QueueCooldown(key)
    pending.cooldowns[key] = true
    QueueFlush()
end

function Comm.RequestSync()
    pending.request = true
    pending.watch = true
    pending.hello = true
    pending.custom = true
    pending.state = true
    QueueFlush()
end

function Comm.IsBlocked()
    return blocked or IsLockedDown()
end

local function ScheduleReply()
    local delay = REPLY_DELAY_MIN + math.random() * REPLY_DELAY_SPREAD
    ns.Schedule("comm.reply", delay, function()
        pending.watch = pending.watch or ns.Custom.HasLocal()
        pending.hello = true
        pending.custom = true
        pending.state = true
        Comm.Flush()
    end)
end

local function ParseEntry(text)
    local key, duration, remaining = strsplit(":", text)
    key = tonumber(key)
    if not key or not ns.Spells.Get(key) then return nil end
    return key, tonumber(duration) or 0, tonumber(remaining) or 0
end

local helloKnown, helloDurations, stateActive, watched = {}, {}, {}, {}

local function ParseKnown(payload)
    wipe(helloKnown)
    wipe(helloDurations)
    for item in string.gmatch(payload or "", "[^,]+") do
        local key, duration = ParseEntry(item)
        if key then
            helloKnown[key] = true
            if duration > 0 then helloDurations[key] = duration end
        end
    end
end

local function OnHello(member, version, payload)
    ParseKnown(payload)
    ns.Members.ApplyHello(member, version, helloKnown, helloDurations)
end

local function OnCustomKnown(member, payload)
    ParseKnown(payload)
    ns.Members.ApplyCustomKnown(member, helloKnown, helloDurations)
end

local function OnWatch(guid, payload)
    wipe(watched)
    local count = 0
    for item in string.gmatch(payload or "", "[^,]+") do
        local spellID = tonumber(item)
        if spellID and spellID > 0 and count < ns.Custom.MAX_SPELLS then
            watched[spellID] = true
            count = count + 1
        end
    end
    if ns.Custom.SetWants(guid, watched) then
        Comm.QueueCustomKnown()
    end
end

local function OnState(member, payload)
    wipe(stateActive)
    for item in string.gmatch(payload or "", "[^,]+") do
        local key, duration, remaining = ParseEntry(item)
        if key and remaining > 0 and duration > 0 then
            stateActive[key] = { duration = duration, remaining = remaining }
        end
    end
    ns.Members.ApplyState(member, stateActive)
end

local function OnCooldown(member, payload)
    local key, duration, remaining = ParseEntry(payload or "")
    if key then
        ns.Members.ApplyRemote(member, key, duration, remaining)
    end
end

local function OnMessage(prefix, text)
    if ns.IsSecret(prefix) or ns.IsSecret(text) or prefix ~= PREFIX then return end
    local kind, version, guid, payload = strsplit(SEP, text, 4)
    version = tonumber(version)
    if not version or not guid or guid == ns.Roster.PlayerGUID() then return end
    local member = ns.Members.Ensure(guid)
    if kind == MSG_REQUEST then
        ScheduleReply()
    elseif kind == MSG_WATCH then
        OnWatch(guid, payload)
    elseif kind == MSG_HELLO then
        OnHello(member, version, payload)
    elseif kind == MSG_CUSTOM_KNOWN then
        OnCustomKnown(member, payload)
    elseif kind == MSG_STATE then
        OnState(member, payload)
    elseif kind == MSG_COOLDOWN then
        OnCooldown(member, payload)
    end
end

local function GreetNewMembers()
    if ns.TestMode.active then return end
    local hasNew = false
    local present = {}
    for _, unit in ipairs(ns.Roster.UNITS) do
        local guid = unit ~= "player" and ns.Roster.GUID(unit)
        if guid then
            present[guid] = true
            if not greeted[guid] then hasNew = true end
        end
    end
    greeted = present
    if hasNew and Channel() then
        ns.Schedule("comm.greet", GREET_DELAY, Comm.RequestSync)
    end
end

local function RetryIfBlocked()
    if blocked then QueueFlush(0.1) end
end

C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)

ns.Listen("ROSTER_CHANGED", GreetNewMembers)

ns.RegisterEvent("CHAT_MSG_ADDON", OnMessage)

ns.RegisterEvent("ADDON_RESTRICTION_STATE_CHANGED", function(restriction, state)
    if restriction == RESTRICTION_CHAT and state == RESTRICTION_INACTIVE then
        RetryIfBlocked()
    end
end)

ns.RegisterEvent("PLAYER_REGEN_ENABLED", RetryIfBlocked)
ns.RegisterEvent("ENCOUNTER_END", RetryIfBlocked)
ns.RegisterEvent("PLAYER_ENTERING_WORLD", RetryIfBlocked)
