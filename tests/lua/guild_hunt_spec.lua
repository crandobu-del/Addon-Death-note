local ns=...
for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end
local V,R,S,N,C=ns.Validation,ns.BountyRules,ns.Sightings,ns.GuildNative,ns.GuildContext
local passed=0
local function test(name,fn)local ok,err=pcall(fn);assert(ok,name..": "..tostring(err));passed=passed+1 end
local function eq(a,b)assert(a==b,tostring(a).." ~= "..tostring(b))end
local function actor(name)return{id=name.."-Forever",name=name,realm="Forever"}end
local a,b,enemy=actor("A"),actor("B"),actor("Enemy")
local function rows(count,spacing,victim)
    local out={};for i=1,count do out[i]={id="i"..i,guildId="g",enemy=enemy,victim=victim or a,occurredAt=100+i*(spacing or 1),source="observed",location={zone="Elwynn"}}end
    return out
end
test("successive triplets double rewards",function()
    for _,p in ipairs({{2,2,1},{3,6,2},{6,24,4},{9,72,8}})do local reward,m=R.Calculate(rows(p[1]));eq(reward,p[2]);eq(m,p[3])end
end)
test("strict hour boundary",function()local r=rows(3,1800);eq(R.Calculate(r),3);r[3].occurredAt=r[3].occurredAt-1;eq(R.Calculate(r),6)end)
test("window moves past older incidents",function()local r=rows(6,2000);eq(R.Calculate(r),6);r[4].occurredAt=9000;r[5].occurredAt=9001;r[6].occurredAt=9002;eq(R.Calculate(r),12)end)
test("different victims never unlock each others multiplier",function()local r=rows(2);local other=rows(2,1,b);for _,x in ipairs(other)do r[#r+1]=x end;eq(R.Calculate(r),4)end)
test("arrival order does not change reward",function()local r=rows(9);local expected=R.Calculate(r);r[1],r[9]=r[9],r[1];eq(R.Calculate(r),expected)end)
test("numeric overflow refused",function()local r=rows(180);local reward,_,why=R.Calculate(r);assert(not reward and why=="reward_limit")end)
local function dbFor(count)local db=assert(ns.Store.New("g"));for _,r in ipairs(rows(count))do assert(ns.Incidents.Add(db,r))end;return db end
local function claim(db,rule,ids)return{id="c",guildId="g",enemyId=enemy.id,avenger=b,occurredAt=1000,incidentIds=ids or {"i1","i2","i3"},rewardRule=rule}end
test("new reward agrees with board and round trip",function()
    local db=dbFor(3);eq(ns.Wanted.List(db)[1].reward,6);assert(ns.Wanted.List(db)[1].repeatGank)
    assert(ns.Vengeance.Resolve(db,claim(db,2)));eq(db.vengeances.c.reward,6)
    local restored=assert(ns.Store.Restore(ns.Store.Snapshot(db),"g"));eq(restored.vengeances.c.reward,6)
    restored.vengeances.c.reward=999;eq(ns.Reputation.Ranking(restored)[1].reputation,6)
    assert(not ns.Vengeance.Resolve(db,claim(db,2)));eq(ns.Store.Restore(ns.Store.Snapshot(restored),"g").vengeances.c.reward,6)
end)
test("historical claims without rule preserve base reward",function()local db=dbFor(3);assert(ns.Vengeance.Resolve(db,claim(db)));eq(db.vengeances.c.reward,3);eq(ns.Store.Restore(ns.Store.Snapshot(db),"g").vengeances.c.reward,3)end)
test("partial claim only pays its selected set",function()local db=dbFor(6);assert(ns.Vengeance.Resolve(db,claim(db,2,{"i1","i2"})));eq(db.vengeances.c.reward,2);eq(ns.Wanted.List(db)[1].reward,8)end)
test("unsupported reward rule refused",function()assert(not ns.Vengeance.Resolve(dbFor(3),claim(nil,99)))end)
test("guild claim publishes explicit rule",function()
    local g=assert(ns.Guild.New("g",b.id,{a,b}));for _,r in ipairs(rows(3))do assert(ns.Guild.AddIncident(g,r))end
    assert(ns.Guild.Claim(g,claim(nil)));eq(g.claims.c.rewardRule,2);eq(g.db.vengeances.c.reward,6)
    eq(ns.Guild.Restore(ns.Guild.Snapshot(g),"g",b.id,{[a.id]=a,[b.id]=b}).db.vengeances.c.reward,6)
end)
local actual=C.Current
test("access accepts only actual guild context",function()
    assert(ns.Access.Allowed());C_Club.GetClubInfo=function()return {name="Other"}end;assert(not ns.Access.Allowed())
    C_Club.GetClubInfo=function()return {name="Le Syndicat Rouge"}end
    local secret={};issecretvalue=function(v)return rawequal(v,secret)end
    C_Club.GetGuildClubId=function()return secret end;assert(not ns.Access.Allowed())
    C_Club.GetGuildClubId=function()error("missing")end;assert(not ns.Access.Allowed())
    C_Club.GetGuildClubId=function()return 1 end;assert(ns.Access.Allowed())
end)
local context={guildId="g",owner=a,nameMode="realm"}
C.Current=function()return context end
local chats,packets={},{}
GetServerTime=function()return 10000 end
C_ChatInfo={AreOutgoingAddonChatMessagesRestricted=function()return true end,InChatMessagingLockdown=function()return false end,
    SendChatMessage=function(text,kind)eq(kind,"GUILD");chats[#chats+1]=text end}
local function setup()
    S.Reset();S.clock=0;S.scan=0;N.testMode=false;context={guildId="g",owner=a,nameMode="realm"}
    N.channel=assert(ns.Channel.New(context,{}, {[a.id]=a,[b.id]=b}))
    for _,r in ipairs(rows(3))do assert(ns.Guild.AddIncident(N.channel.session,r))end
    N.changed=nil;ns.WantedMarkers.units={};N.queue={};N.nonce="1-2";N.counter=0
    C.Current=function()return context end
end
local row={enemyId=enemy.id,mapId=101,zone="Elwynn",at=10000}
test("presence reaches guild members in another zone",function()
    setup();assert(S.Receive(row,b));eq(#S.notes,1)
    local view=S.Decorate({notifications={}});eq(#view.notifications,1);eq(view.notifications[1].zone,"Elwynn")
    assert(S.Read(view.notifications[1].id));assert(S.Decorate({notifications={}}).notifications[1].read)
end)
test("two observers elect one chat sender",function()
    setup();local before=#chats;assert(S.Receive(row,b));assert(S.Receive(row,a));S.Tick(3.1);eq(#chats,before+1);eq(#S.notes,1)
    S.Receive(row,b);S.Tick(1);eq(#chats,before+1)
end)
test("other elected client never repeats chat",function()setup();context.owner=b;local before=#chats;S.Receive(row,b);S.Receive(row,a);S.Tick(3.1);eq(#chats,before)end)
test("closed and unknown bounties do not alert",function()
    setup();assert(ns.Guild.Claim(N.channel.session,{id="c",guildId="g",enemyId=enemy.id,avenger=a,occurredAt=1000,incidentIds={"i1","i2","i3"}}))
    assert(not S.Receive(row,b));eq(#S.notes,0)
end)
test("stale future malformed and markup sightings refused",function()
    setup();for _,changes in ipairs({{at=9900},{at=10006},{zone="|Hbad"},{mapId=0},{enemyId="not-wanted"}})do local bad=V.Copy(row);for k,v in pairs(changes)do bad[k]=v end;assert(not S.Receive(bad,b))end
end)
test("restricted chat still keeps addon notification",function()
    setup();C_ChatInfo.InChatMessagingLockdown=function()return true end;local before=#chats;S.Receive(row,a);S.Tick(3.1);eq(#chats,before);eq(#S.notes,1);eq(S.lastChat,"restricted_or_unavailable")
    C_ChatInfo.InChatMessagingLockdown=function()return false end
end)
test("test mode never sends real sightings",function()setup();N.testMode=true;assert(not S.Receive(row,a));assert(not S.Observe("nameplate1"));eq(#N.queue,0);N.testMode=false end)
test("ordinary wire validates membership before alert",function()
    setup();local e=ns.Channel.Envelope(N.channel,"sighting","s1");e.senderId=b.id;e.sighting=row
    assert(not ns.Channel.Receive(N.channel,e,b.id,{[a.id]=a}));assert(ns.Channel.Receive(N.channel,e,b.id,{[a.id]=a,[b.id]=b}));assert(not ns.Channel.Receive(N.channel,e,b.id,{[a.id]=a,[b.id]=b}))
end)
test("observing a public identity sends once without points",function()
    setup();local original=ns.WantedMarkers.Actor;ns.WantedMarkers.Actor=function()return enemy end
    C_Map.GetBestMapForUnit=function(unit)eq(unit,"player");return 101 end
    local snapshot=ns.Store.Snapshot(N.channel.session.db)
    assert(S.Observe("nameplate1"));local queued=#N.queue;assert(queued>0);assert(not S.Observe("nameplate1"));eq(#N.queue,queued)
    assert(V.Same(snapshot,ns.Store.Snapshot(N.channel.session.db)));ns.WantedMarkers.Actor=original
end)
test("queued observation waits for wire acceptance and does not reopen a peer election",function()
    setup();local before=#chats
    -- B's candidacy is already on the wire while A's is still queued.
    S.Receive(row,b);S.Tick(4);eq(#chats,before)
    S.Sent(row,a);S.Tick(4);eq(#chats,before);eq(#S.notes,1)
end)
test("wanted index is built once per database revision",function()
    setup();local calls=0;local original=ns.Wanted.List
    ns.Wanted.List=function(...)calls=calls+1;return original(...)end
    for i=1,80 do assert(S.Validate(row,context))end
    eq(calls,1);N.channel.session.db=V.Copy(N.channel.session.db);assert(S.Validate(row,context));eq(calls,2)
    ns.Wanted.List=original
end)
test("guild departure hides UI clears alerts transport and retains saved data",function()
    setup();ns.UI.SetProvider({View=function()return {wanted={},ranking={},journal={},notifications={}}end});ns.UI.Toggle();assert(ns.UI.window:IsShown())
    local stopped=0;SyndicatRouge.OnAccessRevoked(function()stopped=stopped+1 end)
    ns.ChatDeathProbe.report={running=true,events={PLAYER_DEAD={}},deaths=0};ns.KillProofProbe.report={running=true,received=0}
    local saved=V.Copy(SyndicatRougeCharacterDB);S.Receive(row,a);C.Current=function()return nil,"different_guild"end
    ns.Access.Refresh();assert(not ns.UI.window:IsShown());eq(#S.notes,0);assert(not N.channel);assert(V.Same(saved,SyndicatRougeCharacterDB))
    assert(stopped>0 and not ns.ChatDeathProbe.report.running and not ns.KillProofProbe.report.running)
    ns.ChatDeathProbe.Receive("PLAYER_DEAD");ns.KillProofProbe.Receive("x","y")
    eq(ns.ChatDeathProbe.report.deaths,0);eq(ns.KillProofProbe.report.received,0)
    local previous=ns.UI.provider;SyndicatRouge.ShowDemo({}, {},"fake",a.id);eq(ns.UI.provider,previous)
    SlashCmdList.SYNDICATROUGE();assert(not ns.UI.window:IsShown())
    C.Current=function()return context end;ns.Access.Refresh();assert(ns.Access.Allowed())
end)
return {passed=passed}
