local _,ns=...
local A={revocations={}};ns.Access=A
function A.Allowed()
    local ok,context,reason=pcall(ns.GuildContext.Current)
    A.reason=ok and reason or "guild_check_failed"
    return ok and context~=nil
end
function A.Require()
    if A.Allowed()then return true end
    print("Tableau des primes : accès réservé aux membres vérifiés du Syndicat Rouge ("..tostring(A.reason)..").")
    return false
end
function A.Refresh()
    local allowed=A.Allowed()
    if ns.UI.Minimap.button then ns.UI.Minimap.button:SetShown(allowed) end
    if not allowed then
        for _,stop in ipairs(A.revocations)do pcall(stop)end
        if ns.UI.window then ns.UI.window:Hide()end
        if ns.WantedMarkers then ns.WantedMarkers.HideAll();if ns.WantedMarkers.preview then ns.WantedMarkers.preview:Hide()end end
        if ns.Sightings then ns.Sightings.Reset()end
        if ns.GuildNative.channel then ns.GuildNative.Suspend()end
    end
end
function A.Initialize()
    local f=CreateFrame("Frame");A.frame=f
    f:RegisterEvent("PLAYER_LOGIN");f:RegisterEvent("PLAYER_GUILD_UPDATE")
    f:SetScript("OnEvent",A.Refresh)
    local elapsed=0
    f:SetScript("OnUpdate",function(_,dt)elapsed=elapsed+dt;if elapsed>=2 then elapsed=0;A.Refresh()end end)
    A.Refresh()
end
