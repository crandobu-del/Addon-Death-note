local ns=...
local K=ns.KillProofProbe
local passed=0
local function check(ok,message) assert(ok,message);passed=passed+1 end
local before=ns.Validation.Copy(SyndicatRougeCharacterDB)
local originals={UnitGUID=UnitGUID,UnitNameFromGUID=UnitNameFromGUID,CombatLogGetCurrentEventInfo=CombatLogGetCurrentEventInfo,
    secret=issecretvalue,events=C_EventUtils,project=WOW_PROJECT_ID,camelot=WOW_PROJECT_CAMELOT}
local captured,queries={},0
local secret=setmetatable({},{__tostring=function() error("secret stringified") end,__eq=function() error("secret compared") end})
issecretvalue=function(value) return rawequal(value,secret) end
WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
C_EventUtils={IsEventValid=function(event) assert(event=="PARTY_KILL");return true end,
    IsCallbackEvent=function() return false end}
UnitGUID=function(token) assert(token=="player","must never query an enemy PvP token");queries=queries+1;return "self" end
UnitNameFromGUID=function() error("must not resolve target identity") end
CombatLogGetCurrentEventInfo=function() error("must not read restricted combat") end
check(K.report==nil and K.frame==nil,"not activated on load")
local r=K.Start()
check(r.running and r.valid=="yes" and r.callback=="no" and r.subscription=="registered","separate metadata and subscription")
check(K.frame.events.PARTY_KILL and not K.frame.events.COMBAT_LOG_EVENT_UNFILTERED,"only literal ordinary event subscribed")
K.Receive(secret,"victim")
check(r.blocked==1 and queries==0,"attacker guard before comparison and own query")
K.Receive("self",secret)
check(r.blocked==2 and queries==0,"target guard before type or contents")
K.Receive("self",nil);K.Receive("self","|Khidden|k")
check(r.invalid==2 and queries==0,"nil or masked target refused")
K.Receive("other","victim")
check(r.otherAttacker==1 and r.ownPairs==0,"other member kill never assigned to self")
K.Receive("self","self")
check(r.invalid==3 and r.ownPairs==0,"self pair rejected")
K.frame.scripts.OnEvent(K.frame,"PARTY_KILL","self","victim")
check(r.ownPairs==1 and r.lastResult=="public_pair_for_self","ordinary frame payload counted with public own identity")
check(r.attackerGUID==nil and r.targetGUID==nil and K.targetGUID==nil,"no identity retained")
check(ns.Validation.Same(before,SyndicatRougeCharacterDB),"no ledger or saved data mutation")
local ownQueries=queries
issecretvalue=nil;K.Receive("self","victim")
check(r.lastResult=="guard_missing" and queries==ownQueries,"guard absence fails closed")
issecretvalue=function() error("guard failure") end;K.Receive("self","victim")
check(r.lastResult=="guard_failed" and queries==ownQueries,"guard error fails closed")
issecretvalue=function(value) return rawequal(value,secret) end
UnitGUID=function(token) assert(token=="player");return secret end;K.Receive("self","victim")
check(r.lastResult=="protected" and r.ownPairs==1,"protected own GUID not inspected")
UnitGUID=nil;K.Receive("self","victim")
check(r.lastResult=="own_guid_api_missing","missing getter explicit")
UnitGUID=function() error("unavailable") end;K.Receive("self","victim")
check(r.lastResult=="own_guid_query_failed","own getter failure isolated")
local frame=K.frame;K.Start()
check(K.frame==frame and K.report.received==0,"restart resets counters and reuses frame")
K.Stop();local count=K.report.received;K.Receive("self","victim")
check(not K.report.running and K.report.received==count and not frame.events.PARTY_KILL,"stop removes subscription and ignores payload")
WOW_PROJECT_ID=1;r=K.Start();check(not r.running and r.lastResult=="wrong_client","other flavor never starts")
WOW_PROJECT_ID=18;C_EventUtils.IsEventValid=function() return false end;r=K.Start()
check(not r.running and r.lastResult=="event_invalid","invalid event not subscribed")
C_EventUtils.IsEventValid=function() return true end;C_EventUtils.IsCallbackEvent=function() return true end;r=K.Start()
check(not r.running and r.lastResult=="callback_not_frame_event","callback not treated as frame event")
for key,value in pairs(originals) do
    if key=="secret" then issecretvalue=value elseif key=="events" then C_EventUtils=value
    elseif key=="project" then WOW_PROJECT_ID=value elseif key=="camelot" then WOW_PROJECT_CAMELOT=value else _G[key]=value end
end
-- The sandbox globals absent before the test must also be removed.
UnitNameFromGUID=originals.UnitNameFromGUID
UnitGUID=originals.UnitGUID
CombatLogGetCurrentEventInfo=originals.CombatLogGetCurrentEventInfo
return {passed=passed}
