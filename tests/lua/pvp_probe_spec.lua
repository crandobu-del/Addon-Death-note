local ns=...
local P=ns.PvpProbe
local passed=0
local function check(ok,message)assert(ok,message);passed=passed+1 end
local oldProject,oldCamelot,oldCombat,oldEvents,oldSecret,oldGetter=WOW_PROJECT_ID,WOW_PROJECT_CAMELOT,C_CombatLog,C_EventUtils,issecretvalue,CombatLogGetCurrentEventInfo
check(P.report==nil and P.frame==nil,"diagnostic never starts on login")
WOW_PROJECT_ID=18;WOW_PROJECT_CAMELOT=18
C_EventUtils={IsEventValid=function()return true end,IsCallbackEvent=function(name)return name=="COMBAT_LOG_EVENT_UNFILTERED"end}
C_CombatLog={IsCombatLogRestricted=function()return true end}
local reads=0
CombatLogGetCurrentEventInfo=function()reads=reads+1;error("must never read protected combat data")end
local report=P.Start()
check(report.targetMatches and report.running,"probe starts only for confirmed Forever target")
check(report.combatRestriction=="true","public restriction query recorded")
check(report.events.COMBAT_LOG_EVENT_UNFILTERED.subscription=="not_attempted_restricted_callback_source","restricted callback never subscribed")
check(not P.frame.events.COMBAT_LOG_EVENT_UNFILTERED,"frame has no protected combat subscription")
P.frame.scripts.OnEvent(P.frame,"PLAYER_DEAD","ignored payload")
check(report.events.PLAYER_DEAD.deliveries==1,"ordinary death delivery counted")
check(report.killerAttribution=="not_established" and reads==0,"death never becomes invented killer attribution")
check(report.api.legacyGetterPresent,"getter presence distinct from operation permission")
check(report.events.PLAYER_DEAD.subscription=="registered","subscription recorded independently from delivery")
local frame=P.frame
P.Start()
check(P.frame==frame and P.report.events.PLAYER_DEAD.deliveries==0,"restart reuses frame and resets counts")
P.Stop()
check(not P.report.running and next(frame.events)==nil and frame.scripts.OnEvent==nil,"stop removes subscriptions and handler")
C_CombatLog=nil;C_EventUtils=nil
report=P.Start()
check(report.combatRestriction=="unavailable" and report.events.PLAYER_DEAD.valid=="unavailable","missing query API never treated as permission")
local secret=setmetatable({},{__tostring=function()error("secret leaked")end})
issecretvalue=function(value)return value==secret end
C_CombatLog={IsCombatLogRestricted=function()return secret end}
P.Sample()
check(P.report.combatRestriction=="restricted_value","secret query result not serialized or inspected")
C_CombatLog.IsCombatLogRestricted=function()error("restricted")end
P.Sample();check(P.report.combatRestriction=="operation_failed","query failure preserved without bypass")
WOW_PROJECT_ID=1
report=P.Start()
check(not report.running and report.stopReason=="client_target_unconfirmed","other client does not activate Forever probe")
check(SyndicatRougePvpProbe==report,"diagnostic metadata persist separately from incidents")
WOW_PROJECT_ID, WOW_PROJECT_CAMELOT, C_CombatLog, C_EventUtils, issecretvalue, CombatLogGetCurrentEventInfo=oldProject,oldCamelot,oldCombat,oldEvents,oldSecret,oldGetter
return {passed=passed}
