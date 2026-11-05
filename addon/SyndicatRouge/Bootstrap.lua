local addonName, ns = ...
local function provider(db, viewerId, demo)
    return {
        demo = demo,
        View = function() return ns.Core.View(db, viewerId) end,
        Read = function(_, id) return ns.Notifications.Read(db, id, viewerId) end,
        Thank = function(_, id) return ns.Notifications.Thank(db, id, viewerId) end,
    }
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, _, name)
    if name ~= addonName then return end
    events:UnregisterEvent("ADDON_LOADED")
    -- No gameplay/identity adapter yet. Never persist a guessed guild or demo ledger.
    ns.UI.SetProvider(provider(ns.Core.New("unconfigured:forever"), nil, false))
    SLASH_SYNDICATROUGE1 = "/syndicat"
    SLASH_SYNDICATROUGE2 = "/sr"
    SlashCmdList.SYNDICATROUGE = function() ns.UI.Toggle() end
end)

-- Explicit development extension point; no fixtures, network receiver or rewards here.
SyndicatRouge = {
    MapPreview = { Create = ns.UI.Maps.Create, Display = ns.UI.Maps.Display },
    ShowDemo = function(incidents, claims, guildId, viewerId)
        local db = assert(ns.Core.New(guildId))
        for _, incident in ipairs(incidents) do assert(ns.Incidents.Add(db, incident)) end
        for _, claim in ipairs(claims) do assert(ns.Vengeance.Resolve(db, claim)) end
        ns.UI.SetProvider(provider(db, viewerId, true))
        local f = ns.UI.Create(); ns.UI.Refresh(); f:Show()
    end,
    ResetView = function()
        ns.UI.SetProvider(provider(ns.Core.New("unconfigured:forever"), nil, false))
        ns.UI.Refresh()
    end,
}
