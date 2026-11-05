import { readFile } from 'node:fs/promises';
import { createEngine } from './lua-host.mjs';
const manifest = JSON.parse(await readFile(new URL('./lua-manifest.json', import.meta.url), 'utf8'));
const sources = await Promise.all(manifest.map(async name => ({ name, source: await readFile(new URL('../addon/SyndicatRouge/'+name, import.meta.url), 'utf8') })));
const engine = createEngine(sources);
try {
  let total = 0;
  for (const file of ['core_spec.lua','sync_spec.lua','outbox_spec.lua','wire_spec.lua','delivery_spec.lua']) {
    const result = engine.test(await readFile(new URL('../tests/lua/'+file, import.meta.url), 'utf8'));
    total += result.passed;
    console.log(`${file}: ${result.passed} tests passed.`);
  }
  console.log(`Lua: ${total} tests passed (actual addon modules, no WoW client).`);
} finally { engine.close(); }
