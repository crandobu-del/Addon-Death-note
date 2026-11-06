import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {createEngine} from './lua-host.mjs';
const root=new URL('../',import.meta.url);
const toc=await readFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root),'utf8');
const sources=[{name:'isolated WoW double',source:await readFile(new URL('tests/lua/native_wow_fake.lua',root),'utf8')}];
for(const name of toc.split(/\r?\n/).filter(x=>x&&!x.startsWith('#')))sources.push({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')});
sources.push({name:'two-client harness, tests only',source:`
local _,ns=...
local H={};ns.DeliveryHarness=H
local packets,logs={},{}
local surnames={Lyra="Aube-Rouge",Kaelan="Ombrelune",Enemy="Crocsombre"}
local function actor(name)
    local full=H.regional and name.." "..surnames[name] or name
    local realm=H.regional and "forever-regional" or "Forever"
    return{id=full.."-"..realm,name=full,realm=realm}
end
function H.Boot(owner,saved,regional)
    H.regional=regional==true
    print=function(text)logs[#logs+1]=text end
    issecretvalue=function()return false end
    WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
    C_Club={GetGuildClubId=function()return "123" end,GetClubInfo=function()return{name=ns.Config.guildName}end}
    C_GuildInfo={MemberExistsByName=function(name)
        if H.regional then return name==actor("Lyra").name or name==actor("Kaelan").name end
        return name=="Lyra-Forever" or name=="Kaelan-Forever"
    end}
    RegionalUniqueNamesEnabled=function()return H.regional end
    UnitNameUnmodified=function()return owner,H.regional and surnames[owner] or "Forever" end
    UnitFullName=UnitNameUnmodified
    GetServerTime=function()return 1793900000 end
    C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,AreOutgoingAddonChatMessagesRestricted=function()return H.regional end,InChatMessagingLockdown=function()return false end,
        SendAddonMessage=function(prefix,text,channel)assert(channel=="GUILD");packets[#packets+1]={prefix=prefix,text=text,sender=H.regional and actor(owner).name or owner.."-Forever"};return 0 end}
    SyndicatRougeCharacterDB=saved
    for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end
    assert(ns.GuildNative.Start());ns.Runtime.root.syncEnabled=true
end
function H.Seed()
    local guildId=ns.GuildNative.channel.context.guildId
    assert(ns.GuildNative.Change("incident",{id="i",guildId=guildId,enemy=actor("Enemy"),victim=actor("Lyra"),occurredAt=100,source="observed",location={zone="Elwynn"}}))
    assert(ns.GuildNative.Change("claim",{id="v",guildId=guildId,enemyId=actor("Enemy").id,avenger=actor("Kaelan"),occurredAt=200,incidentIds={"i"}}))
end
function H.Pull()
    for i=1,300 do ns.GuildNative.Tick(.31)end
    -- Wire frames split bytes, including inside UTF-8 sequences. Preserve
    -- those bytes through the JavaScript bridge instead of decoding each frame.
    for _,packet in ipairs(packets)do packet.hex=packet.text:gsub(".",function(c)return string.format("%02x",string.byte(c))end);packet.text=nil end
    local result=packets;packets={};return result
end
function H.Receive(packet)
    local text=packet.hex and packet.hex:gsub("%x%x",function(pair)return string.char(tonumber(pair,16))end) or packet.text
    ns.GuildNative.Receive(packet.prefix,text,"GUILD",packet.sender)
end
function H.Thank()
    ns.UI.Create();ns.UI.window.tab=4;ns.UI.Refresh()
    local panel=ns.UI.window.panels[4];assert(panel.current and panel.current.kind~="thanks")
    assert(panel.thank:IsShown() and not panel.thank.disabled)
    panel.thank.scripts.OnClick();assert(panel.thank.label.text=="En attente")
end
function H.Read()
    ns.UI.Create();ns.UI.window.tab=4;ns.UI.Refresh()
    local panel=ns.UI.window.panels[4];assert(panel.current.kind=="thanks")
    assert(not panel.thank:IsShown() and panel.read:IsShown())
    panel.read.scripts.OnClick();assert(panel.read.disabled)
end
function H.Snapshot()return ns.Validation.Copy(ns.Runtime.root)end
function H.EnterTest()assert(ns.SyncTest.Enter());assert(ns.UI.provider.test and ns.GuildNative.prefix=="SRGuildTest1")end
function H.LeaveTest()assert(ns.SyncTest.Leave());assert(not ns.UI.provider.test and ns.GuildNative.prefix=="SRGuild1")end
function H.LoadTest()assert(ns.SyncTest.Load())end
function H.AvengeTest(target)return ns.SyncTest.Avenge(target)end
function H.MainSnapshot()local root=ns.Validation.Copy(ns.Runtime.root);root.guildTest=nil;return root end
function H.TestInfo()
    local c=ns.GuildNative.channel;local view=ns.UI.provider:View();local rep={}
    for _,row in ipairs(view.ranking)do rep[row.member.name]=row.reputation end
    return {incidents=ns.Validation.Count(c.session.incidents),claims=ns.Validation.Count(c.session.claims),ranking=rep,
        peers=ns.Validation.Count(c.peers),mode=ns.UI.window.mode.text,prefix=ns.GuildNative.prefix}
end
function H.Info()
    local c=ns.GuildNative.channel;local view=ns.UI.provider:View();local unread,thanksAlerts,vengeanceAlerts=0,0,0
    for _,note in ipairs(view.notifications)do if not note.read then unread=unread+1 end end
    for _,line in ipairs(logs)do if line:find("te remercie",1,true)then thanksAlerts=thanksAlerts+1 elseif line:find("t’a vengé",1,true)then vengeanceAlerts=vengeanceAlerts+1 end end
    return {pending=#ns.Delivery.Pending(c.delivery,c.session),inbox=ns.Validation.Count(c.delivery.inbox),unread=unread,
        thanksAlerts=thanksAlerts,vengeanceAlerts=vengeanceAlerts,notifications=#view.notifications,
        status=view.notifications[1] and view.notifications[1].deliveryStatus}
end
`});
const engines=new Set();
function boot(owner,saved,regional){const e=createEngine(sources);engines.add(e);e.call('DeliveryHarness','Boot',owner,saved,regional);return e;}
const call=(e,name,...args)=>e.call('DeliveryHarness',name,...args)[0];
function forward(from,to,discard=false){const packets=call(from,'Pull');if(Array.isArray(packets)&&!discard)for(const p of packets)call(to,'Receive',p);}
function cast(from,...targets){const packets=call(from,'Pull');if(Array.isArray(packets))for(const p of packets)for(const to of targets)call(to,'Receive',p);}
try{
 for(const regional of [false,true]){
 let a=boot('Lyra',undefined,regional),b=boot('Kaelan',undefined,regional);call(b,'Seed');forward(b,a);forward(a,b);forward(b,a);
 assert.equal(call(a,'Info').notifications,1);assert.equal(call(a,'Info').vengeanceAlerts,1);
 call(a,'Thank');assert.equal(call(a,'Info').pending,1);
 const savedA=call(a,'Snapshot');a.close();engines.delete(a);a=boot('Lyra',savedA,regional);
 assert.equal(call(a,'Info').pending,1);assert.equal(call(a,'Info').vengeanceAlerts,0);
 forward(a,b);assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,1);
 forward(b,a,true);assert.equal(call(a,'Info').pending,1);
 const savedB=call(b,'Snapshot');b.close();engines.delete(b);b=boot('Kaelan',savedB,regional);
 assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,0);
 forward(a,b);forward(b,a);assert.equal(call(a,'Info').pending,0);assert.equal(call(a,'Info').status,'delivered');
 assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,0);
 call(b,'Read');const readB=call(b,'Snapshot');b.close();engines.delete(b);b=boot('Kaelan',readB,regional);
 assert.equal(call(b,'Info').unread,0);
 console.log('Delivery lifecycle ('+(regional?'Forever regional names, realm flag true':'realm-qualified names')+'): isolated native clients passed catch-up, UI click, sender reload, dropped ACK, receiver reload, retry, deduplication, confirmed delivery and persistent read. Not a game-client test.');
 }
 let a=boot('Lyra',undefined,true),b=boot('Kaelan',undefined,true),normal=boot('Lyra',undefined,true);
 call(b,'Seed');forward(b,a);forward(a,b);forward(b,a);
 const mainA=call(a,'MainSnapshot'),mainB=call(b,'MainSnapshot'),mainNormal=call(normal,'MainSnapshot');
 call(a,'EnterTest');call(b,'EnterTest');cast(a,b,normal);cast(b,a,normal);cast(a,b,normal);
 call(a,'LoadTest');cast(a,b,normal);cast(b,a,normal);cast(a,b,normal);
 assert.equal(call(a,'TestInfo').incidents,5);assert.equal(call(b,'TestInfo').incidents,5);
 assert.match(call(a,'TestInfo').mode,/TEST PARTAGÉ/);
 assert.equal(call(b,'AvengeTest','mornecroc'),true);cast(b,a,normal);cast(a,b,normal);
 assert.equal(call(a,'TestInfo').ranking['Kaelan Ombrelune'],2);
 assert.equal(call(b,'AvengeTest','mornecroc'),false);
 call(a,'Thank');cast(a,b,normal);cast(b,a,normal);
 assert.equal(call(a,'Info').pending,0);assert.equal(call(b,'Info').inbox,1);
 assert.equal(call(b,'AvengeTest','brisecroc'),true);cast(b,a,normal);cast(a,b,normal);
 assert.equal(call(a,'AvengeTest','noctis'),true);cast(a,b,normal);cast(b,a,normal);
 assert.equal(call(a,'TestInfo').ranking['Kaelan Ombrelune'],3);assert.equal(call(a,'TestInfo').ranking['Lyra Aube-Rouge'],1);
 assert.deepEqual(call(a,'MainSnapshot'),mainA);assert.deepEqual(call(b,'MainSnapshot'),mainB);assert.deepEqual(call(normal,'MainSnapshot'),mainNormal);
 const savedTest=call(a,'Snapshot');a.close();engines.delete(a);a=boot('Lyra',savedTest,true);
 assert.deepEqual(call(a,'MainSnapshot'),mainA);call(a,'EnterTest');cast(a,b,normal);cast(b,a,normal);
 assert.equal(call(a,'TestInfo').incidents,5);assert.equal(call(a,'TestInfo').claims,3);
 call(a,'LeaveTest');call(b,'LeaveTest');
 assert.deepEqual(call(a,'MainSnapshot'),mainA);assert.deepEqual(call(b,'MainSnapshot'),mainB);
 console.log('Shared test dataset: five demo incidents, real UI thanks delivery, simulated revenge, 3/1 test ranking, reload/resume and strict production-profile/third-client isolation passed. Not a game-client test.');
}finally{for(const e of engines)e.close();}
