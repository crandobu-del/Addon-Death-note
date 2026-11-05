import {readFile} from 'node:fs/promises';
import {createEngine} from './lua-host.mjs';
const root = new URL('../', import.meta.url);
const toc = await readFile(new URL('addon/SyndicatRouge/SyndicatRouge.toc',root),'utf8');
const files = toc.split(/\r?\n/).filter(l=>l && !l.startsWith('#'));
const sources = [{name:'WoW contract double',source:await readFile(new URL('tests/lua/native_wow_fake.lua',root),'utf8')}];
for (const name of files) sources.push({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')});
sources.push({name:'Separate demo companion',source:await readFile(new URL('dev/SyndicatRougeDemo/Demo.lua',root),'utf8')});
const engine = createEngine(sources);
try { const result = engine.test(await readFile(new URL('tests/lua/native_spec.lua',root),'utf8')); console.log(`Native UI: ${result.passed} contract/behavior tests passed (not visual or in-game validation).`); }
finally { engine.close(); }
