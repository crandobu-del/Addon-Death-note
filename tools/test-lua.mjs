import { readFile } from 'node:fs/promises';
import { createEngine } from './lua-host.mjs';
const manifest = JSON.parse(await readFile(new URL('./lua-manifest.json', import.meta.url), 'utf8'));
const sources = await Promise.all(manifest.map(async name => ({ name, source: await readFile(new URL('../addon/SyndicatRouge/'+name, import.meta.url), 'utf8') })));
const engine = createEngine(sources);
try {
  const result = engine.test(await readFile(new URL('../tests/lua/core_spec.lua', import.meta.url), 'utf8'));
  console.log(`Lua: ${result.passed} tests passed (actual addon modules, no WoW client).`);
} finally { engine.close(); }
