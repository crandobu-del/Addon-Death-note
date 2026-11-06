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
    InChatMessagingLockdown=function()return false end,
    SendAddonMessage=function(prefix,text,channel) sent[#sent+1]={prefix=prefix,text=text,channel=channel};return sendCode end}
local runtime={writable=true,root={formatVersion=1,ledger={untouched=true}}}
N.Bind(runtime,function() end)
local function start() guild=123;member=true;restricted=false;sendCode=0;assert(N.Start()) end
local function incoming(kind,id,extras,sender)
    local e={version=1,guildId="guild:123",senderId=sender or "Kaelan-Forever",kind=kind,id=id}
    for k,v in pairs(extras or {}) do e[k]=v end
    for _,p in ipairs(assert(ns.Wire.Packets(e,id))) do N.Receive(N.prefix,p,"GUILD",sender or "Kaelan-Forever") end
end
local function probeSetup()
    start();restricted=true;N.probe=nil;N.lastProbeRequest=nil
    N.channel=nil;runtime.root.syncEnabled=false
    C_ChatInfo.InChatMessagingLockdown=function()return false end
end
test("Forever guild and canonical own identity",function()
    local c=assert(C.Current());eq(c.guildId,"guild:123");eq(c.owner.id,"Lyra-Forever")
end)
test("missing local realm uses public normalized realm API",function()
    local original,realmAPI=UnitFullName,GetNormalizedRealmName
    UnitFullName=function()return "Lyra",nil end
    GetNormalizedRealmName=function()return "Forever" end
    local context=assert(C.Current());eq(context.owner.id,"Lyra-Forever");eq(C.lastCheck.realm,"normalized_local")
    UnitFullName=original;GetNormalizedRealmName=realmAPI
end)
test("missing realm without public fallback has a specific reason",function()
    local original,realmAPI=UnitFullName,GetNormalizedRealmName
    UnitFullName=function()return "Lyra","" end;GetNormalizedRealmName=nil
    local context,reason=C.Current();eq(context,nil);eq(reason,"player_realm_unavailable")
    UnitFullName=original;GetNormalizedRealmName=realmAPI
end)
test("protected own identity never triggers public fallback",function()
    local original,realmAPI=UnitFullName,GetNormalizedRealmName;local calls=0
    GetNormalizedRealmName=function()calls=calls+1;return "Forever" end
    UnitFullName=function()return "Lyra",secret end
    local context,reason=C.Current();eq(context,nil);eq(reason,"player_identity_protected");eq(calls,0)
    UnitFullName=function()return secret,nil end
    eq(C.Current(),nil);eq(calls,0)
    UnitFullName=original;GetNormalizedRealmName=realmAPI
end)
test("hyphenated explicit character name is not parsed as a realm",function()
    local original=UnitFullName
    UnitFullName=function()return "Nom-Compose","Forever" end
    local context=assert(C.Current());eq(context.owner.name,"Nom-Compose");eq(context.owner.id,"Nom-Compose-Forever")
    eq(C.Actor("Nom-Compose-Forever","Forever").name,"Nom-Compose")
    UnitFullName=original
end)
test("short guild lookup allowed only for a proven local realm",function()
    local original,realmAPI=C_GuildInfo.MemberExistsByName,GetNormalizedRealmName
    GetNormalizedRealmName=function()return "Forever" end
    local queries={};C_GuildInfo.MemberExistsByName=function(name)queries[#queries+1]=name;return name=="Lyra" end
    assert(C.Member({id="Lyra-Forever",name="Lyra",realm="Forever"}));eq(#queries,2)
    queries={};eq(C.Member({id="Lyra-Other",name="Lyra",realm="Other"}),false);eq(#queries,1)
    C_GuildInfo.MemberExistsByName=original;GetNormalizedRealmName=realmAPI
end)
test("protected membership lookup never retries with a short name",function()
    local original,realmAPI=C_GuildInfo.MemberExistsByName,GetNormalizedRealmName;local calls=0
    C_GuildInfo.MemberExistsByName=function()return secret end
    GetNormalizedRealmName=function()calls=calls+1;return "Forever" end
    eq(C.Member({id="Lyra-Forever",name="Lyra",realm="Forever"}),false);eq(calls,0)
    C_GuildInfo.MemberExistsByName=original;GetNormalizedRealmName=realmAPI
end)
test("ambiguous hyphenated name cannot use short-name membership fallback",function()
    local original,realmAPI=C_GuildInfo.MemberExistsByName,GetNormalizedRealmName;local calls=0
    GetNormalizedRealmName=function()return "Forever" end
    C_GuildInfo.MemberExistsByName=function(name)calls=calls+1;return name=="Lyra-Other" end
    eq(C.Member({id="Lyra-Other-Forever",name="Lyra-Other",realm="Forever"}),false);eq(calls,1)
    C_GuildInfo.MemberExistsByName=original;GetNormalizedRealmName=realmAPI
end)
test("diagnostic reports only categories without changing data or queuing messages",function()
    local before=V.Copy(runtime.root);local queued=#N.queue
    SlashCmdList.SYNDICATROUGESYNC("diagnostic")
    assert(V.Same(before,runtime.root));eq(#N.queue,queued);eq(C.lastCheck.name,"public")
end)
test("protected names and K wrappers refused",function()
    eq(C.Actor(secret,"Forever"),nil);eq(C.Actor("|Kabc|k","Forever"),nil)
    eq(C.Actor("Kaelan",secret),nil);eq(C.Actor("Kaelan-Forever","Other").id,"Kaelan-Forever")
end)
test("own guild club confirms self even while roster lookup fails",function()
    member=false;local context=assert(C.Current());eq(C.lastCheck.member,"own_guild_club")
    assert(C.Member(context.owner,context))
    eq(C.Member({id="Kaelan-Forever",name="Kaelan",realm="Forever"},context),false)
    member=true
end)
test("wrong client fails closed",function()
    WOW_PROJECT_ID=1;eq(C.Current(),nil);WOW_PROJECT_ID=18
end)

test("regional transport uses exact full names and preserves legacy caches without conversion",function()
    local modeAPI,nameAPI,memberAPI=RegionalUniqueNamesEnabled,UnitNameUnmodified,C_GuildInfo.MemberExistsByName
    local savedRoot=runtime.root
    RegionalUniqueNamesEnabled=function()return true end
    UnitNameUnmodified=function()return "Lyra","Aube-Rouge" end
    local queries={}
    C_GuildInfo.MemberExistsByName=function(name)queries[#queries+1]=name;return name=="Kaelan Ombrelune" end
    runtime.root={guilds={["guild:123"]={legacy="preserved",incidents={old={unchanged=true}}}},guildDelivery={["guild:123"]={legacy="also preserved"}}}
    local legacy=V.Copy(runtime.root);guild=123;assert(N.Start())
    local context=N.channel.context
    eq(context.guildId,"guild:123:regional-v1");eq(context.owner.name,"Lyra Aube-Rouge");eq(context.owner.realm,"forever-regional")
    assert(V.Same(legacy.guilds["guild:123"],runtime.root.guilds["guild:123"]))
    assert(V.Same(legacy.guildDelivery["guild:123"],runtime.root.guildDelivery["guild:123"]))
    local peer=assert(C.Sender("Kaelan Ombrelune",context));eq(peer.id,"Kaelan Ombrelune-forever-regional")
    assert(C.Member(peer,context));eq(queries[#queries],"Kaelan Ombrelune")
    local e={version=1,guildId=context.guildId,senderId=peer.id,kind="test",id="regionaltest"}
    for _,packet in ipairs(assert(ns.Wire.Packets(e,e.id)))do N.Receive(N.prefix,packet,"GUILD","Kaelan Ombrelune")end
    eq(N.channel.peers[peer.id],true);eq(V.Count(N.channel.session.incidents),0)
    local ownPackets=assert(ns.Wire.Packets({version=1,guildId=context.guildId,senderId=context.owner.id,kind="test",id="ownregional"},"ownregional"))
    for _,packet in ipairs(ownPackets)do N.Receive(N.prefix,packet,"GUILD","Lyra Aube-Rouge")end
    eq(N.channel.peers[context.owner.id],nil)
    local snapshot=V.Copy(runtime.root);assert(N.Start());assert(V.Same(snapshot,runtime.root))
    RegionalUniqueNamesEnabled=function()return secret end
    eq(C.Current(),nil)
    RegionalUniqueNamesEnabled=function()return true end;UnitNameUnmodified=function()return "Lyra",secret end
    eq(C.Current(),nil)
    RegionalUniqueNamesEnabled=modeAPI;UnitNameUnmodified=nameAPI;C_GuildInfo.MemberExistsByName=memberAPI
    runtime.root=savedRoot;assert(N.Start())
end)

test("normal transport refuses absent failed protected and invalid lockdown query",function()
    start();local original=C_ChatInfo.InChatMessagingLockdown;local count=#sent
    for _,case in ipairs({{nil},{function()error("private error")end},{function()return secret end},{function()return 0 end}}) do
        C_ChatInfo.InChatMessagingLockdown=case[1];N.Tick(4);eq(#sent,count);eq(N.status,"restricted")
    end
    C_ChatInfo.InChatMessagingLockdown=original
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
test("native chat lockdown blocks sends while a public realm flag alone does not",function()
    start();restricted=true;C_ChatInfo.InChatMessagingLockdown=function()return true end
    local count=#sent;N.Tick(1);eq(#sent,count);eq(N.status,"restricted");eq(N.restrictionReason,"chat_lockdown");assert(#N.queue>0)
    C_ChatInfo.InChatMessagingLockdown=function()return false end
    N.Tick(1);eq(N.status,"active");eq(N.restrictionReason,"allowed_realm_flag_observed");eq(#sent,count+1)
end)

test("restriction diagnostics distinguish unavailable failed protected and invalid without sending",function()
    start();local original=C_ChatInfo.AreOutgoingAddonChatMessagesRestricted
    local cases={
        {nil,"restriction_api_missing"},
        {function()error("private error must not be reported")end,"restriction_query_failed"},
        {function()return secret end,"restriction_value_protected"},
        {function()return nil end,"restriction_result_invalid"},
        {function()return 0 end,"restriction_result_invalid"},
    }
    local count,queued=#sent,#N.queue
    for _,case in ipairs(cases) do
        C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=case[1]
        local blocked,reason=N.OutgoingRestriction();eq(blocked,true);eq(reason,case[2])
        N.Tick(4);eq(N.status,"restricted");eq(N.restrictionReason,case[2]);eq(#sent,count);eq(#N.queue,queued)
        SlashCmdList.SYNDICATROUGESYNC("diagnostic");eq(#sent,count);eq(#N.queue,queued)
    end
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=original
end)
test("explicit synthetic probe sends once without draining queue or mutating saved data",function()
    probeSetup();local count,queued,root=#sent,#N.queue,V.Copy(runtime.root)
    SlashCmdList.SYNDICATROUGESYNC("sonde")
    eq(#sent,count+1);eq(sent[#sent].prefix,"SRProbe1");eq(sent[#sent].channel,"GUILD")
    eq(N.probe.result,"accepted_code_0");eq(#N.queue,queued);assert(V.Same(root,runtime.root))
    N.Tick(1);eq(#sent,count+1);eq(#N.queue,queued)
    SlashCmdList.SYNDICATROUGESYNC("sonde");eq(#sent,count+1)
    N.ReceiveProbe("SRProbe1",N.probe.token,"GUILD","Lyra-Forever");eq(N.probe.echo,true)
    N.ReceiveProbe("SRProbe1",N.probe.token,"GUILD","Kaelan-Forever");eq(N.probe.peers,1)
    N.ReceiveProbe("SRProbe1",N.probe.token,"GUILD","Kaelan-Forever");eq(N.probe.peers,1)
    eq(#sent,count+1);assert(V.Same(root,runtime.root))
    N.Tick(120);eq(N.probe.finished,true);eq(#sent,count+1)
    N.ReceiveProbe("SRProbe1",N.probe.token,"GUILD","Other-Forever");eq(N.probe.peers,1)
end)

test("probe refuses lockdown absent failed protected and invalid queries",function()
    probeSetup();local original=C_ChatInfo.InChatMessagingLockdown;local count=#sent
    local cases={{nil},{function()return true end},{function()error("not logged")end},{function()return secret end},{function()return nil end},{function()return 0 end}}
    for _,case in ipairs(cases) do
        C_ChatInfo.InChatMessagingLockdown=case[1];N.Probe();eq(N.probe,nil);eq(#sent,count)
    end
    C_ChatInfo.InChatMessagingLockdown=original
    local restrictionAPI=C_ChatInfo.AreOutgoingAddonChatMessagesRestricted
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=function()return secret end
    N.Probe();eq(N.probe,nil);eq(#sent,count)
    C_ChatInfo.AreOutgoingAddonChatMessagesRestricted=restrictionAPI
end)

test("probe records native refusal or protected result without retry",function()
    probeSetup();sendCode=11;local count=#sent;N.Probe();eq(N.probe.result,"refused_code_11")
    N.Tick(12);eq(#sent,count+1);eq(N.probe.echo,false)
    N.lastProbeRequest=nil;sendCode=secret;N.Probe();eq(N.probe.result,"protected_result");eq(#sent,count+2)
    sendCode=0
end)

test("probe receive guards membership context payload and protected data",function()
    probeSetup();N.Probe();local p=N.probe
    N.ReceiveProbe(secret,p.token,"GUILD","Kaelan-Forever")
    N.ReceiveProbe("SRProbe1",secret,"GUILD","Kaelan-Forever")
    N.ReceiveProbe("SRProbe1",p.token,"WHISPER","Kaelan-Forever")
    N.ReceiveProbe("SRProbe1","SRP1:invalid","GUILD","Kaelan-Forever")
    N.ReceiveProbe("SRProbe1",p.token,"GUILD",secret)
    member=false;N.ReceiveProbe("SRProbe1",p.token,"GUILD","Kaelan-Forever");member=true
    eq(p.echo,false);eq(p.peers,0);eq(p.received,2);eq(p.tokenSeen,true);eq(p.senderState,"membership_unavailable")
    guild=456;N.ReceiveProbe("SRProbe1",p.token,"GUILD","Lyra-Forever");eq(p.echo,false);guild=123
    N.ReceiveProbe("SRProbe1","SRP1:1-2-3","GUILD","Lyra-Forever");eq(p.echo,false)
    for i=1,6 do N.ReceiveProbe("SRProbe1",p.token,"GUILD","Peer"..i.."-Forever") end
    eq(p.peers,4)
end)

test("probe distinguishes matching payload from self identity and counts bounded metadata only",function()
    probeSetup();N.Probe();local p=N.probe
    N.ReceiveProbe("SRProbe1",p.token,"GUILD",secret)
    eq(p.tokenSeen,true);eq(p.echo,false);eq(p.senderState,"protected")
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","|Khidden|k");eq(p.senderState,"invalid")
    member=false;N.ReceiveProbe("SRProbe1",p.token,"GUILD","Unknown-Forever")
    eq(p.senderState,"membership_unavailable");eq(p.peers,0);member=true
    for i=1,110 do N.ReceiveProbe("SRProbe1",p.token,"GUILD","Lyra-Forever") end
    eq(p.received,99);eq(p.echo,true);eq(p.senderState,"self")
    N.Tick(121);local count=p.received
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","Lyra-Forever");eq(p.received,count)
end)

test("regional probe matches own native full name and checks exact peer name without realm suffix",function()
    probeSetup();local modeAPI,nameAPI,memberAPI=RegionalUniqueNamesEnabled,UnitNameUnmodified,C_GuildInfo.MemberExistsByName
    RegionalUniqueNamesEnabled=function()return true end
    UnitNameUnmodified=function()return "Lyra","Aube-Rouge" end
    local queries={}
    C_GuildInfo.MemberExistsByName=function(name)queries[#queries+1]=name;return name=="Kaelan Ombrelune" end
    local before=V.Copy(runtime.root);N.Probe();local p=N.probe
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","Lyra Aube-Rouge")
    eq(p.echo,true);eq(p.senderState,"self");eq(#queries,0)
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","Kaelan Ombrelune")
    eq(p.peers,1);eq(p.senderState,"verified_member");eq(queries[1],"Kaelan Ombrelune")
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","Kaelan Ombrelune");eq(p.peers,1)
    C_GuildInfo.MemberExistsByName=function()return secret end
    eq(C.ProbeSender("Autre Personne"),"membership_unavailable")
    UnitNameUnmodified=function()return "Lyra",secret end
    eq(C.ProbeSender("Lyra Aube-Rouge"),"self_name_unavailable")
    RegionalUniqueNamesEnabled=function()return secret end
    eq(C.ProbeSender("Lyra Aube-Rouge"),"name_mode_unavailable")
    assert(V.Same(before,runtime.root))
    RegionalUniqueNamesEnabled=modeAPI;UnitNameUnmodified=nameAPI;C_GuildInfo.MemberExistsByName=memberAPI
end)

test("probe can listen before sending and keeps received peer evidence when sending",function()
    probeSetup();local count,root=#sent,V.Copy(runtime.root)
    SlashCmdList.SYNDICATROUGESYNC("ecouter")
    eq(#sent,count);eq(N.probe.result,"not_sent")
    local p=N.probe
    N.ReceiveProbe("SRProbe1","SRP1:999-888-777","GUILD","Kaelan-Forever");eq(p.peers,1)
    N.Tick(35);eq(p.finished,nil);eq(#sent,count)
    SlashCmdList.SYNDICATROUGESYNC("sonde")
    eq(N.probe,p);eq(p.peers,1);eq(#sent,count+1)
    N.ReceiveProbe("SRProbe1",p.token,"GUILD","Lyra-Forever");eq(p.echo,true)
    assert(V.Same(root,runtime.root))
    N.Tick(121);eq(p.finished,true)
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
test("saved activation retries after guild identity finishes loading",function()
    local original=C_Club.GetGuildClubId
    C_Club.GetGuildClubId=function()return nil end
    runtime.root.syncEnabled=true;eq(N.Start(),false);eq(N.channel,nil)
    C_Club.GetGuildClubId=original;guild=123;N.Tick(20);assert(N.channel)
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
test("shared fixture mode preserves production state and refuses production data",function()
    local T=ns.SyncTest;local originalTime=GetServerTime
    GetServerTime=function()return 1793900000 end
    guild=123;member=true
    local real=ns.Runtime;local before=V.Copy(real.root)
    assert(T.Enter());assert(N.testMode);eq(N.prefix,"SRGuildTest4");assert(ns.UI.provider.test)
    local c=N.channel;assert(c.context.guildId:sub(-8)==":test-v1")
    assert(T.Load("Kaelan-Forever"));eq(V.Count(c.session.incidents),5);eq(V.Count(c.session.claims),0)
    for _,row in pairs(c.session.incidents)do eq(row.source,"demo");eq(row.id:sub(1,5),"test:")end
    local root=V.Copy(real.root);root.guildTest=nil;local expected=V.Copy(before);expected.guildTest=nil
    assert(V.Same(root,expected))
    eq(T.Load("Kaelan-Forever"),false)
    eq(T.Avenge("mornecroc"),false);assert(T.Avenge("noctis"))
    eq(V.Count(c.session.claims),1);eq(T.Avenge("noctis"),false)
    local row=V.Copy(c.session.incidents["test:v1:noctis:1"]);row.id="observed:new";row.source="observed"
    local changed,reason=ns.Channel.Change(c,"incident",row);eq(changed,false);eq(reason,"test_records_only")
    local ctx=c.context;c.context=V.Copy(ctx);c.context.test=false
    local state,errorCode=ns.Channel.State(c,"blocked");eq(state,nil);eq(errorCode,"demo_not_shareable");c.context=ctx
    assert(T.Leave());eq(N.testMode,false);eq(N.prefix,"SRGuild4");assert(not ns.UI.provider.test)
    root=V.Copy(real.root);root.guildTest=nil;assert(V.Same(root,expected))
    local retained=real.root.guildTest;real.root.guildTest={version=999,keep=true}
    local rejected=V.Copy(real.root);eq(T.Enter(),false);assert(V.Same(rejected,real.root));eq(N.testMode,false)
    real.root.guildTest=retained;GetServerTime=originalTime
end)
issecretvalue=actualSecret
return {passed=passed}
