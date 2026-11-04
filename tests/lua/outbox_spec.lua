local ns = ...
local count = 0
local function eq(a,b) assert(a == b, tostring(a) .. " ~= " .. tostring(b)) end
local function test(name, fn) local ok,why=pcall(fn);assert(ok,name..": "..tostring(why));count=count+1 end
local a={id="a",name="Lÿra",realm="Forever"}
local b={id="b",name="Kaëlan",realm="Forever"}
local roster={a,b}
local function session(owner) return assert(ns.Guild.New("guild",owner or "a",roster)) end
local function incident() return {id="i",guildId="guild",enemy={id="e",name="Ennemi",realm="Forever"},victim=a,
 occurredAt=100,location={zone="Strangleronce"},source="demo"} end
local function claim(id,actor) return {id=id,guildId="guild",enemyId="e",avenger=actor,occurredAt=200,incidentIds={"i"}} end
test("export contains only a versioned demo feed for Forever",function()
 local s=session();ns.Guild.AddIncident(s,incident());local output=assert(ns.DiscordOutbox.Build(s))
 eq(output.version,1);eq(output.target,"forever");eq(output.mode,"demo");eq(output.guildName,"Le Syndicat Rouge")
 eq(#output.incidents,1);eq(output.senderId,nil);eq(output.notificationState,nil);eq(output.members,nil)
end)
test("personal read and thanks are never part of an export",function()
 local s=session();ns.Guild.AddIncident(s,incident());local other=session("b")
 ns.Guild.Receive(other,ns.Protocol.Export(s),"a");ns.Guild.Claim(other,claim("v",b))
 ns.Guild.Receive(s,ns.Protocol.Export(other),"b")
 local notification=ns.Notifications.List(s.db,"a")[1]
 ns.Notifications.Thank(s.db,notification.id,"a")
 local output=assert(ns.DiscordOutbox.Build(s));eq(output.preferences,nil);eq(output.notifications,nil)
 eq(output.incidents[1].vengeanceId,nil);eq(output.claims[1].reward,nil)
end)
test("pending claims are exported instead of disappearing",function()
 local s,t=session(),session("b");ns.Guild.AddIncident(s,incident());ns.Guild.Receive(t,ns.Protocol.Export(s),"a")
 ns.Guild.Claim(s,claim("v1",a));ns.Guild.Claim(t,claim("v2",b));ns.Guild.Receive(s,ns.Protocol.Export(t),"b")
 local output=assert(ns.DiscordOutbox.Build(s));eq(#output.claims,2);eq(#output.incidents,1)
end)
test("snapshot export cannot switch guild or register owner",function()
 local s=session();ns.Guild.AddIncident(s,incident());local snapshot=ns.Guild.Snapshot(s)
 eq(ns.DiscordOutbox.FromSnapshot(snapshot,"wrong","a",roster),nil)
 eq(ns.DiscordOutbox.FromSnapshot(snapshot,"guild","b",roster),nil)
end)
test("export is a defensive copy and is deterministic",function()
 local s=session();ns.Guild.AddIncident(s,incident());local first=ns.DiscordOutbox.Build(s)
 assert(ns.Validation.Same(first,ns.DiscordOutbox.Build(s)))
 first.incidents[1].enemy.name="changed";eq(s.incidents.i.enemy.name,"Ennemi")
end)
return {passed=count}
