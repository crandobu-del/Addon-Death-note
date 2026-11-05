local ns=...
local W,Ch,G,V=ns.Wire,ns.Channel,ns.Guild,ns.Validation
local passed=0
local function test(name,fn) local ok,reason=pcall(fn);assert(ok,name..": "..tostring(reason));passed=passed+1 end
local function eq(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local function actor(name) return {id=name.."-Forever",name=name,realm="Forever"} end
local a,b=actor("Lyra"),actor("Kaelan")
local roster={[a.id]=a,[b.id]=b}
local function fresh(owner,root) return assert(Ch.New({guildId="guild:1",owner=owner},root or {},roster)) end
local function incident(id) return {id=id or "i",guildId="guild:1",enemy=actor("Enemy"),victim=a,occurredAt=100,source="manual",location={zone="Strangleronce",mapId=101,x=.32,y=.29}} end
local function send(from,to,id)
    local packets=assert(W.Packets(assert(Ch.State(from,id)),id));local pool={};local msg
    for i=#packets,1,-1 do msg=W.Receive(pool,from.context.owner.id,packets[i],1) end
    return Ch.Receive(to,msg,from.context.owner.id,roster)
end
test("codec roundtrip Unicode, delimiters, arrays, false and nested maps",function()
    local value={name="Éléonore;:|",rows={{x=.32}},flag=false}
    assert(V.Same(value,assert(W.Decode(assert(W.Encode(value))))))
end)
test("reject source text without executing it",function() eq(W.Decode("return os.execute('bad')"),nil) end)
test("reject trailing data and duplicate keys",function() eq(W.Decode("t0:extra"),nil);eq(W.Decode("t2:s1:xys1:xn"),nil) end)
test("reject truncation, absurd lengths and complexity",function()
    for _,s in ipairs({"s9:x","s999999999:x","t999999:","d3:nan","x"}) do eq(W.Decode(s),nil) end
    local t={};t.self=t;eq(W.Encode(t),nil)
    local t={};local p=t;for i=1,14 do p.x={};p=p.x end;eq(W.Encode(t),nil)
end)
test("packet size and reversed reassembly",function()
    local value={text=string.rep("é",1400)};local packets=assert(W.Packets(value,"tx"));local pool={},result
    for i=#packets,1,-1 do assert(#packets[i]<=240);result=W.Receive(pool,"a",packets[i],0) end
    assert(V.Same(result,value));eq(V.Count(pool),0)
end)
test("duplicate fragments do not complete early",function()
    local packets=W.Packets({text=string.rep("a",300)},"tx");local pool={}
    eq(W.Receive(pool,"a",packets[1],0),nil);eq(W.Receive(pool,"a",packets[1],0),nil)
    assert(W.Receive(pool,"a",packets[2],0))
end)
test("conflicting fragment rejected and memory bounded",function()
    local pool={};W.Receive(pool,"a","1;x;1;2;hello",0)
    local _,reason=W.Receive(pool,"a","1;x;1;2;world",0);eq(reason,"packet_conflict")
    for i=1,5 do W.Receive(pool,"sender"..i,"1;x;1;2;part",0) end
    eq(V.Count(pool),4);W.Receive(pool,"new","1;x;1;2;part",301);eq(V.Count(pool),1)
end)
test("fragments isolated by sender",function()
    local packets=W.Packets({text=string.rep("a",300)},"tx");local pool={}
    W.Receive(pool,"a",packets[1],0);eq(W.Receive(pool,"b",packets[2],0),nil)
end)
test("two endpoints merge a real-form record through framed bytes",function()
    local x,y=fresh(a),fresh(b);assert(Ch.Change(x,"incident",incident()));assert(send(x,y,"tx"))
    eq(V.Count(y.session.incidents),1);assert(y.root.guilds["guild:1"]);eq(y.root.ledger,nil)
end)
test("catchup and repeated state do not duplicate rewards",function()
    local x,y=fresh(a),fresh(b);assert(Ch.Change(x,"incident",incident()));assert(send(x,y,"tx"))
    assert(Ch.Change(y,"claim",{id="v",guildId="guild:1",enemyId="Enemy-Forever",avenger=b,occurredAt=200,incidentIds={"i"}}))
    assert(send(y,x,"v1"));assert(send(y,x,"v2"));eq(ns.Reputation.Ranking(x.session.db)[1].reputation,1)
    local restored=fresh(a,x.root);eq(ns.Reputation.Ranking(restored.session.db)[1].reputation,1)
end)
test("personal notification state never exported",function()
    local x,y=fresh(a),fresh(b);Ch.Change(x,"incident",incident());send(x,y,"a1")
    Ch.Change(y,"claim",{id="v",guildId="guild:1",enemyId="Enemy-Forever",avenger=b,occurredAt=200,incidentIds={"i"}});send(y,x,"b1")
    local note=ns.Notifications.List(x.session.db,a.id)[1];assert(Ch.Change(x,"read",note.id))
    local msg=Ch.State(x,"state");eq(msg.message.notificationState,nil);eq(msg.ui,nil)
    assert(fresh(a,x.root).session.notificationState[note.id].read)
end)
test("reject demo exports and imports",function()
    local x,y=fresh(a),fresh(b);local row=incident();row.source="demo"
    eq(Ch.Change(x,"incident",row),false);assert(G.AddIncident(x.session,row));eq(Ch.State(x,"demo"),nil)
    local msg=Ch.Envelope(x,"state","bad");msg.message=assert(ns.Protocol.Export(x.session))
    eq(Ch.Receive(y,msg,a.id,roster),false);eq(V.Count(y.session.incidents),0)
end)
test("wrong sender guild target and version rejected atomically",function()
    local x,y=fresh(a),fresh(b);Ch.Change(x,"incident",incident());local msg=Ch.State(x,"a")
    eq(Ch.Receive(y,msg,b.id,roster),false);msg.guildId="other";eq(Ch.Receive(y,msg,a.id,roster),false)
    msg.guildId="guild:1";msg.version=99;eq(Ch.Receive(y,msg,a.id,roster),false)
    msg.version=1;msg.target="other";eq(Ch.Receive(y,msg,a.id,roster),false);eq(V.Count(y.session.incidents),0)
end)
test("invalid cache preserved",function()
    local root={guilds={["guild:1"]={version=999}}};local before=V.Copy(root)
    eq(Ch.New({guildId="guild:1",owner=a},root,roster),nil);assert(V.Same(root,before))
end)
test("immutable collision preserves saved cache",function()
    local x,y=fresh(a),fresh(b);Ch.Change(x,"incident",incident());send(x,y,"a1")
    local before=V.Copy(y.root);x.session.incidents.i.location.zone="elsewhere"
    eq(send(x,y,"a2"),false);assert(V.Same(before,y.root))
end)
return {passed=passed}
