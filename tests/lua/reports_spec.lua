local ns=...
local V,R,S,D,O,Y=ns.Validation,ns.ReportSchema,ns.ReportStore,ns.DeathDetector,ns.EnemyObserver,ns.ReportSync
local passed=0
local function test(name,fn)local ok,e=pcall(fn);assert(ok,name..": "..tostring(e));passed=passed+1 end
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local now=1793960000
GetServerTime=function()return now end
issecretvalue=function()return false end
UnitFullName=function()return "Alice","Forever"end
RegionalUniqueNamesEnabled=function()return false end
IsInInstance=function()return false,"none"end
C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,AreOutgoingAddonChatMessagesRestricted=function()return false end,
    InChatMessagingLockdown=function()return false end,SendAddonMessage=function()return 0 end}
for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end
local a={id="Alice-Forever",name="Alice",realm="Forever",guid="Player-1-A"}
local b={id="Bob-Forever",name="Bob",realm="Forever",guid="Player-1-B"}
local enemy={id="Enemy-Forever",name="Enemy",realm="Forever",guid="Player-1-E"}
local function reset()
    issecretvalue=function()return false end;ns.GuildNative.testMode=false
    IsInInstance=function()return false,"none"end
    ns.Runtime.writable=true;ns.Runtime.root.pvpReports=nil;assert(S.Open(ns.Runtime.root,now));D.Reset();O.Reset();Y.Reset();ns.ReportsRuntime.projection={}
    ns.Runtime.root.guilds={};ns.Runtime.root.guildDelivery={}
    D.lastRecapStamp=nil
end
local function death()return{id=a.id..":"..now..":1",at=now,guildId="guild:1",victim=V.Copy(a),location={},instanceType="none"}end
local function hit(guid,flags,overkill,time)
    return {event="SWING_DAMAGE",sourceGUID=guid,sourceName="Enemy",sourceFlags=flags,overkill=overkill,timestamp=time or now}
end
local playerFlags=0x40+0x100+0x400
local function report()
    return assert(D.Classify({hit(enemy.guid,playerFlags,0)},death(),"ignore"))
end
local function incoming(kind,data,sender)
    local c=ns.GuildNative.channel
    Y.counter=Y.counter+1
    return Y.Receive({version=1,guildId=c.context.guildId,senderId=(sender or a).id,kind="report",id="i"..Y.counter,report={v=1,kind=kind,data=data}},sender or a)
