export const guildId = 'demo:forever:le-syndicat-rouge';
export const actors = {
  lyra: {id:'Forever:Lÿra',name:'Lÿra',realm:'Forever',race:'Elfe de la nuit',class:'Mage',level:60},
  kaelan: {id:'Forever:Kaëlan',name:'Kaëlan',realm:'Forever',race:'Humain',class:'Paladin',level:60},
  thorin: {id:'Forever:Thörin',name:'Thörin',realm:'Forever',race:'Nain',class:'Guerrier',level:60},
  maelys: {id:'Forever:Maëlys',name:'Maëlys',realm:'Forever',race:'Humaine',class:'Voleuse',level:60},
  faelin: {id:'Forever:Faëlin',name:'Faëlin',realm:'Forever',race:'Humain',class:'Prêtre',level:60},
  morne: {id:'Forever:Mornecroc',name:'Mornecroc',realm:'Forever',race:'Orc',class:'Guerrier',level:60},
  selene: {id:'Forever:Sélénombre',name:'Sélénombre',realm:'Forever',race:'Elfe de la nuit',class:'Mage',level:60},
  brise: {id:'Forever:Brisecroc',name:'Brisecroc',realm:'Forever',race:'Nain',class:'Paladin',level:60},
  noctis: {id:'Forever:Noctis',name:'Noctis',realm:'Forever',race:'Humain',class:'Voleur',level:60}
};
export const viewer = actors.lyra;
const day = Date.UTC(2026,10,4,0,0,0)/1000;
export const at = (hour, minute) => day + hour*3600 + minute*60;
const row=(id,enemy,victim,hour,minute,zone)=>({id,guildId,enemy,victim,occurredAt:at(hour,minute),location:{zone},source:'demo'});
export const incidents = [
 row('demo:brise:1',actors.brise,actors.lyra,18,14,'Hautes-terres d’Arathi'),
 row('demo:morne:old',actors.morne,actors.maelys,17,5,'Strangleronce'),
 row('demo:selene:old',actors.selene,actors.thorin,17,30,'Bois de la Pénombre'),
 row('demo:noctis:1',actors.noctis,actors.faelin,18,32,'Les Paluns'),
 row('demo:morne:thorin',actors.morne,actors.thorin,18,48,'Strangleronce'),
 row('demo:selene:2',actors.selene,actors.thorin,18,51,'Bois de la Pénombre'),
 {...row('demo:morne:lyra',actors.morne,actors.lyra,19,6,'Strangleronce · Grom’gol'),location:{zone:'Strangleronce · Grom’gol',mapId:1434,x:0.32,y:0.29}},
 row('demo:morne:faelin',actors.morne,actors.faelin,18,58,'Strangleronce')
];
export const vengeances = [
 {id:'demo:v:old-morne',guildId,enemyId:actors.morne.id,avenger:actors.lyra,occurredAt:at(17,20),incidentIds:['demo:morne:old']},
 {id:'demo:v:old-selene',guildId,enemyId:actors.selene.id,avenger:actors.thorin,occurredAt:at(17,50),incidentIds:['demo:selene:old']},
 {id:'demo:v:brise',guildId,enemyId:actors.brise.id,avenger:actors.kaelan,occurredAt:at(18,42),incidentIds:['demo:brise:1']}
];
