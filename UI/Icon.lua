local _, ns = ...

local UI = ns.UI
local L = ns.L

local Icon = {}
ns.Icon = Icon

local ceil, format = math.ceil, string.format

local TEXCOORD_INSET = 0.08
local FLAT_SWIPE_ALPHA = 0.72
local BLIZZARD_FRAME_ATLAS = "UI-HUD-ActionBar-IconFrame"
local BLIZZARD_MASK_ATLAS = "UI-HUD-ActionBar-IconFrame-Mask"
local BLIZZARD_BUTTON_SIZE, BLIZZARD_FRAME_WIDTH, BLIZZARD_COOLDOWN_INSET = 45, 46, 3
local BLIZZARD_MASK_SIZE = 64
local BLIZZARD_SWIPE_ALPHA = 0.64
local URGENT_SECONDS = 5
local PULSE_SCALE = 1.22
local UNKNOWN_ALPHA = 0.45
local MIN_FONT, FONT_RATIO = 9, 0.42

local function Bucket(remaining, decimals)
    if remaining >= 3600 then return 2000000 + ceil(remaining / 3600) end
    if remaining >= 60 then return 1000000 + ceil(remaining / 60) end
    if decimals and remaining < 10 then return -ceil(remaining * 10) end
    return ceil(remaining)
end

local function FormatRemaining(remaining, decimals)
    if remaining >= 3600 then return format("%dh", ceil(remaining / 3600)) end
    if remaining >= 60 then return format("%dm", ceil(remaining / 60)) end
    if decimals and remaining < 10 then return format("%.1f", ceil(remaining * 10) / 10) end
    return format("%d", ceil(remaining))
end

local function CreatePulse(button)
    local group = button:CreateAnimationGroup()
    local grow = group:CreateAnimation("Scale")
    grow:SetOrder(1)
    grow:SetDuration(0.12)
    grow:SetScaleFrom(1, 1)
    grow:SetScaleTo(PULSE_SCALE, PULSE_SCALE)
    grow:SetSmoothing("OUT")
    local settle = group:CreateAnimation("Scale")
    settle:SetOrder(2)
    settle:SetDuration(0.25)
    settle:SetScaleFrom(PULSE_SCALE, PULSE_SCALE)
    settle:SetScaleTo(1, 1)
    settle:SetSmoothing("IN_OUT")
    button.pulse = group

    local flash = button.overlay:CreateTexture(nil, "OVERLAY")
    flash:SetAllPoints(button.icon)
    button.flashTexture = flash
    flash:SetColorTexture(1, 1, 1, 1)
    flash:SetBlendMode("ADD")
    flash:SetAlpha(0)
    local flashGroup = flash:CreateAnimationGroup()
    local fade = flashGroup:CreateAnimation("Alpha")
    fade:SetFromAlpha(0.55)
    fade:SetToAlpha(0)
    fade:SetDuration(0.45)
    fade:SetSmoothing("OUT")
    button.flash = flashGroup
end

local function ShowTooltip(button)
    if not button.key then return end
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(button.key)
    local member = button.member
    local remaining = ns.Members.Remaining(member, button.key)
    GameTooltip:AddLine(" ")
    if remaining > 0 then
        GameTooltip:AddLine(format(L.TOOLTIP_COOLDOWN, FormatRemaining(remaining, true)), unpack(UI.COLORS.warn))
    elseif member.synced or member.cds[button.key] then
        GameTooltip:AddLine(L.TOOLTIP_READY, unpack(UI.COLORS.good))
    else
        GameTooltip:AddLine(L.TOOLTIP_UNKNOWN, unpack(UI.COLORS.muted))
    end
    if member.name then
        local r, g, b = UI.ClassColor(member.class)
        GameTooltip:AddLine(member.name, r, g, b)
    end
    if not member.synced then
        GameTooltip:AddLine(L.TOOLTIP_NO_SYNC, 0.6, 0.63, 0.69, true)
    end
    GameTooltip:Show()
end

local function HideTooltip(button)
    if GameTooltip:IsOwned(button) then GameTooltip:Hide() end
end

function Icon.Create(parent)
    local button = CreateFrame("Frame", nil, parent)
    button.background = UI.Fill(button, { 0, 0, 0, 0.85 }, "BACKGROUND")

    local icon = button:CreateTexture(nil, "ARTWORK")
    button.icon = icon

    button.mask = button:CreateMaskTexture()
    button.mask:SetAtlas(BLIZZARD_MASK_ATLAS)
    button.mask:SetPoint("CENTER", icon)

    local cooldown = CreateFrame("Cooldown", nil, button, "CooldownFrameTemplate")
    cooldown:SetDrawEdge(false)
    cooldown:SetDrawBling(false)
    cooldown:SetHideCountdownNumbers(true)
    cooldown.noCooldownCount = true
    button.cooldown = cooldown

    local overlay = CreateFrame("Frame", nil, button)
    overlay:SetAllPoints()
    overlay:SetFrameLevel(cooldown:GetFrameLevel() + 2)
    button.overlay = overlay
    button.border = UI.Border(overlay, UI.COLORS.iconBorder, "OVERLAY")
    button.frame = overlay:CreateTexture(nil, "ARTWORK")
    button.frame:SetAtlas(BLIZZARD_FRAME_ATLAS)
    button.frame:SetPoint("TOPLEFT")

    button.timer = overlay:CreateFontString(nil, "OVERLAY")
    button.timer:SetPoint("CENTER", 1, 0)

    CreatePulse(button)
    button:SetScript("OnEnter", ShowTooltip)
    button:SetScript("OnLeave", HideTooltip)
    return button
end

