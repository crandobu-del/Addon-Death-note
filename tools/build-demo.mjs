import { build } from 'esbuild';
import { readFile, mkdir, copyFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
const root = new URL('../',import.meta.url);
const output = new URL('../demo/build/',import.meta.url);
await mkdir(new URL('assets/',output),{recursive:true});
await build({entryPoints:{app:fileURLToPath(new URL('demo/src/main.js',root)),sync:fileURLToPath(new URL('demo/src/sync.js',root))},outdir:fileURLToPath(output),bundle:true,platform:'browser',format:'iife',target:'es2020',define:{'process':'undefined','process.env.FENGARICONF':'undefined','process.env.NODE_ENV':'"production"'},plugins:[{
 name:'actual-lua-sources',setup(builder){
  builder.onResolve({filter:/^lua:source$/},()=>({path:'sources',namespace:'lua'}));
  builder.onLoad({filter:/.*/,namespace:'lua'},async()=>{
   const manifest=JSON.parse(await readFile(new URL('lua-manifest.json',import.meta.url),'utf8'));
   const sources=await Promise.all(manifest.map(async name=>({name,source:await readFile(new URL('addon/SyndicatRouge/'+name,root),'utf8')})));
   return {contents:'export default '+JSON.stringify(sources),loader:'js'};
  });
 }
}]});
await Promise.all([
 copyFile(new URL('demo/src/index.html',root),new URL('index.html',output)),
 copyFile(new URL('demo/src/app.css',root),new URL('app.css',output)),
 copyFile(new URL('demo/src/sync.html',root),new URL('sync.html',output)),
 copyFile(new URL('demo/src/sync.css',root),new URL('sync.css',output)),
 copyFile(new URL('docs/plans/death-note/assets/death-note-syndicat-rouge-v3.png',root),new URL('assets/register.png',output)),
 copyFile(new URL('docs/plans/death-note/assets/death-note-vengeurs-v1.png',root),new URL('assets/avengers.png',output)),
 copyFile(new URL('demo/assets/illustrative-map.png',root),new URL('assets/map.png',output))
]);
console.log('Offline preview built at demo/build/index.html');
