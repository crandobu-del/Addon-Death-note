import sources from 'lua:source';
import { createEngine } from '../../tools/lua-host.mjs';
import { guildId, actors, at } from './scenario.js';
const engine=createEngine(sources);
const $=id=>document.getElementById(id);
const list=value=>Object.values(value||{});
const e=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const members=[actors.lyra,actors.kaelan,actors.thorin,actors.maelys,actors.faelin];
let registers=[],lastExchange=null;
function status(message){$('sync-status').textContent=message;}
function operation(register,name,payload=null,sender=null){
 const result=engine.call('Guild','Execute',register.snapshot??null,guildId,register.owner.id,members,name,payload,sender)[0];
 if(!result.ok)throw new Error(result.reason||'Erreur du registre');
 register.snapshot=result.snapshot;register.view=result.view;register.message=result.message;
 return result;
}
function make(owner){const register={owner,online:true,snapshot:null,counter:0};operation(register,'view');return register;}
function add(register,id,victim=register.owner){operation(register,'incident',{id,guildId,enemy:actors.morne,victim,occurredAt:at(19,0)+register.counter*60,location:{zone:'Strangleronce · Grom’gol'},source:'demo'});}
function claim(register){
 // Only incidents still open in the derived ledger are eligible.
 const incidents=list(register.view.wanted).flatMap(row=>list(row.incidents)).filter(row=>!row.vengeanceId);
 if(!incidents.length)throw new Error('Aucun incident ouvert à venger');
 register.counter++;
 operation(register,'claim',{id:`demo:sync:claim:${register.owner.id}:${register.counter}`,guildId,enemyId:actors.morne.id,avenger:register.owner,occurredAt:at(20,0)+register.counter*60,incidentIds:incidents.map(row=>row.id)});
}
function initialize(){registers=[make(actors.lyra),make(actors.kaelan)];add(registers[0],'demo:sync:initial');lastExchange=null;$('repeat').disabled=true;}
function synchronize(repeat=false){
 if(registers.some(r=>!r.online)){status('Un membre est hors ligne. Les registres restent séparés ; reconnecte-le pour rattraper les événements.');return;}
 if(!repeat){lastExchange=registers.map(register=>({sender:register.owner.id,message:operation(register,'export').message}));}
 if(!lastExchange)return;
 const outcomes=[];
 // Capture both messages before delivery, as independent clients would do.
 for(let index=0;index<registers.length;index++)outcomes.push(operation(registers[index],'receive',lastExchange[1-index].message,lastExchange[1-index].sender).reason);
 $('repeat').disabled=false;render();
 const conflicts=list(registers[0].view.conflicts).length;
 status(conflicts?`Registres synchronisés : ${conflicts} revendications en attente. La récompense concernée est suspendue, aucun double crédit.`:outcomes.every(x=>x==='unchanged')?'Échange déjà reçu : aucun incident ni point ajouté.':'Registres synchronisés : mêmes incidents, mêmes vengeances et même classement.');
}
function render(){
 $('registers').innerHTML=registers.map((register,index)=>{
  const view=register.view,events=list(view.journal).filter(row=>row.kind==='incident'),conflicts=list(view.conflicts),ranking=list(view.ranking),notices=list(view.notifications);
  const pending=new Set(list(view.pendingIncidentIds));
  const open=list(view.wanted).reduce((sum,row)=>sum+row.openCount,0);
  return `<article class="paper sync-register" data-register="${index}"><header><h2>Registre de ${e(register.owner.name)}</h2><label class="connection"><input type="checkbox" data-online="${index}" ${register.online?'checked':''}>${register.online?'Connecté au partage':'Hors ligne'}</label></header><p class="sync-counts">${view.incidentCount} incident(s) connu(s) · ${open-pending.size} à venger · ${pending.size} en attente · ${view.claimCount} revendication(s)</p><div class="sync-actions"><button type="button" data-add="${index}">Simuler une attaque</button><button class="primary" type="button" data-claim="${index}" ${open===0||conflicts.length?'disabled':''}>Simuler une vengeance</button></div>${conflicts.length?`<section class="sync-conflicts"><h3>${conflicts.length} revendications en attente</h3><ul>${conflicts.map(c=>`<li>${e(c.avenger.name)} · ${list(c.incidentIds).length} incident(s) disputé(s)</li>`).join('')}</ul><p class="small">La guilde devra départager ces revendications.</p></section>`:''}<h3>Incidents connus</h3>${events.length?`<table><thead><tr><th>Ennemi</th><th>Victime</th><th>État</th></tr></thead><tbody>${events.map(row=>`<tr><td>${e(row.incident.enemy.name)}</td><td>${e(row.incident.victim.name)}</td><td>${pending.has(row.incident.id)?'En attente':row.incident.vengeanceId?'<span class="mini-stamp">VENGÉ</span>':'À venger'}</td></tr>`).join('')}</tbody></table>`:'<p class="empty">Aucun incident reçu pour le moment.</p>'}<h3>Classement connu</h3><div class="sync-ranking">${ranking.length?ranking.map(row=>`<div class="rankline"><span>${e(row.member.name)}</span><strong>${row.reputation} réputation</strong></div>`).join(''):'<p class="empty">Aucune vengeance validée.</p>'}</div><h3>Notifications personnelles</h3>${notices.length?notices.map(n=>`<div class="sync-notice">${e(n.avenger.name)} a vengé ${e(n.victim.name)}.<br><button type="button" data-thank="${index}" data-notification="${e(n.id)}" ${n.thanked?'disabled':''}>${n.thanked?'Remerciement mémorisé':`Remercier ${e(n.avenger.name)}`}</button></div>`).join(''):'<p class="empty">Aucune notification de vengeance pour ce membre.</p>'}</article>`;
 }).join('');
}
function guarded(action){try{action();}catch(error){status(`Action refusée : ${error.message}. Le registre concerné reste inchangé.`);}}
$('registers').addEventListener('change',event=>{const index=event.target.dataset.online;if(index===undefined)return;registers[Number(index)].online=event.target.checked;render();status(registers[Number(index)].online?'Membre reconnecté : tu peux synchroniser pour rattraper les événements.':'Membre hors ligne : ses actions restent dans son propre registre.');});
$('registers').addEventListener('click',event=>{
 const button=event.target.closest('[data-add],[data-claim],[data-thank]');if(!button)return;
 guarded(()=>{
  if(button.dataset.add!==undefined){const r=registers[Number(button.dataset.add)];r.counter++;add(r,`demo:sync:incident:${r.owner.id}:${r.counter}`);status(`Nouvel incident connu seulement de ${r.owner.name}. Synchronise pour le partager.`);}
  else if(button.dataset.claim!==undefined){const r=registers[Number(button.dataset.claim)];claim(r);status(`Vengeance locale de ${r.owner.name}. La réputation reste à confronter aux autres registres.`);}
  else{operation(registers[Number(button.dataset.thank)],'thank',button.dataset.notification);status('Remerciement conservé dans le registre personnel. Aucun message envoyé.');}
  render();
 });
});
$('exchange').onclick=()=>guarded(()=>synchronize());
$('repeat').onclick=()=>guarded(()=>synchronize(true));
$('reset-sync').onclick=()=>guarded(()=>{initialize();render();status('Scénario réinitialisé : seule Lÿra connaît le premier incident.');});
$('conflict-scenario').onclick=()=>guarded(()=>{initialize();synchronize();claim(registers[0]);claim(registers[1]);synchronize();});
guarded(()=>{initialize();render();status('Prêt : partage le premier incident avec Kaëlan. Tout se déroule dans ce navigateur.');});
