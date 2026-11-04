import http from 'node:http';
import fs from 'node:fs/promises';
import path from 'node:path';
import {spawn,execFile} from 'node:child_process';
import {promisify} from 'node:util';
const executar=promisify(execFile);
const project=process.cwd(), port=8767, debugPort=8768;
let socket, sequence=0; const pending=new Map(); let ready=false;
function call(method,params={}) {return new Promise((resolve,reject)=>{const id=++sequence;const timer=setTimeout(()=>{pending.delete(id);reject(Error('Timeout CDP: '+method));},45000);pending.set(id,{resolve:v=>{clearTimeout(timer);resolve(v)},reject:e=>{clearTimeout(timer);reject(e)}});socket.send(JSON.stringify({id,method,params}));});}
const html=`<!doctype html><script type="module">
import {FaceLandmarker,FilesetResolver} from '/vision_bundle.mjs';
try {
 const fileset=await FilesetResolver.forVisionTasks('/wasm');
 const face=await FaceLandmarker.createFromOptions(fileset,{baseOptions:{modelAssetPath:'/face_landmarker.task',delegate:'CPU'},runningMode:'IMAGE',numFaces:1,outputFaceBlendshapes:true,outputFacialTransformationMatrixes:true});
 window.analisar=async({width,height,data})=>{const raw=atob(data);const bytes=new Uint8ClampedArray(raw.length);for(let i=0;i<raw.length;i++)bytes[i]=raw.charCodeAt(i);const image=new ImageData(bytes,width,height);const result=face.detect(image);return {width,height,landmarks:(result.faceLandmarks[0]||[]).map(p=>[p.x*width,p.y*height,p.z*width]),matrix:result.facialTransformationMatrixes?.[0]?Array.from(result.facialTransformationMatrixes[0].data):null,blendshapes:result.faceBlendshapes?.[0]?.categories||[]};};
 window.mpReady=true;
} catch(error) {window.mpError=String(error);}
</script>`;
const mime=file=>file.endsWith('.png')?'image/png':file.endsWith('.bmp')?'image/bmp':file.endsWith('.wasm')?'application/wasm':file.endsWith('.mjs')||file.endsWith('.js')?'text/javascript':file.endsWith('.jpg')?'image/jpeg':'application/octet-stream';
const server=http.createServer(async(req,res)=>{try {
 const url=new URL(req.url,'http://127.0.0.1');
 if(url.pathname==='/') {res.setHeader('Content-Type','text/html');return res.end(html);}
 if(url.pathname==='/status') {res.setHeader('Content-Type','application/json');return res.end(JSON.stringify({ready}));}
 if(url.pathname==='/landmarks'||url.pathname==='/analisar') {
  if(!ready) {res.writeHead(503);return res.end('MediaPipe inicializando');}
  const file=path.resolve(url.searchParams.get('file')||'');if(!file.startsWith(project+path.sep))throw Error('Arquivo fora do projeto');
  const {stdout}=await executar(path.join(project,'work/venv-modelo/bin/python'),[path.join(project,'arte/bola_pixels.py'),file],{maxBuffer:32*1024*1024});
  const result=await call('Runtime.evaluate',{expression:`window.analisar(${stdout.trim()})`,awaitPromise:true,returnByValue:true});
  if(result.exceptionDetails)throw Error(JSON.stringify(result.exceptionDetails));
  const data=result.result.value;
  res.setHeader('Content-Type','application/json');return res.end(JSON.stringify(url.pathname==='/landmarks'?data.landmarks.map(p=>p.slice(0,2)):data));
 }
 let file;
 if(url.pathname==='/image') {file=path.resolve(url.searchParams.get('file')||'');if(!file.startsWith(project+path.sep))throw Error('Arquivo fora do projeto');}
 else if(url.pathname==='/face_landmarker.task')file=path.join(project,'work/ferramentas/face_landmarker.task');
 else if(url.pathname==='/vision_bundle.mjs'||url.pathname.startsWith('/wasm/'))file=path.join(project,'work/ferramentas/mediapipe-web',url.pathname);
 else {res.writeHead(404);return res.end();}
 res.setHeader('Content-Type',mime(file));res.end(await fs.readFile(file));
} catch(error) {res.writeHead(500);res.end(String(error));}});
await new Promise(resolve=>server.listen(port,'127.0.0.1',resolve));
const chrome=spawn('/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',[`--remote-debugging-port=${debugPort}`,`--user-data-dir=${project}/work/bola-chrome`,'--headless=new','--disable-background-timer-throttling','--disable-renderer-backgrounding','--no-first-run','--disable-background-networking','--disable-features=OptimizationGuideOnDeviceModel,OptimizationHints,MediaRouter',`http://127.0.0.1:${port}/`],{stdio:['ignore','ignore','inherit']});
process.on('SIGTERM',()=>{chrome.kill();server.close();process.exit();});
let tabs;
for(let i=0;i<100;i++){try{tabs=await(await fetch(`http://127.0.0.1:${debugPort}/json/list`)).json();if(tabs.some(t=>t.type==='page'))break;}catch{}await new Promise(r=>setTimeout(r,200));}
const tab=tabs.find(t=>t.type==='page');socket=new WebSocket(tab.webSocketDebuggerUrl);
await new Promise(resolve=>socket.addEventListener('open',resolve,{once:true}));
socket.addEventListener('message',event=>{const result=JSON.parse(event.data);if(!pending.has(result.id))return;const callback=pending.get(result.id);pending.delete(result.id);result.error?callback.reject(Error(JSON.stringify(result.error))):callback.resolve(result.result);});
for(let i=0;i<180;i++){const result=await call('Runtime.evaluate',{expression:'({ready:!!window.mpReady,error:window.mpError})',returnByValue:true});if(result.result.value.error)throw Error(result.result.value.error);if(result.result.value.ready){ready=true;console.log('MEDIAPIPE LOCAL PRONTO');break;}await new Promise(r=>setTimeout(r,500));}
if(!ready)throw Error('MediaPipe não inicializou');
