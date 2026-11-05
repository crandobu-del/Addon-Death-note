local _, demo = ...
local P = {}
demo.PvpProbe = P
local ordinary = {"PLAYER_DEAD", "PLAYER_ALIVE", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED"}
local combatEvent = "COMBAT_LOG_EVENT_UNFILTERED"

local function public(value)
    return not (type(issecretvalue)=="function" and issecretvalue(value))
end
local function booleanQuery(fn, ...)
    if type(fn)~="function" then return "unavailable" end
    local ok,value=pcall(fn,...)
    if not ok then return "operation_failed" end
    if not public(value) then return "restricted_value" end
    if type(value)~="boolean" then return "unexpected_type" end
    return value and "true" or "false"
end
local function eventInfo(name)
    return {valid=booleanQuery(C_EventUtils and C_EventUtils.IsEventValid,name),
        callback=booleanQuery(C_EventUtils and C_EventUtils.IsCallbackEvent,name),
        subscription="not_tested",deliveries=0}
end

function P.Stop()
    if P.frame then
        for _,name in ipairs(ordinary) do P.frame:UnregisterEvent(name) end
        P.frame:SetScript("OnEvent",nil)
    end
    if P.report then P.report.running=false end
end
function P.Sample()
    if not P.report then return end
    local status=booleanQuery(C_CombatLog and C_CombatLog.IsCombatLogRestricted)
    P.report.combatRestriction=status
    P.report.restrictionSamples[#P.report.restrictionSamples+1]=status
    if #P.report.restrictionSamples>20 then table.remove(P.report.restrictionSamples,1) end
end
function P.Start()
    P.Stop()
    local report={version=1,target="forever",sourceCommit="eac30af597e5aaa43a60f6675ef5fdcea100375f",
        events={},running=false,restrictionSamples={},profile="user_profile_not_isolated",
        killerAttribution="not_established",combatRead="not_attempted_restricted_source",
        recapRead="not_attempted_forever_loading_unverified"}
    if type(GetBuildInfo)=="function" then report.clientVersion,report.build,report.buildDate,report.interface=GetBuildInfo() end
    report.projectID=WOW_PROJECT_ID
    report.targetMatches=type(WOW_PROJECT_CAMELOT)=="number" and WOW_PROJECT_ID==WOW_PROJECT_CAMELOT
    report.api={restriction=type(C_CombatLog and C_CombatLog.IsCombatLogRestricted)=="function",
        eventValidity=type(C_EventUtils and C_EventUtils.IsEventValid)=="function",
        eventCategory=type(C_EventUtils and C_EventUtils.IsCallbackEvent)=="function",
        legacyGetterPresent=type(CombatLogGetCurrentEventInfo)=="function"}
    P.report=report;SyndicatRougePvpProbe=report
    for _,name in ipairs(ordinary) do report.events[name]=eventInfo(name) end
    report.events[combatEvent]=eventInfo(combatEvent)
    report.events[combatEvent].subscription="not_attempted_restricted_callback_source"
    if not report.targetMatches then report.stopReason="client_target_unconfirmed";return report end
    if not P.frame then P.frame=CreateFrame("Frame") end
    for _,name in ipairs(ordinary) do
        local row=report.events[name]
        if row.valid=="false" then row.subscription="invalid_event"
        elseif row.callback=="true" then row.subscription="callback_not_subscribed"
        else
            local ok,registered=pcall(P.frame.RegisterEvent,P.frame,name)
            row.subscription=ok and registered==true and "registered" or "registration_failed"
        end
    end
    report.running=true
    P.frame:SetScript("OnEvent",function(_,event)
        local row=report.events[event]
        if not row or row.subscription~="registered" then return end
        row.deliveries=math.min(row.deliveries+1,10000)
        P.Sample()
    end)
    P.Sample()
    return report
end
function P.Show()
    local report=P.report
    if not report and type(SyndicatRougePvpProbe)=="table" and SyndicatRougePvpProbe.version==1 then report=SyndicatRougePvpProbe end
    if not report then print("DEATH NOTE : lance /srpvp debut pour vérifier le client.");return end
    local labels={['true']="oui",['false']="non",unavailable="API absente",operation_failed="appel impossible",restricted_value="valeur protégée"}
    print("DEATH NOTE — diagnostic PvP : "..tostring(report.clientVersion or "version inconnue").." / "..tostring(report.build or "build inconnu"))
    print("Cible Forever confirmée : "..(report.targetMatches and "oui" or "non"))
    print("Journal de combat restreint : "..(labels[report.combatRestriction] or "non mesuré"))
    local log=report.events and report.events[combatEvent]
    if log then print("Événement de combat : valide="..(labels[log.valid] or log.valid)..", callback="..(labels[log.callback] or log.callback).." ; lecture non tentée.") end
    local dead=report.events and report.events.PLAYER_DEAD
    if dead then print("Mort du personnage : abonnement="..dead.subscription..", réceptions="..dead.deliveries.." (PvP ou autre cause).") end
    print("Identification fiable du tueur : pas encore établie. Aucun incident ni point créé.")
end
SLASH_SYNDICATROUGEPVPPROBE1="/srpvp"
SlashCmdList.SYNDICATROUGEPVPPROBE=function(command)
    if command=="debut" then P.Start();P.Show()
    elseif command=="fin" then P.Stop();P.Show()
    else if P.report and P.report.running then P.Sample() end;P.Show() end
end
