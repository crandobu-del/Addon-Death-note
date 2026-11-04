import { readFile, writeFile } from 'node:fs/promises';
import { createEngine } from './lua-host.mjs';
import { actors, guildId, incidents, vengeances, viewer } from '../demo/src/scenario.js';
const manifest=JSON.parse(await readFile(new URL('./lua-manifest.json',import.meta.url),'utf8'));
const sources=await Promise.all(manifest.map(async name=>({name,source:await readFile(new URL('../addon/SyndicatRouge/'+name,import.meta.url),'utf8')})));
const engine=createEngine(sources);
try {
 const roster=[actors.lyra,actors.kaelan,actors.thorin,actors.maelys,actors.faelin];
 const result=engine.call('Guild','Execute',null,guildId,viewer.id,roster,'receive',
  {version:1,guildId,senderId:actors.kaelan.id,incidents,claims:vengeances},actors.kaelan.id)[0];
 if(!result.ok)throw new Error(result.reason);
 const output=engine.call('DiscordOutbox','FromSnapshot',result.snapshot,guildId,viewer.id,roster)[0];
 if(!output)throw new Error('Export unavailable');
 // Empty Lua arrays cross the development bridge as empty objects.
 output.incidents=Object.values(output.incidents);output.claims=Object.values(output.claims);
 await writeFile(new URL('../tests/fixtures/discord-export-demo.json',import.meta.url),JSON.stringify(output,null,2)+'\n');
 console.log('Demo export fixture generated from the actual Lua exporter.');
} finally {engine.close();}
