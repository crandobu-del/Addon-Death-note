import sources from 'lua:source';
import { createEngine } from '../../tools/lua-host.mjs';
import { guildId, viewer, actors, incidents, vengeances, at } from './scenario.js';

const engine = createEngine(sources);
const $ = id => document.getElementById(id);
const rows = value => Object.values(value || {});
const escape = value => String(value ?? '').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
const time = value => new Intl.DateTimeFormat('fr-BE',{timeZone:'Europe/Brussels',day:'2-digit',month:'2-digit',hour:'2-digit',minute:'2-digit'}).format(new Date(value*1000));
const cssActor = actor => ({'Mornecroc':'morne','Sélénombre':'selene','Brisecroc':'brise','Noctis':'noctis','Kaëlan':'kaelan','Lÿra':'lyra','Thörin':'thorin'}[actor?.name]||'noctis');
const portrait = actor => `<span class="portrait ${cssActor(actor)}" role="img" aria-label="Portrait illustratif de ${escape(actor.name)}"></span>`;
const key = 'syndicat-rouge:offline-demo:v1';
let snapshot, view, selected = actors.morne.id, selectedAvenger = actors.kaelan.id, currentTab = 'wanted', filter = 'all';
let preferences = {vengeanceAlert:true};
let storageAllowed = true;

