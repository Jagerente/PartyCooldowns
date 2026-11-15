local _, ns = ...

SLASH_PARTYCOOLDOWNS1 = "/pcd"
SLASH_PARTYCOOLDOWNS2 = "/partycd"
SlashCmdList.PARTYCOOLDOWNS = function()
    ns.Options.Toggle()
end

function PartyCooldowns_OnAddonCompartmentClick()
    ns.Options.Toggle()
end
