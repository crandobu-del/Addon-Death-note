import http from 'node:http';
import { readFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import path from 'node:path';
const root=fileURLToPath(new URL('../demo/build/',import.meta.url));
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png'};
export function createDemoServer(port=8765) {
 const server=http.createServer(async(request,response)=>{
  let file;
  try {const url=new URL(request.url,'http://127.0.0.1');const relative=decodeURIComponent(url.pathname);file=path.resolve(root,'.'+(relative==='/'?'/index.html':relative));
   if(!file.startsWith(root)||!['GET','HEAD'].includes(request.method)){response.writeHead(403);response.end();return;}
   const data=await readFile(file);response.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':'no-store'});response.end(request.method==='HEAD'?undefined:data);
  }catch{response.writeHead(404);response.end('Not found');}
 });
 return new Promise((resolve,reject)=>{server.once('error',reject);server.listen(port,'127.0.0.1',()=>resolve(server));});
}
if(process.argv[1]&&path.resolve(process.argv[1])===fileURLToPath(import.meta.url)) {
 await createDemoServer();console.log('Death Note demo: http://127.0.0.1:8765 (Ctrl+C to stop)');
}
