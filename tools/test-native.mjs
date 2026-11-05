import {readFile} from 'node:fs/promises';
import {createEngine} from './lua-host.mjs';
const root = new URL('../', import.meta.url);
const toc = await readFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root),'utf8');
const files = toc.split(/\r?\n/).filter(l=>l && !l.startsWith('#'));
const sources = [{name:'WoW contract double',source:await readFile(new URL('tests/lua/native_wow_fake.lua',root),'utf8')}];
for (const name of files) sources.push({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')});
for (const name of ['MapLocations.lua','MapCatalog.lua','MapAudit.lua','PvpProbe.lua','ChatDeathProbe.lua','KillProofProbe.lua','Demo.lua']) sources.push({name:'Separate demo companion '+name,source:await readFile(new URL('dev/SyndicatRougeDemo/'+name,root),'utf8')});
const engine = createEngine(sources);
try { for(const name of ['native_spec.lua','map_spec.lua','portrait_spec.lua','map_audit_spec.lua','pvp_probe_spec.lua','chat_death_spec.lua','kill_proof_spec.lua','persistence_spec.lua']) {const result = engine.test(await readFile(new URL('tests/lua/'+name,root),'utf8')); console.log(`${name}: ${result.passed} contract/behavior tests passed (not visual or in-game validation).`);} }
finally { engine.close(); }
const guildEngine=createEngine(sources);
try { const result=guildEngine.test(await readFile(new URL('tests/lua/guild_native_spec.lua',root),'utf8'));console.log(`guild_native_spec.lua: ${result.passed} API/security tests passed (not in-game validation).`); }
finally { guildEngine.close(); }
await import('./test-persistence-reload.mjs');
await import('./test-delivery-lifecycle.mjs');
