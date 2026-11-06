import {readFile} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {createEngine} from './lua-host.mjs';
const root=new URL('../',import.meta.url);
const toc=await readFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root),'utf8');
const sources=[{name:'isolated game double',source:await readFile(new URL('tests/lua/native_wow_fake.lua',root),'utf8')}];
for(const name of toc.split(/\r?\n/).filter(l=>l&&!l.startsWith('#')))sources.push({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')});
sources.push({name:'report lifecycle harness, tests only',source:`
local _,ns=...
local H={};ns.ReportHarness=H
local packets={};local own;local now=1793960000
local function actor(name)return{id=name.."-Forever",name=name,realm="Forever",guid="Player-1-"..name}end
function H.Boot(name,saved)
 own=name;print=function()end
 GetServerTime=function()return now end;UnitFullName=function()return name,"Forever"end
 RegionalUniqueNamesEnabled=function()return false end
 C_ChatInfo={RegisterAddonMessagePrefix=function()return 0 end,AreOutgoingAddonChatMessagesRestricted=function()return false end,InChatMessagingLockdown=function()return false end,
 SendAddonMessage=function(prefix,packet,route)
  assert(route=="GUILD");packets[#packets+1]={prefix=prefix,hex=packet:gsub(".",function(c)return string.format("%02x",c:byte())end),sender=own.."-Forever"};return 0
 end}
 SyndicatRougeCharacterDB=saved
 for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end
 assert(ns.GuildNative.Start());ns.Runtime.root.syncEnabled=true
end
function H.Seed(count)
 for i=1,count do
  local r={version=1,id=ns.ReportStore.NextId(actor(own),now),at=now,guildId="guild:1",victim=actor(own),killer=actor("Enemy"),attackers={actor("Enemy")},
   location={},source="death_recap",confidence="confirmed",finish="player",instanceType="none",pvp=true,revision=1}
  assert(ns.ReportStore.Put(r,"author",now,true));assert(ns.ReportStore.Put(r,"author",now,false))
 end
end
function H.Step(dt)ns.ReportSync.Tick(dt);ns.GuildNative.Tick(dt);local out=packets;packets={};return out end
function H.Receive(packet)
 local text=packet.hex:gsub("%x%x",function(pair)return string.char(tonumber(pair,16))end)
 ns.GuildNative.Receive(packet.prefix,text,"GUILD",packet.sender)
end
function H.Info()
 local trust={};for _,e in ipairs(ns.ReportStore.List(false))do trust[e.trust]=(trust[e.trust]or 0)+1 end
 return{count=#ns.ReportStore.List(false),personal=#ns.ReportStore.List(true),trust=trust,sources=ns.ReportSync.request and ns.ReportSync.request.sources or 0,
  sessions=ns.Validation.Count(ns.ReportSync.sessions),queue=#ns.ReportSync.queue,nativeQueue=#ns.GuildNative.queue,status=ns.ReportSync.status,error=ns.GuildNative.lastError,
  incidents=ns.Validation.Count(ns.GuildNative.channel.session.incidents),cursors=ns.Validation.Copy(ns.ReportStore.data.cursors)}
end
function H.Save()return ns.Validation.Copy(ns.Runtime.root)end
function H.Request()return ns.ReportSync.Request()end
function H.Pause()ns.ReportStore.Settings().sharing=false end
function H.Resume()ns.ReportStore.Settings().sharing=true;ns.ReportSync.Start(ns.GuildNative.channel.context)end
`});
const engines=[];
function boot(name,saved){const e=createEngine(sources);engines.push(e);e.call('ReportHarness','Boot',name,saved);return e;}
const call=(e,method,...args)=>e.call('ReportHarness',method,...args)[0];
function run(clients,seconds){for(let t=0;t<seconds;t+=.31){const batches=clients.map(e=>call(e,'Step',.31));for(let i=0;i<clients.length;i++)for(const p of Object.values(batches[i]))for(let j=0;j<clients.length;j++)if(i!==j)call(clients[j],'Receive',p);}}
try{
 const author=boot('Alice');call(author,'Seed',6);
 const relay=boot('Bob');run([author,relay],220);
 assert.equal(call(relay,'Info').count,6,JSON.stringify(call(relay,'Info')));
 assert.equal(call(relay,'Info').trust.author,6);
 const missed=boot('Carol');run([relay,missed],200);
 assert.equal(call(missed,'Info').count,6,JSON.stringify(call(missed,'Info')));
 assert.equal(call(missed,'Info').trust.relay,6);assert.equal(call(missed,'Info').incidents,0);
 // The original victim comes back. A fresh bounded catch-up includes explicit author confirmation.
 call(missed,'Request');run([author,relay,missed],240);
 assert.equal(call(missed,'Info').trust.author,6,JSON.stringify(call(missed,'Info')));
 assert.equal(call(missed,'Info').incidents,6);
 const saved=call(missed,'Save');const reloaded=boot('Carol',saved);
 assert.equal(call(reloaded,'Info').count,6);assert.equal(call(reloaded,'Info').personal,0);
 console.log('Report lifecycle: native GUILD wire, delayed discovery, six missed reports, one-hop relay quarantine, victim confirmation, no duplicate bounties, separate personal history and fresh-VM reload passed. Not in-game validation.');
 const d=boot('Daria');call(d,'Seed',40);const e=boot('Evan');call(e,'Seed',1);const f=boot('Faye');call(f,'Seed',1);const g=boot('Gina');
 run([d,e,f,g],170);
 assert.ok(call(g,'Info').sources<=2);assert.ok(call(g,'Info').sessions<=2);
 const partial=call(g,'Info');assert.ok(partial.count>0,JSON.stringify(partial));
 const interrupted=call(g,'Save');call(g,'Pause');run([d,e,f,g],10);assert.equal(call(g,'Info').queue,0);
 const resumed=boot('Gina',interrupted);call(resumed,'Resume');run([d,resumed],450);
 assert.ok(call(resumed,'Info').count>=40,JSON.stringify(call(resumed,'Info')));
 console.log('Report lifecycle: four clients, at most two sources, finite page budgets, persisted continuation cursor, interruption and reconnect progressively recover >32 reports. Not in-game validation.');
}finally{for(const e of engines)e.close();}

