local ns = ...
local G, P, V = ns.Guild, ns.Protocol, ns.Validation
local passed = 0
local function eq(a,b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn)
    local ok, reason = pcall(fn); assert(ok, name .. ": " .. tostring(reason)); passed = passed + 1
end
local function actor(id) return { id = id, name = id, realm = "Forever" } end
local roster = { actor("lyra"), actor("kaelan"), actor("thorin") }
local function fresh(owner) return assert(G.New("guild", owner or "lyra", roster)) end
local function incident(id)
    return { id = id or "i", guildId = "guild", enemy = actor("enemy"), victim = actor("lyra"),
        occurredAt = 100, source = "demo", location = { zone = "Strangleronce" } }
end
local function claim(id, owner, ids)
    return { id = id, guildId = "guild", enemyId = "enemy", avenger = actor(owner),
        occurredAt = 200, incidentIds = ids or {"i"} }
end
local function export(s) return assert(P.Export(s)) end
local function send(a,b) return G.Receive(b, export(a), a.ownerId) end
local function reputation(s)
    local sum = 0
    for _, row in ipairs(ns.Reputation.Ranking(s.db)) do sum = sum + row.reputation end
    return sum
end

test("a missing member catches up incidents and a vengeance", function()
    local a,b = fresh(),fresh("kaelan")
    assert(G.AddIncident(a,incident())); assert(send(a,b)); eq(V.Count(b.incidents),1)
    assert(G.Claim(b,claim("v","kaelan"))); assert(send(b,a))
    eq(reputation(a),1); eq(reputation(b),1)
    eq(#ns.Notifications.List(a.db,"lyra"),1)
    eq(#ns.Notifications.List(b.db,"kaelan"),0)
end)
test("repeated messages do not multiply incidents or reputation", function()
    local a,b = fresh(),fresh("kaelan")
    G.AddIncident(a,incident()); send(a,b); G.Claim(b,claim("v","kaelan")); send(b,a)
    local before = G.Snapshot(a)
    for _=1,4 do local ok,reason=send(b,a);eq(ok,true);eq(reason,"unchanged") end
    assert(V.Same(before,G.Snapshot(a)));eq(reputation(a),1)
end)
test("foreign guild and unknown sender are rejected without mutation", function()
    local a,b = fresh(),fresh("kaelan");G.AddIncident(a,incident())
    local message=export(a);message.guildId="other"
    eq(G.Receive(b,message,"lyra"),false);eq(V.Count(b.incidents),0)
    message=export(a);message.senderId="stranger"
    eq(G.Receive(b,message,"stranger"),false);eq(V.Count(b.incidents),0)
end)
test("payload identity cannot replace the transport sender", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident())
    eq(G.Receive(b,export(a),"thorin"),false);eq(V.Count(b.incidents),0)
end)
test("unknown protocol and sparse record arrays are rejected", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident())
    local message=export(a);message.version=999;eq(G.Receive(b,message,"lyra"),false)
    message=export(a);message.incidents[2]=message.incidents[1];message.incidents[1]=nil
    eq(G.Receive(b,message,"lyra"),false)
end)
test("a changed incident ID rejects an otherwise valid new incident atomically", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident());send(a,b)
    local row=incident();row.location.zone="elsewhere"
    local message=export(a);message.incidents={row,incident("new")}
    local before=G.Snapshot(b);local ok,reason=G.Receive(b,message,"lyra")
    eq(ok,false);eq(reason,"incident_id_conflict");assert(V.Same(before,G.Snapshot(b)))
end)
test("outsider victims and avengers do not enter a guild register", function()
    local a=fresh();local row=incident();row.victim=actor("stranger")
    eq(G.AddIncident(a,row),false);eq(V.Count(a.incidents),0)
    G.AddIncident(a,incident());local message=export(a);message.claims={claim("v","stranger")}
    eq(G.Receive(a,message,"lyra"),false);eq(reputation(a),0)
end)
test("concurrent overlapping claims converge to pending with zero duplicate rewards", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident());send(a,b)
    G.Claim(a,claim("v-a","lyra"));G.Claim(b,claim("v-b","kaelan"))
    local ma,mb=export(a),export(b)
    assert(G.Receive(a,mb,"kaelan"));assert(G.Receive(b,ma,"lyra"))
    eq(reputation(a),0);eq(reputation(b),0);eq(V.Count(a.conflicts),2);eq(V.Count(b.conflicts),2)
    assert(V.Same(a.claims,b.claims));assert(V.Same(a.incidents,b.incidents))
    eq(#ns.Notifications.List(a.db,"lyra"),0)
    eq(a.db.incidents.i.vengeanceId,nil)
end)
test("a third member receives pending claims, not an invented settled result", function()
    local a,b,c=fresh(),fresh("kaelan"),fresh("thorin")
    G.AddIncident(a,incident());send(a,b);G.Claim(a,claim("v-a","lyra"));G.Claim(b,claim("v-b","kaelan"));send(a,b)
    assert(send(b,c));eq(V.Count(c.claims),2);eq(V.Count(c.conflicts),2);eq(reputation(c),0)
end)
test("a partly overlapping claim is never applied partially", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident("i"));G.AddIncident(a,incident("j"));send(a,b)
    G.Claim(a,claim("v-a","lyra",{"i","j"}));G.Claim(b,claim("v-b","kaelan",{"j"}));send(b,a)
    eq(reputation(a),0);eq(a.db.incidents.i.vengeanceId,nil);eq(a.db.incidents.j.vengeanceId,nil)
    eq(#G.View(a).pendingIncidentIds,2)
end)
test("disjoint claims converge and retain their independent rewards", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident("i"));G.AddIncident(a,incident("j"));send(a,b)
    G.Claim(a,claim("v-a","lyra",{"i"}));G.Claim(b,claim("v-b","kaelan",{"j"}))
    local ma,mb=export(a),export(b);G.Receive(a,mb,"kaelan");G.Receive(b,ma,"lyra")
    eq(reputation(a),2);eq(reputation(b),2);eq(V.Count(a.conflicts),0)
