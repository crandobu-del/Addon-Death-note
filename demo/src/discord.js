import examples from '../assets/discord-preview.json';
import exampleExport from '../../tests/fixtures/discord-export-demo.json';
const $=id=>document.getElementById(id);
const e=value=>String(value??'').replace(/[&<>"']/g,c=>({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[c]));
let expanded=false;
function render(){
 const selected=new Set([...document.querySelectorAll('[data-category]:checked')].map(box=>box.dataset.category));
 const available=examples.messages.filter(row=>selected.has(row.category));
 const messages=expanded?available:[...selected].map(category=>available.find(row=>row.category===category)).filter(Boolean);
 $('message-count').textContent=`${messages.length} exemple${messages.length>1?'s':''} · Aucune connexion Discord`;
 $('no-messages').hidden=messages.length>0;
 $('toggle-examples').hidden=available.length<=selected.size;
 $('toggle-examples').textContent=expanded?'Réduire les exemples':'Voir les autres exemples';
 $('toggle-examples').setAttribute('aria-pressed',String(expanded));
 $('discord-messages').innerHTML=messages.map(row=>{
  const lines=row.payload.content.split('\n');const heading=lines.shift().replace(/^\*\*|\*\*$/g,'');
  return `<article class="discord-message" data-message-category="${e(row.category)}"><span class="sender-avatar" aria-hidden="true">SR</span><div><span class="sender-name">${e(row.payload.username)}</span> <span class="sender-badge">EXEMPLE</span><div class="message-body"><h3>${e(heading)}</h3><p>${e(lines.join('\n'))}</p></div>${row.example?`<p class="message-example">${e(row.example)}</p>`:''}</div></article>`;
 }).join('');
}
document.querySelectorAll('[data-category]').forEach(box=>box.addEventListener('change',render));
$('toggle-examples').onclick=()=>{expanded=!expanded;render();};
$('download-export').onclick=()=>{
 const blob=new Blob([JSON.stringify(exampleExport,null,2)+'\n'],{type:'application/json'});
 const url=URL.createObjectURL(blob);const link=document.createElement('a');link.href=url;link.download='syndicat-rouge-export-fictif.json';link.click();
 setTimeout(()=>URL.revokeObjectURL(url),1000);$('download-status').textContent='Export fictif préparé. Aucun message Discord envoyé.';
};
render();
