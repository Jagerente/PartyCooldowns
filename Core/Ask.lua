local _, ns = ...

local L = ns.L

local Ask = {}
ns.Ask = Ask

local format = string.format

local REPEAT_SECONDS = 5
local CHANNEL_WHISPER = "whisper"
local CHAT_TYPE_WHISPER = "WHISPER"

function Ask.IsAvailable(member, key)
    if not ns.db.askOnClick or not member.name then return false end
    if not member.unit or member.unit == "player" then return false end
    return ns.Members.Remaining(member, key) <= 0
end

local function AskedRecently(member, key, now)
    local askedAt = member.asked[key]
    return askedAt ~= nil and now - askedAt < REPEAT_SECONDS
end

local function BuildMessage(member, key)
    local spell = ns.Spells.Name(key)
    if ns.db.askChannel == CHANNEL_WHISPER then
        return format(L.ASK_MESSAGE_whisper, spell)
    end
    return format(L.ASK_MESSAGE_party, member.name, spell)
end

local function WhisperTarget(member)
    local name, realm = UnitFullName(member.unit)
    name, realm = ns.Plain(name), ns.Plain(realm)
    if not name then return member.name end
    if realm and realm ~= "" then return name .. "-" .. realm end
    return name
end

local function BlockedReason(member)
    if ns.Comm.IsLockedDown() then return L.ASK_LOCKED end
    if not UnitIsConnected(member.unit) then return format(L.ASK_OFFLINE, member.name) end
end

local function Deliver(member, message)
    local reason = BlockedReason(member)
    if reason then
        UIErrorsFrame:AddExternalErrorMessage(reason)
        return false
    end
    if ns.db.askChannel == CHANNEL_WHISPER then
        C_ChatInfo.SendChatMessage(message, CHAT_TYPE_WHISPER, nil, WhisperTarget(member))
        return true
    end
    local channel = ns.Comm.Channel()
    if not channel then return false end
    C_ChatInfo.SendChatMessage(message, channel)
    return true
end

function Ask.Request(member, key)
    if not Ask.IsAvailable(member, key) then return false end
    local now = GetTime()
    if AskedRecently(member, key, now) then return false end
    local message = BuildMessage(member, key)
    if ns.TestMode.active then
        print(format(L.ASK_PREVIEW, message))
    elseif not Deliver(member, message) then
        return false
    end
    member.asked[key] = now
    return true
end
