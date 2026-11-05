local ns=...
local P,V=ns.Persistence,ns.Validation
local passed=0
local function check(ok,message)assert(ok,message);passed=passed+1 end
local state=P.Open(nil)
check(state.writable and state.status=="new" and state.root.formatVersion==1,"new per-character profile")
local function actor(id)return{id=id,name=id,realm="Forever"}end
for _,id in ipairs({"a","b"}) do
    assert(ns.Incidents.Add(state.db,{id=id,guildId=P.scope,enemy=actor("enemy"),victim=actor("victim"),occurredAt=10,
        location={zone="Elwynn"},source="manual"}))
end
assert(ns.Vengeance.Resolve(state.db,{id="v",guildId=P.scope,enemyId="enemy",avenger=actor("avenger"),occurredAt=20,incidentIds={"a"}}))
local notification=ns.Notifications.List(state.db,"victim")[1]
assert(ns.Notifications.Thank(state.db,notification.id,"victim"))
local prefs={tab=3,position={point="TOPLEFT",relativePoint="TOPLEFT",x=240,y=-150}}
check(P.Checkpoint(state,prefs),"ledger and preferences checkpoint")
local resumed=P.Open(V.Copy(state.root))
check(resumed.writable and resumed.status=="restored" and V.Count(resumed.db.incidents)==2,"two incidents restore")
check(ns.Wanted.List(resumed.db)[1].openCount==1,"vengeance closure survives reload")
check(ns.Reputation.Ranking(resumed.db)[1].reputation==1,"reputation survives as derived data")
local restoredNotification=ns.Notifications.List(resumed.db,"victim")[1]
check(restoredNotification.read and restoredNotification.thanked,"read and thanks states survive")
check(resumed.root.ui.tab==3 and resumed.root.ui.position.x==240,"window preferences survive")
state.root.ledger.vengeances.v.reward=999
resumed=P.Open(V.Copy(state.root))
check(resumed.db.vengeances.v.reward==1,"stored reward is recomputed, not trusted")
local before=V.Copy(resumed.root)
resumed.db.incidents.bad={id="bad"}
check(not P.Checkpoint(resumed),"invalid runtime state cannot be saved")
check(V.Same(resumed.root,before),"failed checkpoint preserves last valid root")
local future={formatVersion=99,scope="unknown",sentinel="keep me"}
local readOnly=P.Open(future)
check(not readOnly.writable and readOnly.status=="unsupported_profile_version","future profile opened read-only")
check(not P.Checkpoint(readOnly) and future.sentinel=="keep me" and future.formatVersion==99,"future data not overwritten")
local corrupt={formatVersion=1,scope="character-local",ledger={},sentinel="original"}
readOnly=P.Open(corrupt)
check(not readOnly.writable and not P.Checkpoint(readOnly) and corrupt.sentinel=="original" and next(corrupt.ledger)==nil,"corrupt ledger preserved")
check(not P.Open({formatVersion=1,scope="other",ledger={}}).writable,"different scope not mixed into local ledger")
check(P.UI({tab=9,position={point="bad",relativePoint="CENTER",x=0,y=0}}).position==nil,"invalid anchor discarded")
check(P.UI({tab=0}).tab==1 and not P.UI({position={point="CENTER",relativePoint="CENTER",x=math.huge,y=0}}).position,"invalid preferences fall back safely")
check(V.Count(P.Open(nil).db.incidents)==0,"another character starts isolated")

-- Real bootstrap integration: use the live profile, not any pure fixture above.
local live=ns.Runtime
check(live.root==SyndicatRougeCharacterDB and V.Count(live.db.incidents)==0,"bootstrap binds real SavedVariables")
SyndicatRouge.ResetView()
local f=ns.UI.Create();f:Show()
f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",123,-45)
f.tabs[2].scripts.OnClick()
check(live.root.ui.tab==2 and live.root.ui.position.x==123,"real UI changes checkpoint preferences")
local storedUI=V.Copy(live.root.ui)
SyndicatRouge.ShowDemo({{id="demo:save",guildId="demo:save",enemy=actor("enemy"),victim=actor("victim"),occurredAt=10,location={zone="Test"},source="demo"}}, {},"demo:save","victim")
local revision=live.root.revision
f.tabs[4].scripts.OnClick();f:SetPoint("CENTER",UIParent,"CENTER",999,999);f.scripts.OnDragStop(f)
SlashCmdList.SYNDICATROUGESAVE()
check(live.root.revision==revision and V.Same(live.root.ui,storedUI),"demo controls and save command cannot change real preferences")
check(V.Count(live.root.ledger.incidents)==0,"demo never contaminates real ledger")
SlashCmdList.SYNDICATROUGE()
check(not ns.UI.provider.demo and f:IsShown() and f.tab==2 and f.point[4]==123,"slash command returns to persisted real view")
local savedBeforeLogout=live.root.revision
for _,frame in ipairs(SR_TEST_FRAMES) do
    if frame.events and frame.events.PLAYER_LOGOUT then frame.scripts.OnEvent(frame,"PLAYER_LOGOUT") end
end
check(live.root.revision>savedBeforeLogout,"logout checkpoints real state")
local reloaded=P.Open(V.Copy(SyndicatRougeCharacterDB))
check(reloaded.status=="restored" and reloaded.root.ui.tab==2 and V.Count(reloaded.db.incidents)==0,"simulated reload preserves real profile without demo data")
return {passed=passed}
