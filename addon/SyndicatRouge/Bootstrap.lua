local addonName, ns = ...
local live
local function save()
    if not live then return false,"not_initialized" end
    local preferences=live.root and type(live.root)=="table" and live.root.ui or nil
    if ns.UI.window and ns.UI.provider and not ns.UI.provider.demo and not ns.UI.provider.test then preferences=ns.UI.CapturePreferences() end
    return ns.Persistence.Checkpoint(live,preferences)
end
local function provider(db, viewerId, demo)
    local function current() return demo and db or live.db end
    local function change(method,id)
        if demo then return method(db,id,viewerId) end
        if ns.GuildNative.channel then
            return ns.GuildNative.Change(method==ns.Notifications.Read and "read" or "thank",id)
        end
        if not live.writable then return false,"read_only" end
        local candidate,reason=ns.Store.Restore(ns.Store.Snapshot(live.db),ns.Persistence.scope)
        if not candidate then return false,reason end
        local ok,result=method(candidate,id,viewerId)
        if not ok then return false,result end
        local previous=live.db;live.db=candidate
        local saved,errorCode=save()
        if not saved then live.db=previous;return false,errorCode end
        return true,result
    end
    return {
        demo = demo, readOnly=not demo and not live.writable,
        test=not demo and ns.GuildNative.testMode==true,
        shared=not demo and ns.GuildNative.channel~=nil,
        View = function()
            if not demo and ns.GuildNative.channel then
                local c=ns.GuildNative.channel;return ns.Delivery.View(c.delivery,c.session)
            end
            return ns.Core.View(current(), viewerId)
        end,
        Read = function(_, id) return change(ns.Notifications.Read,id) end,
        Thank = function(_, id) return change(ns.Notifications.Thank,id) end,
    }
end
local function realView()
    if not live then return end
    ns.UI.SetProvider(provider(nil,nil,false))
    ns.UI.ApplyPreferences(type(live.root)=="table" and live.root.ui or nil)
    ns.UI.Refresh()
end
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:SetScript("OnEvent", function(_, event, name)
    if event=="PLAYER_LOGOUT" then save();return end
    if name ~= addonName then return end
    events:UnregisterEvent("ADDON_LOADED")
    live=ns.Persistence.Open(SyndicatRougeCharacterDB)
    ns.Runtime=live
    if live.writable then SyndicatRougeCharacterDB=live.root
    else print("Tableau des primes : sauvegarde conservée sans modification ; registre en lecture seule ("..live.status..").") end
    events:RegisterEvent("PLAYER_LOGOUT")
    ns.UI.OnPreferencesChanged=function()
        if ns.UI.provider and not ns.UI.provider.demo and not ns.UI.provider.test then save() end
    end
    realView()
    ns.GuildNative.Bind(live,function()
        if not ns.UI.provider or not ns.UI.provider.demo then
            ns.UI.SetProvider(provider(nil,nil,false));ns.UI.Refresh()
        end
    end)
    ns.WantedMarkers.Initialize(live)
    SLASH_SYNDICATROUGE1 = "/syndicat"
    SLASH_SYNDICATROUGE2 = "/sr"
    SlashCmdList.SYNDICATROUGE = function()
        if ns.UI.provider and ns.UI.provider.demo then
            realView();local f=ns.UI.Create();ns.UI.Refresh();f:Show()
        else ns.UI.Toggle() end
    end
    ns.UI.Minimap.Initialize(SlashCmdList.SYNDICATROUGE)
    SLASH_SYNDICATROUGESAVE1="/srsave"
    SlashCmdList.SYNDICATROUGESAVE=function()
        if ns.UI.provider and ns.UI.provider.demo then print("Tableau des primes : les exemples ne sont pas sauvegardés. /sr ouvre ton registre personnel.");return end
        local ok,reason=save()
        if not ok then print("Tableau des primes : sauvegarde non modifiée ("..tostring(reason)..").");return end
        print("Tableau des primes : profil "..live.status..", révision "..live.root.revision..", "..ns.Validation.Count(live.db.incidents).." incident(s). Écriture sur disque au rechargement ou à la déconnexion.")
    end
end)

-- Explicit demo extension point; fixtures never enter the shared guild provider.
SyndicatRouge = {
    MapPreview = { Create = ns.UI.Maps.Create, Display = ns.UI.Maps.Display },
    ShowDemo = function(incidents, claims, guildId, viewerId)
        save()
        local db = assert(ns.Core.New(guildId))
        for _, incident in ipairs(incidents) do assert(ns.Incidents.Add(db, incident)) end
        for _, claim in ipairs(claims) do assert(ns.Vengeance.Resolve(db, claim)) end
        ns.UI.SetProvider(provider(db, viewerId, true))
        local f = ns.UI.Create(); ns.UI.Refresh(); f:Show()
    end,
    ResetView = function()
        realView()
    end,
}
