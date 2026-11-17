local _, ns = ...

local Members = {}
ns.Members = Members

local GetTime = GetTime
local records = {}

function Members.Get(guid)
    return records[guid]
end

function Members.Ensure(guid)
    local member = records[guid]
    if not member then
        member = {
            guid = guid,
            known = {},
            durations = {},
            cds = {},
            synced = false,
        }
        records[guid] = member
    end
    return member
end

function Members.Forget(guid)
    records[guid] = nil
end

function Members.Each()
    return pairs(records)
end

function Members.Duration(member, key)
    return member.durations[key] or ns.Spells.Get(key).cd
end

function Members.Remaining(member, key, now)
    local entry = member.cds[key]
    if not entry then return 0 end
    return entry.start + entry.duration - (now or GetTime())
end

local function Changed(member, key)
    ns.Fire("COOLDOWN_CHANGED", member.guid, key)
end

function Members.StartCooldown(member, key, start, duration, estimated)
    local entry = member.cds[key]
    if not entry then
        entry = {}
        member.cds[key] = entry
    end
    entry.start = start
    entry.duration = duration
    entry.estimated = estimated == true
    Changed(member, key)
end

function Members.ClearCooldown(member, key)
    if not member.cds[key] then return end
    member.cds[key] = nil
    Changed(member, key)
end

function Members.ApplyRemote(member, key, duration, remaining)
    if duration > 0 then
        member.durations[key] = duration
    end
    if remaining > 0 then
        local now = GetTime()
        Members.StartCooldown(member, key, now - (duration - remaining), duration)
    else
        Members.ClearCooldown(member, key)
    end
end

function Members.ApplyHello(member, version, known, durations)
    member.synced = true
    member.version = version
    wipe(member.known)
    for key in pairs(known) do
        member.known[key] = true
    end
    for key, duration in pairs(durations) do
        member.durations[key] = duration
    end
    ns.Fire("MEMBER_CHANGED", member.guid)
end

function Members.ApplyState(member, active)
    wipe(member.cds)
    local now = GetTime()
    for key, data in pairs(active) do
        member.durations[key] = data.duration
        member.cds[key] = {
            start = now - (data.duration - data.remaining),
            duration = data.duration,
        }
    end
    ns.Fire("MEMBER_CHANGED", member.guid)
end

function Members.ApplyResets(member, key, onCleared)
    local resets = ns.Spells.Get(key).resets
    if not resets then return end
    for _, resetKey in ipairs(resets) do
        if member.cds[resetKey] then
            Members.ClearCooldown(member, resetKey)
            if onCleared then onCleared(resetKey) end
        end
    end
end

function Members.PruneExpired(member, now)
    for key, entry in pairs(member.cds) do
        if entry.start + entry.duration <= now then
            member.cds[key] = nil
        end
    end
end
