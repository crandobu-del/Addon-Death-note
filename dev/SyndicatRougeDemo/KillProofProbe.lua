local _,demo=...
local K={};demo.KillProofProbe=K
local eventName="PARTY_KILL"
local function public(value)
    if type(issecretvalue)~="function" then return false,"guard_missing" end
    local ok,secret=pcall(issecretvalue,value)
    if not ok then return false,"guard_failed" end
    if secret then return false,"protected" end
    return true
end
local function increment(key)
    K.report[key]=math.min((K.report[key] or 0)+1,10000)
end
local function query(method)
    if type(method)~="function" then return "unavailable" end
    local ok,value=pcall(method,eventName)
    if not ok then return "failed" end
    local allowed=public(value)
    if not allowed then return "protected" end
    if value==true then return "yes" elseif value==false then return "no" end
    return "unknown"
end
function K.Receive(attackerGUID,targetGUID)
    if not K.report or not K.report.running then return end
    increment("received")
    -- Do not type-check, compare, format, resolve or persist protected identities.
    local attackerPublic,reason=public(attackerGUID)
    local targetPublic,targetReason=public(targetGUID)
    if not attackerPublic or not targetPublic then
        increment("blocked");K.report.lastResult=not attackerPublic and reason or targetReason;return
    end
    if type(attackerGUID)~="string" or type(targetGUID)~="string" or #attackerGUID==0 or #targetGUID==0
        or #attackerGUID>160 or #targetGUID>160 or attackerGUID:find("[|%c]") or targetGUID:find("[|%c]") then
        increment("invalid");K.report.lastResult="invalid_pair";return
    end
    increment("publicPairs")
    if type(UnitGUID)~="function" then K.report.lastResult="own_guid_api_missing";return end
    -- Never query target/focus/nameplate tokens; these can be PvP-restricted.
    local ok,ownGUID=pcall(UnitGUID,"player")
    if not ok then K.report.lastResult="own_guid_query_failed";return end
    local ownPublic,ownReason=public(ownGUID)
    if not ownPublic then increment("blocked");K.report.lastResult=ownReason;return end
    if type(ownGUID)~="string" or #ownGUID==0 then K.report.lastResult="own_guid_missing";return end
    if attackerGUID~=ownGUID then increment("otherAttacker");K.report.lastResult="other_attacker";return end
    if targetGUID==ownGUID then increment("invalid");K.report.lastResult="self_pair";return end
    increment("ownPairs");K.report.lastResult="public_pair_for_self"
    -- A public pair still does not identify a wanted player or establish an open incident.
    -- Deliberately no claim, Store, saved variable, notification or guild send here.
end
function K.Stop()
    if K.frame then K.frame:UnregisterEvent(eventName);K.frame:SetScript("OnEvent",nil) end
    if K.report then K.report.running=false end
end
function K.Start()
    K.Stop()
    K.report={running=false,received=0,publicPairs=0,ownPairs=0,otherAttacker=0,blocked=0,invalid=0,
        valid="not_checked",callback="not_checked",subscription="not_attempted",lastResult="not_observed"}
    local r=K.report
    if type(WOW_PROJECT_CAMELOT)~="number" or WOW_PROJECT_ID~=WOW_PROJECT_CAMELOT then r.lastResult="wrong_client";return r end
    if not public(false) then r.lastResult="guard_unavailable";return r end
    r.valid=query(C_EventUtils and C_EventUtils.IsEventValid)
    r.callback=query(C_EventUtils and C_EventUtils.IsCallbackEvent)
    if r.valid=="no" then r.lastResult="event_invalid";return r end
    if r.callback=="yes" then r.lastResult="callback_not_frame_event";return r end
    if not K.frame then K.frame=CreateFrame("Frame") end
    local ok,value=pcall(K.frame.RegisterEvent,K.frame,eventName)
    if not ok or not public(value) or value~=true then
        r.subscription="failed";r.lastResult="subscription_failed";K.Stop();return r
    end
    r.subscription="registered";r.running=true
    K.frame:SetScript("OnEvent",function(_,event,attackerGUID,targetGUID)
        if event==eventName then K.Receive(attackerGUID,targetGUID) end
    end)
    return r
end
function K.Show()
    local r=K.report
    if not r then print("Tableau des primes : diagnostic de kill inactif. /srkill debut pour le lancer.");return end
    print("Tableau des primes — preuve de kill : "..(r.running and "actif" or "arrêté"))
    print("PARTY_KILL : valide="..r.valid..", callback="..r.callback..", abonnement="..r.subscription)
    print("Réceptions="..r.received.." ; paires lisibles="..r.publicPairs.." ; attribuées à toi="..r.ownPairs.." ; protégées="..r.blocked.." ; autres attaquants="..r.otherAttacker.." ; invalides="..r.invalid)
    print("Résultat="..r.lastResult..". Aucun nom/GUID conservé ; aucune vengeance ni réputation attribuée.")
end
SLASH_SYNDICATROUGEKILLPROOF1="/srkill"
SlashCmdList.SYNDICATROUGEKILLPROOF=function(command)
    command=(command or ""):lower():gsub("é","e"):match("^%s*(.-)%s*$")
    if command=="debut" then K.Start();K.Show()
    elseif command=="fin" then K.Stop();K.Show()
    elseif command=="" or command=="bilan" then K.Show()
    else print("Tableau des primes : /srkill debut | bilan | fin") end
end
