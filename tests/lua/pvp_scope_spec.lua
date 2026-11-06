local ns = ...
local V, S, G = ns.Validation, ns.PvpScope, ns.Guild
local passed = 0
local function test(name, fn)
    local ok, reason = pcall(fn); assert(ok, name..": "..tostring(reason)); passed = passed + 1
end
local function actor(name) return {id=name.."-Forever",name=name,realm="Forever"} end
local a,b,e = actor("A"),actor("B"),actor("Enemy")
local function world() IsInInstance=function()return false,"none"end; issecretvalue=function()return false end end
local function incident(scope) return {id="i",guildId="g",enemy=e,victim=a,occurredAt=100,source="observed",location={zone="Elwynn"},instanceType=scope} end
local function claim(scope) return {id="c",guildId="g",enemyId=e.id,avenger=b,occurredAt=200,incidentIds={"i"},instanceType=scope} end
local function session()
    world(); local g=assert(G.New("g",b.id,{a,b})); assert(G.AddIncident(g,incident())); return g
end
for _,kind in ipairs({"pvp","arena"}) do
    test(kind.." cannot add deaths or close bounties",function()
        local g=session(); local before=G.Snapshot(g)
        IsInInstance=function()return true,kind end
        local ok,reason=G.AddIncident(g,incident()); assert(not ok and reason=="pvp_instance_excluded")
        ok,reason=G.Claim(g,claim()); assert(not ok and reason=="pvp_instance_excluded")
        assert(V.Same(before,G.Snapshot(g))); assert(#ns.Reputation.Ranking(g.db)==0)
        assert(#ns.Notifications.List(g.db,a.id)==0); assert(not g.db.incidents.i.vengeanceId)
    end)
    test(kind.." cannot enter by record or wire",function()
        world(); local db=assert(ns.Store.New("g")); assert(not ns.Incidents.Add(db,incident(kind)))
        assert(ns.Incidents.Add(db,incident())); assert(not ns.Vengeance.Resolve(db,claim(kind)))
        local msg={version=1,guildId="g",senderId=a.id,incidents={incident(kind)},claims={}}
        assert(not ns.Protocol.Decode(msg,"g",a.id,{[a.id]=a,[b.id]=b}))
        msg.incidents={incident()}; msg.claims={claim(kind)}
        assert(not ns.Protocol.Decode(msg,"g",a.id,{[a.id]=a,[b.id]=b}))
    end)
    test(kind.." blocks development local mutation route",function()
        local g=session(); IsInInstance=function()return true,kind end
        local r=ns.Core.Execute(ns.Store.Snapshot(g.db),"g","vengeance",claim(),b.id)
        assert(not r.ok and V.Same(r.snapshot,g.db))
        r=ns.Core.Execute(nil,"g","incident",incident(),a.id); assert(not r.ok and next(r.snapshot.incidents)==nil)
    end)
end
test("world mutations stamp scope and persist rewards",function()
    local g=session(); assert(g.incidents.i.instanceType=="none"); assert(G.Claim(g,claim()))
    assert(g.claims.c.instanceType=="none" and g.db.vengeances.c.reward==1)
    local restored=assert(G.Restore(G.Snapshot(g),"g",b.id,{a,b})); assert(restored.claims.c.instanceType=="none")
end)
test("leaving battleground resumes local recording",function()
    local g=session(); IsInInstance=function()return true,"pvp"end; assert(not G.Claim(g,claim()))
    world(); assert(G.Claim(g,claim()))
end)
test("world records received and restored while receiver is in arena",function()
    local g=session(); assert(G.Claim(g,claim())); local msg=assert(ns.Protocol.Export(g)); local snap=G.Snapshot(g)
    IsInInstance=function()return true,"arena"end
    local receiver=assert(G.New("g",a.id,{a,b})); assert(G.Receive(receiver,msg,b.id))
    assert(receiver.db.vengeances.c.reward==1); assert(G.Restore(snap,"g",b.id,{a,b}))
end)
test("old unscoped history remains restorable in battleground",function()
    world();local db=assert(ns.Store.New("g"));assert(ns.Incidents.Add(db,incident()));assert(ns.Vengeance.Resolve(db,claim()))
    IsInInstance=function()return true,"pvp"end;local restored=assert(ns.Store.Restore(ns.Store.Snapshot(db),"g"))
    assert(restored.vengeances.c.reward==1 and restored.incidents.i.instanceType==nil)
end)
test("unavailable erroneous and protected contexts fail closed",function()
    local g=session();local before=G.Snapshot(g)
    for _,fn in ipairs({false,function()error("unavailable")end,function()return nil,"none"end,
        function()return false,"arena"end,function()return true,"none"end,function()return false,"unknown"end,
        function()return false,nil end}) do
        IsInInstance=fn;assert(not G.Claim(g,claim()));assert(V.Same(before,G.Snapshot(g)))
    end
    world();local secret={};IsInInstance=function()return true,secret end;issecretvalue=function(v)return rawequal(v,secret)end
    assert(not G.Claim(g,claim()));assert(V.Same(before,G.Snapshot(g)))
    world();issecretvalue=nil;assert(not G.Claim(g,claim()))
end)
test("only requested instance types are excluded",function()
    for _,kind in ipairs({"party","raid","scenario"}) do
        local g=session();IsInInstance=function()return true,kind end;assert(G.Claim(g,claim()));assert(g.claims.c.instanceType==kind)
    end
end)
test("excluded origin cannot be relabelled by local ingestion",function()
    local g=session();assert(not G.Claim(g,claim("arena")));assert(not G.AddIncident(g,incident("pvp")))
end)
world()
return {passed=passed}