end
reset()
test("fatal zero is identified and unknown fields stay absent",function()
    local row=report();eq(row.confidence,"confirmed");eq(row.killer.guid,enemy.guid);eq(row.killer.id,nil);eq(row.location.mapId,nil);assert(R.Normalize(row,now,30))
end)
test("pure PvE and old attacks are ignored",function()
    assert(not D.Classify({hit("Creature-1-1",0x40+0x800,10)},death(),"ignore"))
    assert(not D.Classify({hit(enemy.guid,playerFlags,10,now-16)},death(),"ignore"))
end)
test("recent attacker without fatal hit is estimated",function()local r=D.Classify({hit(enemy.guid,playerFlags,-1)},death(),"ignore");eq(r.confidence,"estimated")end)
test("mixed finish policy and fall never accuse with certainty",function()
    local entries={hit(enemy.guid,playerFlags,-1,now-2),hit("Creature-1-1",0x40+0x800,0)}
    assert(not D.Classify(entries,death(),"ignore"));local r=D.Classify(entries,death(),"estimate");eq(r.confidence,"estimated");eq(r.finish,"pve")
    entries[2]={event="ENVIRONMENTAL_DAMAGE",timestamp=now,overkill=0}
    assert(not D.Classify(entries,death(),"ignore"));eq(D.Classify(entries,death(),"estimate").finish,"environment")
end)
test("pet owner mapped by GUID and counted once",function()
    O.cache[enemy.guid]={actor=V.Copy(enemy),seen=O.clock};O.owners["Pet-1-P"]={guid=enemy.guid,seen=O.clock}
    local r=D.Classify({hit(enemy.guid,playerFlags,-1),hit("Pet-1-P",0x40+0x100+0x1000,0)},death(),"ignore")
    eq(#r.attackers,1);eq(r.killer.guid,enemy.guid);eq(r.confidence,"confirmed")
end)
test("unowned pet remains unknown without guessed owner",function()
    O.Reset();local r=D.Classify({hit("Pet-1-X",0x40+0x100+0x1000,0)},death(),"ignore");eq(r.confidence,"unknown");eq(r.killer,nil);assert(R.Normalize(r,now,30))
end)
test("explicit guardian summon relationship is bounded and deduplicated",function()
    reset();assert(O.LinkOwner(enemy.guid,"Enemy","Creature-1-Guardian"))
    local r=D.Classify({hit(enemy.guid,playerFlags,-1),hit("Creature-1-Guardian",0x40+0x100+0x2000,0)},death(),"ignore")
    eq(#r.attackers,1);eq(r.killer.guid,enemy.guid);eq(r.confidence,"confirmed")
end)
test("protected fields are rejected before comparisons",function()
    local secret={};issecretvalue=function(v)return rawequal(v,secret)end
    local e=hit(enemy.guid,playerFlags,0);e.sourceGUID=secret
    assert(not D.Classify({e},death(),"ignore"));issecretvalue=function()return false end
end)
test("duplicate reports do not create new rows",function()
    reset();local r=report();assert(S.Put(r,"author",now,true));local ok,why=S.Put(r,"author",now,true);eq(ok,false);eq(why,"duplicate");eq(#S.List(true),1)
end)
test("GUID enrichment upgrades short names under same report ID",function()
    reset();local r=report();r.killer.name="Enemy-Forever";assert(S.Put(r,"author",now,true));assert(S.Put(r,"author",now,false))
    local changed=S.Enrich(enemy.guid,enemy,now,a.id);eq(#changed,1);eq(#S.List(true),1);eq(S.data.personal[r.id].row.killer.id,enemy.id);eq(S.data.personal[r.id].row.revision,2)
end)
test("relay cannot modify author data or establish trust",function()
    reset();local r=report();assert(S.Put(r,"relay",now,false));eq(S.data.shared[r.id].trust,"relay")
    assert(S.Put(r,"author",now,false));eq(S.data.shared[r.id].trust,"author")
    local fake=V.Copy(r);fake.killer.name="Forged";assert(not S.Put(fake,"relay",now,false));eq(S.data.shared[r.id].row.killer.name,"Enemy")
end)
test("author can replace a conflicting relay without blessing relay content",function()
    reset();local r=report();local fake=V.Copy(r);fake.killer.guid="Player-1-F";fake.attackers[1].guid="Player-1-F"
    assert(S.Put(fake,"relay",now,false));assert(S.Put(r,"author",now,false));eq(S.data.shared[r.id].row.killer.guid,enemy.guid)
end)
test("malformed dates fields sizes and schemas are rejected",function()
    reset();local r=report()
    for _,change in ipairs({function(x)x.at=now+31 end,function(x)x.version=2 end,function(x)x.unknown=true end,function(x)x.location.x=2 end,function(x)x.instanceType="arena"end,function(x)x.attackers[2]=V.Copy(x.attackers[1])end})do local x=V.Copy(r);change(x);assert(not S.Put(x,"author",now,false))end
    eq(#S.List(false),0)
end)
test("retention and cap apply without losing UI settings",function()
    reset();ns.Runtime.root.ui={tab=2};S.data.settings.maxShared=50
    for i=1,55 do local r=report();r.id=a.id..":"..now..":"..i;r.at=now-i;local ok,why=S.Put(r,"author",now,false);assert(ok or why=="capacity_evicted")end
    eq(#S.List(false),50);S.Cleanup(now+31*86400);eq(#S.List(false),0);eq(ns.Runtime.root.ui.tab,2)
end)
test("future report store is left untouched",function()
    reset();local future={version=99,unknown={important=true}};ns.Runtime.root.pvpReports=future
    assert(not S.Open(ns.Runtime.root,now));assert(rawequal(ns.Runtime.root.pvpReports,future));reset()
end)
test("serial IDs survive reopen",function()
    local one=S.NextId(a,now);assert(S.Open(ns.Runtime.root,now));local two=S.NextId(a,now);assert(one~=two)
end)
test("author confirmation cannot authenticate relay-only identity fields",function()
    reset();assert(ns.GuildNative.Start());local author=report();local fake=V.Copy(author)
    fake.killer={guid=enemy.guid,name="Enemy",realm="Forged",id="Enemy-Forged"};fake.attackers={V.Copy(fake.killer)}
    assert(S.Put(fake,"relay",now,false));assert(incoming("direct",{row=author},a))
    eq(S.data.shared[author.id].row.killer.id,nil);eq(V.Count(ns.GuildNative.channel.session.incidents),0)
end)
test("legacy observations cannot bypass victim verification by renaming",function()
    reset();assert(ns.GuildNative.Start());local c=ns.GuildNative.channel
    local row={id="renamed",guildId=c.context.guildId,enemy=enemy,victim=a,occurredAt=now,source="observed",location={zone="Test"}}
    local e={version=1,guildId=c.context.guildId,senderId=b.id,id="renamed",kind="state",message={version=1,guildId=c.context.guildId,senderId=b.id,incidents={row},claims={}}}
    assert(not ns.Channel.Receive(c,e,b.id,{[a.id]=a,[b.id]=b}));eq(V.Count(c.session.incidents),0)
end)
test("fresh mixed recap is terminal despite recent PvP combat buffer",function()
    reset();D.Attack(hit(enemy.guid,playerFlags,-1,now-1))
    C_DeathRecap={HasRecapEvents=function()return true end,GetRecapEvents=function()return {hit(enemy.guid,playerFlags,-1,now-1),hit("Creature-1-N",0x40+0x800,0)}end}
    D.OnDeath();D.Tick(.31);eq(D.pending,nil);eq(#S.List(true),0);eq(D.status,"mixed_finish_ignored");C_DeathRecap=nil
end)
test("unchanged recap cannot be reused by a second death or reload",function()
    reset();C_DeathRecap={HasRecapEvents=function()return true end,GetRecapEvents=function()return {hit(enemy.guid,playerFlags,0)}end}
    D.OnDeath();D.Tick(.31);eq(#S.List(true),1);eq(S.data.lastRecapStamp,now)
    D.dead=false;D.OnDeath();D.Tick(.31);D.Tick(.71);D.Tick(1.01);eq(#S.List(true),1)
    assert(S.Open(ns.Runtime.root,now));D.Initialize();eq(D.lastRecapStamp,now);C_DeathRecap=nil
end)
test("capacity evicted older direct report is handled without Lua error",function()
    reset();assert(ns.GuildNative.Start());S.data.settings.maxShared=50
    for i=1,50 do local r=report();r.id=a.id..":"..now..":"..i;assert(S.Put(r,"author",now,false))end
    local older=report();older.at=now-1;older.id=a.id..":"..(now-1)..":old"
    local ok,why=incoming("direct",{row=older},a);assert(not ok and why=="capacity_evicted");eq(#S.List(false),50)
end)
test("duplicate death event and exclusions",function()
    reset();D.OnDeath();assert(D.pending);local id=D.pending.id;D.OnDeath();eq(D.pending.id,id)
    for _,kind in ipairs({"pvp","arena"})do D.Reset();IsInInstance=function()return true,kind end;D.OnDeath();eq(D.pending,nil)end
    IsInInstance=function()return false,"none"end;D.Reset();D.duel=true;D.OnDeath();eq(D.pending,nil);D.duel=false
end)
test("duel to death stays excluded when finish precedes PLAYER_DEAD",function()
    reset();D.frame.scripts.OnEvent(nil,"DUEL_TO_THE_DEATH_REQUESTED");assert(D.duel)
    D.frame.scripts.OnEvent(nil,"DUEL_FINISHED");D.OnDeath();eq(D.pending,nil)
    D.duelUntil=nil;D.duel=false
end)
test("recap retries preserve captured scope and only one report",function()
    reset();O.cache[enemy.guid]={actor=V.Copy(enemy),seen=O.clock}
    local n=0;C_DeathRecap={HasRecapEvents=function()n=n+1;return n>=2 end,GetRecapEvents=function()return {hit(enemy.guid,playerFlags,0)}end}
    D.OnDeath();local id=D.pending.id;D.Tick(.31);assert(D.pending);D.Tick(.71);eq(D.pending,nil);assert(S.data.personal[id]);eq(#S.List(true),1)
    C_DeathRecap=nil
end)
test("stale recap never blames a previous victim",function()
    reset();C_DeathRecap={HasRecapEvents=function()return true end,GetRecapEvents=function()return {hit(enemy.guid,playerFlags,0,now-10)}end}
    D.OnDeath();D.Tick(.31);D.Tick(.71);D.Tick(1.01);eq(#S.List(true),0);C_DeathRecap=nil
end)
test("direct victim must match transport sender",function()
    reset();assert(ns.GuildNative.Start());local r=report()
    local ok,why=incoming("direct",{row=r},b);assert(not ok);eq(why,"direct_victim_mismatch");eq(#S.List(false),0)
    assert(incoming("direct",{row=r},a));eq(S.data.shared[r.id].trust,"author")
end)
test("relay cannot affect bounty and author confirmation can",function()
    reset();assert(ns.GuildNative.Start());local r=report();r.killer=V.Copy(enemy);r.attackers={V.Copy(enemy)}
    assert(S.Put(r,"relay",now,false));assert(not ns.ReportsRuntime.Project(r));eq(V.Count(ns.GuildNative.channel.session.incidents),0)
    assert(incoming("direct",{row=r},a));eq(V.Count(ns.GuildNative.channel.session.incidents),1)
    assert(incoming("direct",{row=r},a));eq(V.Count(ns.GuildNative.channel.session.incidents),1)
end)
test("malformed pages unsolicited messages and flood are bounded",function()
    reset();assert(ns.GuildNative.Start())
    assert(not incoming("page",{rows={}},b))
    for i=1,30 do incoming("seek",{request="seek"..i},b)end
    assert(V.Count(Y.serving)<=1);eq(Y.rates[b.id].n,31)
end)
test("queue saturation and expiry never delete personal reports",function()
    reset();assert(ns.GuildNative.Start());for i=1,40 do Y.Publish(report())end;eq(#Y.queue,32)
    local r=report();assert(S.Put(r,"author",now,true));Y.Tick(40);assert(#Y.queue<=32);eq(#S.List(true),1)
end)
test("exact own death can populate personal bounty with sharing inactive",function()
    reset();ns.GuildNative.Suspend();ns.Runtime.db=assert(ns.Store.New(ns.Persistence.scope))
    local r=report();r.killer=V.Copy(enemy);r.attackers={V.Copy(enemy)}
    assert(S.Put(r,"author",now,false));assert(ns.ReportsRuntime.Project(r));eq(V.Count(ns.Runtime.db.incidents),1)
    assert(ns.ReportsRuntime.Project(r));eq(V.Count(ns.Runtime.db.incidents),1)
end)
test("test mode and sharing off never publish reports",function()
    reset();assert(ns.GuildNative.Start());ns.GuildNative.testMode=true;assert(not Y.Publish(report()));ns.GuildNative.testMode=false
    S.data.settings.sharing=false;assert(not Y.Publish(report()));eq(#Y.queue,0)
end)
test("confirmation retries independently of selected sync sources",function()
    reset();assert(ns.GuildNative.Start());local r=report();assert(S.Put(r,"relay",now,false))
    Y.Confirm(r);Y.beginAt=nil;Y.Tick(2);eq(Y.confirmations[r.id].attempt,1)
    Y.Tick(46);eq(Y.confirmations[r.id].attempt,2);Y.Tick(91);eq(Y.confirmations[r.id].attempt,3)
    Y.Tick(150);eq(Y.confirmations[r.id].attempt,3)
    assert(incoming("direct",{row=r},a));eq(Y.confirmations[r.id],nil)
end)
test("projection scan passes incomplete recent rows and recovers after reload",function()
    reset();assert(ns.GuildNative.Start());ns.ReportsRuntime.projectKeys=nil;ns.ReportsRuntime.projectIndex=1
    for i=1,12 do local r=report();r.id=a.id..":"..now..":"..i;r.confidence="estimated";assert(S.Put(r,"relay",now,false))end
    local r=report();r.id=a.id..":"..now..":eligible";r.killer=V.Copy(enemy);r.attackers={V.Copy(enemy)};assert(S.Put(r,"author",now,false))
    for i=1,5 do ns.ReportsRuntime.frame.scripts.OnUpdate(nil,2.1)end
    eq(V.Count(ns.GuildNative.channel.session.incidents),1)
    ns.ReportsRuntime.projection={};assert(ns.ReportsRuntime.Project(r));assert(ns.ReportsRuntime.projection[r.id])
end)
test("report-derived bounties exceed network page limit without full-state broadcast",function()
    reset();assert(ns.GuildNative.Start())
    for i=1,130 do local r=report();r.id=a.id..":"..now..":"..i;r.killer=V.Copy(enemy);r.attackers={V.Copy(enemy)}
        assert(S.Put(r,"author",now,false));assert(ns.ReportsRuntime.Project(r))
    end
    local c=ns.GuildNative.channel;eq(V.Count(c.session.incidents),130)
    local state=assert(ns.Channel.State(c,"bounded"));eq(#state.message.incidents,0)
    assert(ns.Guild.Restore(ns.Guild.Snapshot(c.session),c.context.guildId,c.context.owner.id,c.session.members))
end)
test("UI preserves tabs and exposes controls plus paged report journal",function()
    reset();assert(ns.GuildNative.Start());local r=report();assert(S.Put(r,"relay",now,false));ns.UI.Create();ns.UI.window.tab=3;ns.UI.Refresh()
    assert(ns.UI.window.panels[3].current.report);eq(ns.UI.window.panels[3].current.trust,"relay")
    eq(#ns.UI.window.tabs,4);assert(ns.UI.window.reportStatus)
    for i=2,105 do local x=V.Copy(r);x.id=a.id..":"..now..":"..i;assert(S.Put(x,"relay",now,false))end
    ns.UI.Refresh();eq(#ns.UI.window.panels[3].rows,100);assert(ns.UI.window.next:IsShown());ns.UI.window.next.scripts.OnClick();eq(ns.UI.window.pages[3],2)
end)
return {passed=passed}
