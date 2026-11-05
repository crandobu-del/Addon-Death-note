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
local function actor(name)return{id=name.."-Forever",name=name,realm="Forever"}end
function H.Boot(owner,saved)
    print=function(text)logs[#logs+1]=text end
    issecretvalue=function()return false end
    WOW_PROJECT_CAMELOT=18;WOW_PROJECT_ID=18
    C_Club={GetGuildClubId=function()return "123" end,GetClubInfo=function()return{name=ns.Config.guildName}end}
    C_GuildInfo={MemberExistsByName=function(name)return name=="Lyra-Forever" or name=="Kaelan-Forever" end}
    UnitFullName=function()return owner,"Forever" end
    C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,AreOutgoingAddonChatMessagesRestricted=function()return false end,
        SendAddonMessage=function(prefix,text,channel)assert(channel=="GUILD");packets[#packets+1]={prefix=prefix,text=text,sender=owner.."-Forever"};return 0 end}
    SyndicatRougeCharacterDB=saved
    for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end
    assert(ns.GuildNative.Start());ns.Runtime.root.syncEnabled=true
end
function H.Seed()
    assert(ns.GuildNative.Change("incident",{id="i",guildId="guild:123",enemy=actor("Enemy"),victim=actor("Lyra"),occurredAt=100,source="observed",location={zone="Elwynn"}}))
    assert(ns.GuildNative.Change("claim",{id="v",guildId="guild:123",enemyId="Enemy-Forever",avenger=actor("Kaelan"),occurredAt=200,incidentIds={"i"}}))
end
function H.Pull()
    for i=1,300 do ns.GuildNative.Tick(.31)end
    local result=packets;packets={};return result
end
function H.Receive(packet)ns.GuildNative.Receive(packet.prefix,packet.text,"GUILD",packet.sender)end
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
function boot(owner,saved){const e=createEngine(sources);engines.add(e);e.call('DeliveryHarness','Boot',owner,saved);return e;}
const call=(e,name,...args)=>e.call('DeliveryHarness',name,...args)[0];
function forward(from,to,discard=false){const packets=call(from,'Pull');if(Array.isArray(packets)&&!discard)for(const p of packets)call(to,'Receive',p);}
try{
 let a=boot('Lyra'),b=boot('Kaelan');call(b,'Seed');forward(b,a);forward(a,b);forward(b,a);
 assert.equal(call(a,'Info').notifications,1);assert.equal(call(a,'Info').vengeanceAlerts,1);
 call(a,'Thank');assert.equal(call(a,'Info').pending,1);
 const savedA=call(a,'Snapshot');a.close();engines.delete(a);a=boot('Lyra',savedA);
 assert.equal(call(a,'Info').pending,1);assert.equal(call(a,'Info').vengeanceAlerts,0);
 forward(a,b);assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,1);
 forward(b,a,true);assert.equal(call(a,'Info').pending,1);
 const savedB=call(b,'Snapshot');b.close();engines.delete(b);b=boot('Kaelan',savedB);
 assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,0);
 forward(a,b);forward(b,a);assert.equal(call(a,'Info').pending,0);assert.equal(call(a,'Info').status,'delivered');
 assert.equal(call(b,'Info').inbox,1);assert.equal(call(b,'Info').thanksAlerts,0);
 call(b,'Read');const readB=call(b,'Snapshot');b.close();engines.delete(b);b=boot('Kaelan',readB);
 assert.equal(call(b,'Info').unread,0);
 console.log('Delivery lifecycle: isolated native clients passed catch-up, UI click, sender reload, dropped ACK, receiver reload, retry, deduplication, confirmed delivery and persistent read. Not a game-client test.');
}finally{for(const e of engines)e.close();}
