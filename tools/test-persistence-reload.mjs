import assert from 'node:assert/strict';
import {readFile} from 'node:fs/promises';
import {createEngine} from './lua-host.mjs';
const root=new URL('../',import.meta.url);
const fake=await readFile(new URL('tests/lua/native_wow_fake.lua',root),'utf8');
const toc=await readFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root),'utf8');
const sources=await Promise.all(toc.split(/\r?\n/).filter(l=>l&&!l.startsWith('#')).map(async name=>({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')})));
function lua(v){
  if(v==null)return 'nil';
  if(typeof v==='string')return '"'+v.replaceAll('\\','\\\\').replaceAll('"','\\"').replaceAll('\n','\\n')+'"';
  if(typeof v==='number'||typeof v==='boolean')return String(v);
  return '{'+Object.entries(v).map(([k,value])=>'['+(Array.isArray(v)?Number(k)+1:lua(k))+']='+lua(value)).join(',')+'}';
}
function boot(seed){
 const engine=createEngine([{name:'Client contract with serialized profile',source:fake+'\nSyndicatRougeCharacterDB='+lua(seed)},...sources]);
 engine.test('local ns=...;for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.ADDON_LOADED then f.scripts.OnEvent(f,"ADDON_LOADED","SyndicatRouge")end end;return true');
 return engine;
}
let engine=boot(null),saved;
try {
 saved=engine.test(`local ns=...;local s=ns.Runtime
 assert(ns.Incidents.Add(s.db,{id="test:real",guildId=ns.Persistence.scope,enemy={id="enemy",name="Enemy",realm="Test"},victim={id="victim",name="Victim",realm="Test"},occurredAt=10,location={zone="Test"},source="manual"}))
 ns.UI.Toggle();local f=ns.UI.window;f:SetPoint("TOPLEFT",UIParent,"TOPLEFT",70,-90);f.tabs[3].scripts.OnClick()
 for _,frame in ipairs(SR_TEST_FRAMES)do if frame.events and frame.events.PLAYER_LOGOUT then frame.scripts.OnEvent(frame,"PLAYER_LOGOUT")end end
 return SyndicatRougeCharacterDB`);
 assert.equal(saved.ui.tab,3);assert.equal(saved.ledger.incidents['test:real'].enemy.name,'Enemy');
}finally{engine.close();}
engine=boot(saved);
try {
 const resumed=engine.test('local ns=...;ns.UI.Toggle();return {status=ns.Runtime.status,incidents=ns.Validation.Count(ns.Runtime.db.incidents),tab=ns.UI.window.tab,x=ns.UI.window.point[4],ledger=ns.Store.Snapshot(ns.Runtime.db)}');
 assert.equal(resumed.status,'restored');assert.equal(resumed.incidents,1);assert.equal(resumed.tab,3);assert.equal(resumed.x,70);
 assert.deepEqual(resumed.ledger,saved.ledger);
}finally{engine.close();}
engine=boot({formatVersion:99,sentinel:'keep-original'});
try {
 const preserved=engine.test('local ns=...;ns.UI.Toggle();SlashCmdList.SYNDICATROUGESAVE();for _,f in ipairs(SR_TEST_FRAMES)do if f.events and f.events.PLAYER_LOGOUT then f.scripts.OnEvent(f,"PLAYER_LOGOUT")end end;return {writable=ns.Runtime.writable,saved=SyndicatRougeCharacterDB}');
 assert.equal(preserved.writable,false);assert.deepEqual(preserved.saved,{formatVersion:99,sentinel:'keep-original'});
}finally{engine.close();}
engine=boot(null);
try{assert.equal(engine.test('local ns=...;return ns.Validation.Count(ns.Runtime.db.incidents)'),0);}finally{engine.close();}
console.log('Persistence lifecycle: 4 fresh Lua VM scenarios passed; actual game file writes still require client checks.');
