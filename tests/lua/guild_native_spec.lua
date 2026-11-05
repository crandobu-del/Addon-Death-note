local ns=...
local N,C,V=ns.GuildNative,ns.GuildContext,ns.Validation
local passed=0
local function test(name,fn) local ok,reason=pcall(fn);assert(ok,name..": "..tostring(reason));passed=passed+1 end
local function eq(a,b) assert(a==b,tostring(a).." ~= "..tostring(b)) end
local actualSecret=issecretvalue
local secret={}
issecretvalue=function(v) return v==secret end
WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
local guild=123;local restricted=false;local sendCode=0;local sent={};local member=true
C_Club={GetGuildClubId=function() return guild end,GetClubInfo=function() return {name=ns.Config.guildName} end}
C_GuildInfo={MemberExistsByName=function() return member end}
UnitFullName=function() return "Lyra","Forever" end
C_ChatInfo={RegisterAddonMessagePrefix=function() return 0 end,
    AreOutgoingAddonChatMessagesRestricted=function() return restricted end,
    SendAddonMessage=function(prefix,text,channel) sent[#sent+1]={prefix=prefix,text=text,channel=channel};return sendCode end}
local runtime={writable=true,root={formatVersion=1,ledger={untouched=true}}}
N.Bind(runtime,function() end)
local function start() guild=123;member=true;restricted=false;sendCode=0;assert(N.Start()) end
local function incoming(kind,id,extras,sender)
    local e={version=1,guildId="guild:123",senderId=sender or "Kaelan-Forever",kind=kind,id=id}
    for k,v in pairs(extras or {}) do e[k]=v end
    for _,p in ipairs(assert(ns.Wire.Packets(e,id))) do N.Receive(N.prefix,p,"GUILD",sender or "Kaelan-Forever") end
end
test("Forever guild and canonical own identity",function()
    local c=assert(C.Current());eq(c.guildId,"guild:123");eq(c.owner.id,"Lyra-Forever")
end)
test("protected names and K wrappers refused",function()
    eq(C.Actor(secret,"Forever"),nil);eq(C.Actor("|Kabc|k","Forever"),nil)
    eq(C.Actor("Kaelan",secret),nil);eq(C.Actor("Kaelan-Forever","Other").id,"Kaelan-Forever")
end)
test("unavailable membership and wrong client fail closed",function()
    member=false;eq(C.Current(),nil);member=true
    WOW_PROJECT_ID=1;eq(C.Current(),nil);WOW_PROJECT_ID=18
end)
test("enum zero means prefix registered and enqueued not acknowledged",function()
    start();assert(N.channel);eq(N.channel.acks,0);assert(#N.queue>0);assert(runtime.root.guilds)
    assert(runtime.root.ledger.untouched)
end)
test("duplicate prefix enum accepted invalid prefix rejected",function()
    C_ChatInfo.RegisterAddonMessagePrefix=function() return 1 end;assert(N.Start())
    C_ChatInfo.RegisterAddonMessagePrefix=function() return 2 end;eq(N.Start(),false)
    C_ChatInfo.RegisterAddonMessagePrefix=function() return 0 end
end)
test("outgoing restricted never calls send",function()
    start();restricted=true;local count=#sent;N.Tick(1);eq(#sent,count);eq(N.status,"restricted");assert(#N.queue>0)
end)
test("throttled frame kept for retry, success zero removes one",function()
    start();sendCode=3;local count=#N.queue;N.Tick(4);eq(#N.queue,count)
    sendCode=0;N.Tick(4);eq(#N.queue,count-1);eq(sent[#sent].channel,"GUILD");eq(N.channel.acks,0)
end)
test("secret and non guild messages ignored",function()
    start();N.Receive(secret,"x","GUILD","Kaelan");N.Receive(N.prefix,secret,"GUILD","Kaelan")
    N.Receive(N.prefix,"x","WHISPER","Kaelan");eq(V.Count(N.pool),0);eq(N.channel.acks,0)
end)
test("test received and ack queued without adding incident",function()
    start();local count=#N.queue;incoming("test","test1")
    assert(#N.queue>count);eq(V.Count(N.channel.session.incidents),0);eq(N.channel.peers["Kaelan-Forever"],true)
end)
test("only correlated ack counts once per member",function()
    start();local e=ns.Channel.Envelope(N.channel,"test","ourtest");assert(N.Enqueue(e,true))
    incoming("ack","ack1",{ack="unknown",target="Lyra-Forever"});eq(N.channel.acks,0)
    incoming("ack","ack2",{ack="ourtest",target="Lyra-Forever"});eq(N.channel.acks,1)
    incoming("ack","ack3",{ack="ourtest",target="Lyra-Forever"});eq(N.channel.acks,1)
end)
test("hostile primitive and malformed state cannot throw",function()
    start();for _,p in ipairs(assert(ns.Wire.Packets(true,"bool"))) do N.Receive(N.prefix,p,"GUILD","Kaelan-Forever") end
    incoming("state","bad",{message={incidents=true,claims={}}});eq(V.Count(N.channel.session.incidents),0)
end)
test("outsider cannot add peer",function()
    start();local original=C_GuildInfo.MemberExistsByName
    C_GuildInfo.MemberExistsByName=function(name) return name=="Lyra-Forever" end
    incoming("test","outsider");eq(V.Count(N.channel.peers),0)
    C_GuildInfo.MemberExistsByName=original
end)
test("guild change purges queue without sending",function()
    start();guild=456;local count=#sent;N.Tick(4);eq(N.channel,nil);eq(#N.queue,0);eq(#sent,count)
end)
test("explicit stop preserves cache and disables preference",function()
    start();local cache=runtime.root.guilds;SlashCmdList.SYNDICATROUGESYNC("arreter")
    eq(runtime.root.syncEnabled,false);eq(N.channel,nil);eq(runtime.root.guilds,cache)
end)
test("read only profile never starts",function()
    N.runtime={writable=false};eq(N.Start(),false);N.runtime=runtime
end)
test("bootstrap opens shared provider, checkpoints and demo stays isolated",function()
    guild=123
    for _,f in ipairs(SR_TEST_FRAMES) do
        if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge") end
    end
    SlashCmdList.SYNDICATROUGESYNC("activer");eq(ns.UI.provider.shared,true)
    assert(N.channel.root==ns.Runtime.root)
    assert(ns.Persistence.Checkpoint(ns.Runtime,{tab=2}))
    assert(ns.Runtime.root.guilds["guild:123"]);eq(ns.Runtime.root.ui.tab,2)
    SlashCmdList.SYNDICATROUGEDEMO();eq(ns.UI.provider.demo,true)
    eq(V.Count(N.channel.session.incidents),0)
    SlashCmdList.SYNDICATROUGE();eq(ns.UI.provider.shared,true);eq(ns.UI.provider.demo,false)
end)
issecretvalue=actualSecret
return {passed=passed}