end)
test("a conflicting proposal survives restoration and cannot be overwritten locally", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident());send(a,b)
    G.Claim(a,claim("v-a","lyra"));G.Claim(b,claim("v-b","kaelan"));send(b,a)
    local restored=assert(G.Restore(G.Snapshot(a),"guild","lyra",roster))
    eq(V.Count(restored.conflicts),2);eq(reputation(restored),0)
    local changed=claim("v-a","lyra");changed.occurredAt=201
    local ok,reason=G.Claim(restored,changed);eq(ok,false);eq(reason,"vengeance_id_conflict")
    eq(restored.claims["v-a"].occurredAt,200)
end)
test("a changed vengeance ID is rejected even when sent by another member", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident());send(a,b);G.Claim(a,claim("v","lyra"));send(a,b)
    local message=export(a);message.claims[1].occurredAt=201
    local ok,reason=G.Receive(b,message,"lyra");eq(ok,false);eq(reason,"vengeance_id_conflict")
    eq(reputation(b),1)
end)
test("read and thanks remain private during synchronization", function()
    local a,b=fresh(),fresh("kaelan");G.AddIncident(a,incident());send(a,b);G.Claim(b,claim("v","kaelan"));send(b,a)
    local id=ns.Notifications.List(a.db,"lyra")[1].id
    local result=G.Execute(G.Snapshot(a),"guild","lyra",roster,"thank",id)
    eq(result.ok,true);eq(result.message.notificationState,nil)
    a=assert(G.Restore(result.snapshot,"guild","lyra",roster));send(a,b);send(b,a)
    eq(ns.Notifications.List(a.db,"lyra")[1].thanked,true)
    eq(next(b.notificationState),nil)
end)
test("record limits and logical size budget fail explicitly", function()
    local a=fresh();local message=export(a)
    for index=1,P.maxRecords+1 do message.incidents[index]=incident("i"..index) end
    local ok,reason=G.Receive(a,message,"lyra");eq(ok,false);eq(reason,"message_limit")
    eq(V.Count(a.incidents),0)
    message=export(a)
    for index=1,P.maxRecords do message.incidents[index]=incident("i"..index) end
    local ids={};for index=1,P.maxRecords do ids[index]="i"..index end
    for index=1,P.maxRecords do message.claims[index]=claim("v"..index,"lyra",ids) end
    ok,reason=G.Receive(a,message,"lyra");eq(ok,false);eq(reason,"message_budget")
end)
test("restoration cannot move a register into another owner or guild", function()
    local a=fresh();G.AddIncident(a,incident())
    eq(G.Restore(G.Snapshot(a),"guild","kaelan",roster),nil)
    eq(G.Restore(G.Snapshot(a),"other","lyra",roster),nil)
end)
test("a member ID cannot disguise a different name or realm", function()
    local a=fresh();G.AddIncident(a,incident())
    local message=export(a);message.incidents[1].victim.realm="another-realm"
    local ok,reason=G.Receive(a,message,"lyra");eq(ok,false);eq(reason,"member_identity_mismatch")
    message=export(a);message.claims={claim("v","kaelan")};message.claims[1].avenger.name="forged"
    ok,reason=G.Receive(a,message,"lyra");eq(ok,false);eq(reason,"member_identity_mismatch")
    eq(reputation(a),0)
end)
test("two separately bounded messages cannot overflow the merged register", function()
    local a,b=fresh(),fresh("kaelan")
    local message=export(a)
    for index=1,P.maxRecords do message.incidents[index]=incident("i"..index) end
    assert(G.Receive(a,message,"lyra"));G.AddIncident(b,incident("extra"))
    local before=G.Snapshot(a);local ok,reason=send(b,a)
    eq(ok,false);eq(reason,"message_limit");assert(V.Same(before,G.Snapshot(a)))
end)
return { passed = passed }
