local _, ns = ...

local GetTime = GetTime
local SYNC_GRACE = 1

local function OnPartyCast(_, _, unit, _, spellID)
    if ns.IsSecret(spellID) then return end
    local key = ns.Spells.KeyFor(spellID)
    local guid = key and ns.Roster.GUID(unit)
    local member = guid and ns.Members.Get(guid)
    if not member or not ns.Members.Owns(member, key) then return end
    local entry = member.cds[key]
    local now = GetTime()
    if entry and not entry.estimated and now - entry.start < SYNC_GRACE then return end
    ns.Members.StartCooldown(member, key, now, ns.Members.Duration(member, key), not member.synced)
    ns.Members.ApplyResets(member, key)
end

for _, units in ipairs({ { "party1", "party2" }, { "party3", "party4" } }) do
    local frame = CreateFrame("Frame")
    frame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", units[1], units[2])
    frame:SetScript("OnEvent", OnPartyCast)
end
