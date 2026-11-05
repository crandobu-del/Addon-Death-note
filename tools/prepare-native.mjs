import {readFile, writeFile, mkdir, copyFile} from 'node:fs/promises';
import {guildId, viewer, incidents, vengeances} from '../demo/src/scenario.js';
const root = new URL('../', import.meta.url);
const manifest = JSON.parse(await readFile(new URL('tools/lua-manifest.json',root), 'utf8'));
const ui = ['UI/Model.lua','UI/Widgets.lua','UI/Portrait.lua','UI/Map.lua','UI/Window.lua','UI/Views.lua','Bootstrap.lua'];
await writeFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root), [
  '## Interface: 16001','## Title: Tableau des primes — Le Syndicat Rouge',
  '## Notes: Registre de guilde — Forever — développement, client réel non validé',
  '## Author: Le Syndicat Rouge','## Version: 0.5.0-dev','## SavedVariablesPerCharacter: SyndicatRougeCharacterDB', '', ...manifest, ...ui, ''
].join('\n'));
function lua(value) {
  if (typeof value==='string') return '"'+value.replaceAll('\\','\\\\').replaceAll('"','\\"').replaceAll('\n','\\n')+'"';
  if (typeof value==='number') return String(value);
  if (Array.isArray(value)) return '{'+value.map(lua).join(',')+'}';
  return '{'+Object.entries(value).map(([k,v])=>'['+lua(k)+']='+lua(v)).join(',')+'}';
}
await mkdir(new URL('dev/SyndicatRougeDemo/',root), {recursive:true});
await writeFile(new URL('dev/SyndicatRougeDemo/SyndicatRougeDemo.toc',root),
  '## Interface: 16001\n## Title: Tableau des primes — Démonstration\n## Dependencies: SyndicatRouge\n## Version: 0.5.0-dev\n## SavedVariables: SyndicatRougeMapAudit, SyndicatRougePvpProbe\nMapLocations.lua\nMapCatalog.lua\nMapAudit.lua\nPvpProbe.lua\nChatDeathProbe.lua\nKillProofProbe.lua\nDemo.lua\n');
await writeFile(new URL('dev/SyndicatRougeDemo/Demo.lua',root),
  '-- Generated from demo/src/scenario.js; DEVELOPMENT ONLY. No persistence.\n'+
  'local _, demo = ...\nlocal function show() SyndicatRouge.ShowDemo(demo.MapLocations('+lua(incidents)+'),'+[vengeances,guildId,viewer.id].map(lua).join(',')+') end\n'+
  'SLASH_SYNDICATROUGEDEMO1="/srdemo"\nSlashCmdList.SYNDICATROUGEDEMO=show\n'+
  '-- Open explicitly with /srdemo; never replace the real ledger on login.\n');
console.log('Native TOC and separate demo companion generated.');