local function SetMasked(button, masked)
    if button.masked == masked then return end
    button.masked = masked
    if masked then
        button.icon:AddMaskTexture(button.mask)
        button.flashTexture:AddMaskTexture(button.mask)
    else
        button.icon:RemoveMaskTexture(button.mask)
        button.flashTexture:RemoveMaskTexture(button.mask)
    end
end

local function SetBorderShown(button, shown)
    for _, texture in ipairs(button.border) do
        texture:SetShown(shown)
    end
end

local function ApplyFlatSkin(button, _, pixel)
    button.icon:ClearAllPoints()
    button.icon:SetPoint("TOPLEFT", pixel, -pixel)
    button.icon:SetPoint("BOTTOMRIGHT", -pixel, pixel)
    button.icon:SetTexCoord(TEXCOORD_INSET, 1 - TEXCOORD_INSET, TEXCOORD_INSET, 1 - TEXCOORD_INSET)
    SetMasked(button, false)
    button.background:Show()
    button.frame:Hide()
    UI.UpdateBorder(button.overlay, button.border)
    SetBorderShown(button, true)
    button.cooldown:ClearAllPoints()
    button.cooldown:SetAllPoints(button.icon)
    button.cooldown:SetSwipeColor(0, 0, 0, FLAT_SWIPE_ALPHA)
end

local function ApplyBlizzardSkin(button, size)
    local scale = size / BLIZZARD_BUTTON_SIZE
    local inset = BLIZZARD_COOLDOWN_INSET * scale
    button.icon:ClearAllPoints()
    button.icon:SetAllPoints(button)
    button.icon:SetTexCoord(0, 1, 0, 1)
    button.mask:SetSize(BLIZZARD_MASK_SIZE * scale, BLIZZARD_MASK_SIZE * scale)
    SetMasked(button, true)
    button.background:Hide()
    button.frame:SetSize(BLIZZARD_FRAME_WIDTH * scale, size)
    button.frame:Show()
    SetBorderShown(button, false)
    button.cooldown:ClearAllPoints()
    button.cooldown:SetPoint("TOPLEFT", button.icon, "TOPLEFT", inset, -inset)
    button.cooldown:SetPoint("BOTTOMRIGHT", button.icon, "BOTTOMRIGHT", -inset, inset)
    button.cooldown:SetSwipeColor(0, 0, 0, BLIZZARD_SWIPE_ALPHA)
end

local SKINS = {
    flat = { apply = ApplyFlatSkin, font = UI.NumberFont },
    blizzard = { apply = ApplyBlizzardSkin, font = UI.GameFont },
}

local function ApplySkin(button, size, skinName)
    local skin = SKINS[skinName] or SKINS.flat
    local pixel = UI.PixelSize(button)
    if button.skin == skin and button.skinSize == size and button.skinPixel == pixel then return end
    button.skin, button.skinSize, button.skinPixel = skin, size, pixel
    skin.apply(button, size, pixel)
    local fontSize = math.max(MIN_FONT, math.floor(size * FONT_RATIO))
    button.timer:SetFontObject(skin.font(fontSize, "OUTLINE"))
end

function Icon.Configure(button, size)
    local db = ns.db
    button:SetSize(size, size)
    ApplySkin(button, size, db.skin)
    button.cooldown:SetDrawSwipe(db.swipe)
    button:EnableMouse(db.tooltips)
    if button.SetMouseClickEnabled then
        button:SetMouseClickEnabled(false)
    end
end

local function SetTimerColor(button, urgent)
    if button.urgent == urgent then return end
    button.urgent = urgent
    button.timer:SetTextColor(unpack(urgent and UI.COLORS.warn or UI.COLORS.text))
end

local function SetReady(button, unknown)
    button.active = false
    button.bucket = nil
    button.cooldown:Clear()
    button.timer:SetText("")
    button.icon:SetDesaturated(unknown)
    button:SetAlpha(unknown and UNKNOWN_ALPHA or 1)
end

local function SetActive(button, entry)
    button.active = true
    button.icon:SetDesaturated(ns.db.desaturate)
    button:SetAlpha(1)
    if button.cdStart ~= entry.start or button.cdDuration ~= entry.duration then
        button.cdStart, button.cdDuration = entry.start, entry.duration
        button.cooldown:SetCooldown(entry.start, entry.duration)
    end
end

function Icon.Assign(button, key, member, now)
    button.key = key
    button.member = member
    if button.shownKey ~= key then
        button.icon:SetTexture(ns.Spells.Icon(key))
        button.shownKey = key
        button.cdStart, button.cdDuration = nil, nil
    end
    local entry = member.cds[key]
    if entry and entry.start + entry.duration > now then
        SetActive(button, entry)
        Icon.Tick(button, now)
        return true
    end
    button.cdStart, button.cdDuration = nil, nil
    SetReady(button, not member.synced)
    return false
end

function Icon.Tick(button, now)
    local entry = button.member.cds[button.key]
    local remaining = entry and entry.start + entry.duration - now or 0
    if remaining <= 0 then
        button.cdStart, button.cdDuration = nil, nil
        SetReady(button, false)
        if ns.db.pulse and button:IsVisible() then
            button.pulse:Restart()
            button.flash:Restart()
        end
        return false
    end
    if not ns.db.timerText then
        if button.bucket then
            button.timer:SetText("")
            button.bucket = nil
        end
        return true
    end
    local decimals = ns.db.timerDecimals
    local bucket = Bucket(remaining, decimals)
    if bucket ~= button.bucket then
        button.bucket = bucket
        button.timer:SetText(FormatRemaining(remaining, decimals))
        SetTimerColor(button, remaining < URGENT_SECONDS)
    end
    return true
end
