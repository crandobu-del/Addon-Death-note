local ns=...
local C=ns.ChatDeathProbe
local passed=0
local function check(ok,message)assert(ok,message);passed=passed+1 end
local oldGuard,oldClock,oldId,oldCamelot=issecretvalue,GetTime,WOW_PROJECT_ID,WOW_PROJECT_CAMELOT
issecretvalue=function()return false end
check(C.Parse('Vous avez été tué par "JoueurX"').name=="JoueurX","exact user-provided phrase")
check(C.Parse('Vous avez été tué par Sélénombre.').name=="Sélénombre","accented plain name and terminal punctuation")
check(C.Parse('Vous avez été tué par « JoueurX »').name=="JoueurX","French quotes")
local linked=C.Parse('Vous avez été tué par |cffffffff|Hplayer:JoueurX-Realm:12|h[JoueurX]|h|r.')
check(linked.name=="JoueurX-Realm" and linked.playerLink,"public player hyperlink preserves qualified target")
check(not C.Parse('Vous avez été tué par |Hplayer:Other|h[JoueurX]|h'),"mismatched link rejected")
check(not C.Parse('Vous avez été tué par |Hspell:1|h[JoueurX]|h'),"non-player link rejected")
check(not C.Parse('Guilde : Vous avez été tué par JoueurX'),"message must match in full")
check(not C.Parse('Vous avez été tué par Grand monstre'),"multiword NPC not assumed to be player")
local _,status=C.Parse('Vous avez été tué par |Khidden|k')
check(status=="protected_text","protected wrapper never decoded")
local secret=setmetatable({},{__tostring=function()error("secret leaked")end})
issecretvalue=function(value)return value==secret end
_,status=C.Parse(secret)
check(status=="secret","secret never converted or parsed")
issecretvalue=nil;_,status=C.Parse('Vous avez été tué par JoueurX')
check(status=="guard_missing","no access guard means no reading")
issecretvalue=function()return false end
local now=100;GetTime=function()return now end;WOW_PROJECT_ID=18;WOW_PROJECT_CAMELOT=18
C.Start()
check(C.report.running and not C.frame.events.COMBAT_LOG_MESSAGE and not C.frame.events.CHAT_MSG_GUILD,"only permitted event allowlist subscribed")
C.Receive("CHAT_MSG_SYSTEM",'Vous avez été tué par JoueurX')
check(C.report.correlated==0,"phrase alone does not imply own death")
now=101;C.Receive("PLAYER_DEAD")
check(C.report.correlated==1 and C.lastName=="JoueurX","correlates phrase before personal death")
C.Receive("CHAT_MSG_COMBAT_MISC_INFO",'Vous avez été tué par JoueurX')
check(C.report.correlated==1,"duplicate route does not duplicate candidate death")
C.Receive("CHAT_MSG_SYSTEM",'Vous avez été tué par Other')
check(C.report.lastResult=="multiple_candidates" and C.lastName==nil,"different candidates remain ambiguous")
C.Start();now=200;C.Receive("PLAYER_DEAD");now=201
C.Receive("CHAT_MSG_SYSTEM",'Vous avez été tué par JoueurX')
check(C.report.correlated==1,"correlates phrase after personal death")
C.Start();now=300;C.Receive("CHAT_MSG_SYSTEM",'Vous avez été tué par JoueurX');now=310;C.Receive("PLAYER_DEAD")
check(C.report.correlated==0,"stale candidate never reused")
local frame=C.frame;C.Stop()
check(not C.report.running and next(frame.events)==nil and frame.scripts.OnEvent==nil,"stop removes all subscriptions")
issecretvalue,GetTime,WOW_PROJECT_ID,WOW_PROJECT_CAMELOT=oldGuard,oldClock,oldId,oldCamelot
return {passed=passed}
