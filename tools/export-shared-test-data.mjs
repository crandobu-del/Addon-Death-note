import {readFile,writeFile,mkdir} from 'node:fs/promises';
import assert from 'node:assert/strict';
import {createEngine} from './lua-host.mjs';
const root=new URL('../',import.meta.url);
const manifest=JSON.parse(await readFile(new URL('tools/lua-manifest.json',root),'utf8'));
const sources=[{name:'fixture export public-value stub',source:'issecretvalue=function()return false end'}];
for(const name of manifest)sources.push({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')});
const actor=name=>({id:name+'-forever-regional',name,realm:'forever-regional'});
const a=actor('Victime Exemple'),b=actor('Vengeur Exemple');
const guildId='test:forever:dataset-v1',time=Date.UTC(2026,10,5,19,0,0)/1000;
const engine=createEngine(sources);
try{
 const incidents=engine.call('SyncTest','Build',guildId,a,b,time)[0];
 assert.equal(incidents.length,5);assert.ok(incidents.every(x=>x.source==='demo'&&x.id.startsWith('test:')));
 const claim=(target,avenger)=>({id:'test:v1:vengeance:'+target,guildId,enemyId:incidents.find(x=>x.id.includes(target==='mornecroc'?'morne':target==='brisecroc'?'brise':'noctis')).enemy.id,
  avenger,occurredAt:time,incidentIds:incidents.filter(x=>x.id.includes(target==='mornecroc'?'morne':target==='brisecroc'?'brise':'noctis')).map(x=>x.id)});
 const vengeances=[claim('mornecroc',b),claim('brisecroc',b),claim('noctis',a)];
 const out={formatVersion:1,testOnly:true,importableInProduction:false,
  instructions:'Référence fictive du scénario /srtest. Dans le jeu, les rôles A/B sont remplacés par les identités publiques des deux testeurs. Ce JSON ne s’importe pas avec /sr.',
  roles:{A:a,B:b},guildId,incidents,vengeances,
  expected:{initial:{incidents:5,wanted:4,openIncidents:5,rewards:{'TEST Mornecroc':2,'TEST Sélénombre':1,'TEST Brisecroc':1,'TEST Noctis':1}},
   afterThreeSimulations:{closedIncidents:4,openIncidents:1,ranking:{B:3,A:1},vengeanceNotifications:{A:2,B:1}},
   thanks:'A remercie B dans Notifications après la vengeance de Mornecroc ; B reçoit le merci ; la confirmation ferme la demande, sans point supplémentaire.'}};
 await mkdir(new URL('test-data/',root),{recursive:true});
 const file=new URL('test-data/primes-partage-v1.json',root);
 await writeFile(file,JSON.stringify(out,null,2)+'\n');
 console.log('Jeu de test exporté : '+file.pathname);
}finally{engine.close();}