function warn(message) { $('storage-warning').textContent = message; $('storage-warning').hidden = false; }
function announce(message) { $('status').textContent = message; }
function execute(operation, payload, base = snapshot) {
  return engine.call('Core','Execute',base ?? null,guildId,operation,payload ?? null,viewer.id)[0];
}
function save() {
  if (!storageAllowed) return;
  try { localStorage.setItem(key,JSON.stringify({version:1,snapshot,preferences})); }
  catch { storageAllowed = false; warn('Stockage local indisponible : les modifications restent en mémoire pour cette session.'); }
}
function accept(result) {
  if (!result?.view || !result?.snapshot) throw new Error(result?.reason || 'Réponse du moteur indisponible');
  snapshot = result.snapshot; view = result.view;
}
function seed() {
  accept(execute('view',null,null));
  for (const record of incidents) { const result=execute('incident',record); if (!result.ok) throw new Error(result.reason); accept(result); }
  for (const claim of vengeances) { const result=execute('vengeance',claim); if (!result.ok) throw new Error(result.reason); accept(result); }
}
function perform(operation, payload, message) {
  try {
    const result = execute(operation,payload);
    if (!result.ok) { announce(`Action refusée : ${result.reason}. Aucun point supplémentaire attribué.`); return false; }
    accept(result); save(); render(); announce(message); return true;
  } catch (error) { announce(`Action interrompue : ${error.message}`); return false; }
}
function load() {
  let saved;
  try {
    const raw=localStorage.getItem(key);
    if (raw) {
      if (raw.length>5000000) throw new Error('Sauvegarde trop volumineuse');
      saved=JSON.parse(raw);
      if (saved.version!==1 || !saved.snapshot) throw new Error('Format inconnu');
      const restored=execute('view',null,saved.snapshot);
      if (!restored.ok) throw new Error(restored.reason);
      accept(restored);
      if (typeof saved.preferences?.vengeanceAlert==='boolean') preferences.vengeanceAlert=saved.preferences.vengeanceAlert;
    }
  } catch {
    storageAllowed=false;
    warn('Sauvegarde de démonstration illisible ou stockage inaccessible. Scénario temporaire affiché ; les données existantes ne seront pas écrasées. « Réinitialiser » permet de repartir à zéro.');
  }
  if (!view) seed();
}
function renderWanted() {
  const search=$('search').value.trim().toLocaleLowerCase('fr');
  const enemies=rows(view.wanted).filter(row=>`${row.enemy.name} ${row.enemy.realm}`.toLocaleLowerCase('fr').includes(search));
  if (!enemies.some(row=>row.enemy.id===selected)) selected=enemies[0]?.enemy.id;
  $('wanted-list').innerHTML=enemies.length ? enemies.map(row=>`<button type="button" class="target" data-enemy="${escape(row.enemy.id)}" aria-pressed="${row.enemy.id===selected}">${portrait(row.enemy)}<span><span class="target-name">${escape(row.enemy.name)}</span><span class="target-detail">Niv. ${escape(row.enemy.level||'?')} · ${escape(row.enemy.class||'Classe inconnue')}</span><span class="target-detail">${escape(row.lastIncident.location.zone)}</span>${row.openCount===0?'<span class="mini-stamp">VENGÉ</span>':''}</span><span class="target-score">${row.bounty}<small>PRIME</small></span></button>`).join('') : '<p class="empty">Aucun joueur ne correspond à cette recherche.</p>';
  const row=enemies.find(row=>row.enemy.id===selected);
  if (!row) { $('dossier').innerHTML='<p class="empty">Sélectionne un joueur recherché.</p>'; return; }
  const enemy=row.enemy, place=row.lastIncident.location;
  const hasCoordinates=place.mapId!==undefined && place.x!==undefined && place.y!==undefined;
  const map=hasCoordinates ? `<div class="map"><div class="map-art"></div><div class="map-overlay"></div><span class="map-pin" style="left:${place.x*100}%;top:${place.y*100}%" aria-label="Marqueur fictif du dernier meurtre">⌖</span><span class="map-label">${escape(place.zone)} · ${escape(time(row.lastIncident.occurredAt))}</span></div><p class="small">Carte illustrative · Lieu passé du scénario.</p>` : `<div class="map unknown-location"><p>Zone connue<br><strong>${escape(place.zone)}</strong></p></div><p class="small">Coordonnées inconnues : aucun marqueur précis.</p>`;
  $('dossier').innerHTML=`<h2 class="dossier-heading">AVIS DE RECHERCHE</h2><div class="identity">${portrait(enemy)}<div><h3>${escape(enemy.name)}</h3><p>${escape(enemy.race||'Race inconnue')} · ${escape(enemy.class||'Classe inconnue')}</p><p>Niveau ${escape(enemy.level||'?')} · ${escape(enemy.realm)}</p><p>Prime de recherche : <strong>${row.bounty}</strong></p>${row.openCount===0?'<span class="mini-stamp">VENGÉ</span>':''}</div><div class="reward"><span>RÉCOMPENSE</span><strong>+${row.reward} réputation</strong><small>${row.openCount} incident${row.openCount>1?'s':''} à venger</small></div></div><div class="summary">${row.victimCount} victime${row.victimCount>1?'s':''} distincte${row.victimCount>1?'s':''} · Dernier meurtre : ${escape(row.lastIncident.victim.name)} · ${escape(time(row.lastIncident.occurredAt))}</div><div class="dossier-bottom"><section><h3>Dernier meurtre connu</h3>${map}</section><section><h3>Leurs noms restent</h3>${rows(row.incidents).map(i=>`<div class="incident-row"><strong>${escape(i.victim.name)}</strong><span class="small">${escape(time(i.occurredAt))} · ${escape(i.location.zone)}</span>${i.vengeanceId?`<span class="mini-stamp">VENGÉ</span> <span class="small">Par ${escape(snapshot.vengeances[i.vengeanceId].avenger.name)}</span>`:'<span class="pending">À venger</span>'}</div>`).join('')}</section></div><div class="demo-action"><button class="primary" id="simulate" type="button" ${row.openCount===0?'disabled':''}>Simuler une vengeance</button><p>Démonstration : Kaëlan clôture les incidents ouverts et reçoit +${row.reward} réputation. Aucun combat réel.</p></div>`;
  $('simulate').onclick=()=>{
    const open=rows(row.incidents).filter(i=>!i.vengeanceId).map(i=>i.id);
    if (!open.length) return;
    const claim={id:`demo:simulation:${enemy.id}:${open.slice().sort().join('|')}`,guildId,enemyId:enemy.id,avenger:actors.kaelan,incidentIds:open,occurredAt:Math.max(at(20,0),row.lastIncident.occurredAt+60)};
    const concernsViewer=rows(row.incidents).some(i=>!i.vengeanceId&&i.victim.id===viewer.id);
    perform('vengeance',claim,concernsViewer&&preferences.vengeanceAlert?`Tu as été vengée ! Kaëlan gagne ${open.length} réputation. Consulte tes notifications.`:`Vengeance simulée : +${open.length} réputation pour Kaëlan.`);
  };
}
function renderRanking() {
  const ranking=rows(view.ranking);
  if (!ranking.some(row=>row.member.id===selectedAvenger)) selectedAvenger=ranking[0]?.member.id;
  $('ranking').innerHTML=ranking.map((row,index)=>`<tr class="${row.member.id===selectedAvenger?'rank-highlight':''}"><td>${index+1}</td><td><button class="member-button" type="button" data-avenger="${escape(row.member.id)}">${escape(row.member.name)}</button><p class="small">${escape(row.member.realm)}</p></td><td>${row.reputation}</td><td>${row.victimsAvenged}</td></tr>`).join('');
  const row=ranking.find(row=>row.member.id===selectedAvenger);
  $('avenger-detail').innerHTML=row?`${portrait(row.member)}<h3>${escape(row.member.name)}</h3><p>${escape(row.member.class||'Classe inconnue')} · Niveau ${escape(row.member.level||'?')}</p><p class="reputation">${row.reputation} réputation</p><p>${row.victimsAvenged} membre${row.victimsAvenged>1?'s':''} distinct${row.victimsAvenged>1?'s':''} vengé${row.victimsAvenged>1?'s':''}</p><hr><h3>Dernières vengeances</h3>${rows(row.vengeances).map(v=>`<div class="incident-row"><strong>${escape(snapshot.incidents[rows(v.incidentIds)[0]].enemy.name)}</strong><span class="small">${escape(time(v.occurredAt))} · +${v.reward} réputation</span></div>`).join('')}`:'<p class="empty">Aucune vengeance enregistrée.</p>';
}
function renderJournal() {
  const events=rows(view.journal).filter(row=>filter==='all'||row.kind===filter);
  $('journal').innerHTML=events.length?events.map(row=>{
    const incident=row.incident, vengeance=row.vengeance;
    return `<article class="event"><time>${escape(time(row.occurredAt))}</time><div><strong>${incident?`${escape(incident.enemy.name)} a tué ${escape(incident.victim.name)}`:`${escape(vengeance.avenger.name)} a éliminé ${escape(row.enemy.name)}`}</strong><p class="small">${incident?escape(incident.location.zone):`${rows(vengeance.incidentIds).length} incident(s) vengé(s) · +${vengeance.reward} réputation`}</p></div><span>${vengeance||incident.vengeanceId?'<span class="mini-stamp">VENGÉ</span>':'<span class="pending">À VENGER</span>'}</span></article>`;
  }).join(''):'<p class="empty">Aucun événement dans cette catégorie.</p>';
}
function renderNotifications() {
  const notifications=rows(view.notifications);
  $('unread').textContent=notifications.filter(n=>!n.read).length;
  $('notifications').innerHTML=notifications.length?notifications.map(n=>`<article class="paper notice"><h3>Tu as été vengée !</h3><p><strong>${escape(n.avenger.name)}</strong> a éliminé <strong>${escape(n.enemy.name)}</strong>.</p><p>${n.incidentCount} de tes incidents clôturé(s) · ${escape(time(n.occurredAt))}</p><p class="small">+${n.reward} réputation pour ${escape(n.avenger.name)} au total.</p><button type="button" class="primary" data-thank="${escape(n.id)}" ${n.thanked?'disabled':''}>${n.thanked?`${escape(n.avenger.name)} remercié`:`Remercier ${escape(n.avenger.name)}`}</button> ${!n.read?`<button type="button" data-read="${escape(n.id)}">Marquer comme lu</button>`:''}${n.thanked?'<p class="small">Remerciement mémorisé dans cette démo. Aucun message envoyé.</p>':''}</article>`).join(''):'<div class="paper empty">Tu n’as pas encore reçu de notification de vengeance.</div>';
  $('alert-vengeance').checked=preferences.vengeanceAlert;
}
function render() { renderWanted(); renderRanking(); renderJournal(); renderNotifications(); }
function tab(name) {
  currentTab=name;
  for (const button of document.querySelectorAll('[data-tab]')) {
    const active=button.dataset.tab===name; button.setAttribute('aria-selected',active);
    $(button.getAttribute('aria-controls')).hidden=!active;
  }
}
document.querySelector('.tabs').addEventListener('click',event=>{const button=event.target.closest('[data-tab]');if(button) tab(button.dataset.tab);});
document.querySelector('.tabs').addEventListener('keydown',event=>{
  if(!['ArrowLeft','ArrowRight','Home','End'].includes(event.key))return;
  const buttons=[...document.querySelectorAll('[data-tab]')];let index=buttons.indexOf(document.activeElement);if(index<0)return;
  event.preventDefault();index=event.key==='Home'?0:event.key==='End'?buttons.length-1:(index+(event.key==='ArrowRight'?1:-1)+buttons.length)%buttons.length;
  tab(buttons[index].dataset.tab);buttons[index].focus();
});
$('wanted-list').onclick=event=>{const button=event.target.closest('[data-enemy]');if(button){selected=button.dataset.enemy;renderWanted();}};
$('ranking').onclick=event=>{const button=event.target.closest('[data-avenger]');if(button){selectedAvenger=button.dataset.avenger;renderRanking();}};
$('notifications').onclick=event=>{const button=event.target.closest('[data-thank],[data-read]');if(!button)return;if(button.dataset.thank)perform('thank',button.dataset.thank,'Remerciement mémorisé dans la démonstration. Aucun message envoyé.');else perform('read',button.dataset.read,'Notification marquée comme lue.');};
document.querySelector('.filters').onclick=event=>{const button=event.target.closest('[data-filter]');if(!button)return;filter=button.dataset.filter;document.querySelectorAll('[data-filter]').forEach(b=>b.setAttribute('aria-pressed',String(b===button)));renderJournal();};
$('search').oninput=renderWanted;
$('close-window').onclick=()=>{document.querySelector('.book').hidden=true;$('reopen').hidden=false;$('reopen').focus();};
$('reopen').onclick=()=>{document.querySelector('.book').hidden=false;$('reopen').hidden=true;$(document.querySelector('[data-tab][aria-selected=true]').id).focus();};
$('alert-vengeance').onchange=event=>{preferences.vengeanceAlert=event.target.checked;save();announce('Préférence locale enregistrée. La boîte de notifications reste accessible.');};
$('reset').onclick=()=>{storageAllowed=true;preferences={vengeanceAlert:true};$('storage-warning').hidden=true;selected=actors.morne.id;selectedAvenger=actors.kaelan.id;filter='all';$('search').value='';document.querySelectorAll('[data-filter]').forEach(b=>b.setAttribute('aria-pressed',String(b.dataset.filter==='all')));seed();save();render();tab('wanted');announce('Scénario de démonstration réinitialisé.');};
try { load(); render(); tab(currentTab); announce('Démonstration prête. Les mêmes modules Lua calculent les incidents, les vengeances et la réputation.'); }
catch(error) { warn(`Impossible de charger la démonstration : ${error.message}`); document.querySelectorAll('main button').forEach(b=>b.disabled=true); }
