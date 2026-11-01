// MediaPipe WASM local: alternativa aos binários Python incompatíveis com macOS 11.
// node scripts/face-landmarks-web.mjs — encerrar com Ctrl+C ao terminar.
import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const port = Number(process.env.FACE_WEB_PORT || 8767);
const debugPort = port + 1;
const chromePath = process.env.CHROME_PATH || '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome';
let cdp;
let chrome;
let nextId = 0;
const pending = new Map();
const page = `<!doctype html><meta charset="utf-8"><title>MediaPipe local</title>
<script type="module">
import {FaceLandmarker, FilesetResolver} from '/work/ferramentas/mediapipe-web/vision_bundle.mjs';
window.detectorReady = (async () => {
 const files = await FilesetResolver.forVisionTasks('/work/ferramentas/mediapipe-web/wasm');
 const detector = await FaceLandmarker.createFromOptions(files, {
  baseOptions: {modelAssetPath:'/work/ferramentas/face_landmarker.task', delegate:'CPU'},
  runningMode:'IMAGE', numFaces:1
 });
 window.detectFace = async url => {
  const image = new Image(); image.src = url;
  await image.decode();
  const result = detector.detect(image);
  if (!result.faceLandmarks.length) throw Error('Rosto não encontrado: '+url);
  return result.faceLandmarks[0].map(p => [p.x*image.naturalWidth,p.y*image.naturalHeight]);
 };
 return true;
})().catch(e => {window.detectorError = String(e); throw e;});
</script>`;

function command(method, params = {}) {
 const id = ++nextId;
 return new Promise((resolve, reject) => {
  const timer = setTimeout(() => {pending.delete(id); reject(Error(`CDP timeout: ${method}`));}, 90000);
  pending.set(id, {resolve, reject, timer});
  cdp.send(JSON.stringify({id, method, params}));
 });
}
async function evaluate(expression) {
 const r = await command('Runtime.evaluate', {expression, awaitPromise:true, returnByValue:true});
 if (r.exceptionDetails) throw Error(r.exceptionDetails.exception?.description || r.exceptionDetails.text);
 return r.result.value;
}
const server = http.createServer(async (req, res) => {
 try {
  res.setHeader('Cache-Control', 'no-store');
  const url = new URL(req.url, `http://127.0.0.1:${port}`);
  if (url.pathname === '/landmarks') {
   if (!cdp) {res.writeHead(503); return res.end('Inicializando Chrome');}
   const file = path.resolve(url.searchParams.get('file') || '');
   if (!file.startsWith(root + path.sep)) throw Error('Arquivo fora do projeto');
   const relative = '/' + path.relative(root, file).split(path.sep).map(encodeURIComponent).join('/') + '?v=' + Date.now();
   const pts = await evaluate(`window.detectFace(${JSON.stringify(relative)})`);
   res.setHeader('Content-Type', 'application/json');
   return res.end(JSON.stringify(pts));
  }
  if (url.pathname === '/') {res.setHeader('Content-Type', 'text/html'); return res.end(page);}
  const file = path.resolve(root, '.' + decodeURIComponent(url.pathname));
  if (!file.startsWith(root + path.sep)) throw Error('Caminho inválido');
  res.setHeader('Content-Type', ({'.mjs':'text/javascript','.js':'text/javascript',
   '.wasm':'application/wasm','.jpg':'image/jpeg','.png':'image/png'})[path.extname(file)] || 'application/octet-stream');
  const stream = fs.createReadStream(file);
  stream.on('error', e => {res.writeHead(404); res.end(e.message);}); stream.pipe(res);
 } catch (e) {res.writeHead(500); res.end(e.stack);}
});
await new Promise(resolve => server.listen(port, '127.0.0.1', resolve));
chrome = spawn(chromePath, ['--headless', '--disable-gpu', '--no-first-run',
 '--no-default-browser-check', `--remote-debugging-port=${debugPort}`,
 `--user-data-dir=${path.join(root,'work/chrome-face')}`, 'about:blank'], {stdio:'ignore'});
chrome.on('error', e => {console.error(e); server.close(); process.exit(1);});
let targets;
for (let i=0;i<100;i++) {
 try {targets = await (await fetch(`http://127.0.0.1:${debugPort}/json/list`)).json(); break;}
 catch {await new Promise(resolve => setTimeout(resolve, 200));}
}
if (!targets) throw Error('Chrome não iniciou');
const target = targets.find(t => t.type === 'page');
cdp = new WebSocket(target.webSocketDebuggerUrl);
await new Promise((resolve,reject) => {cdp.onopen=resolve; cdp.onerror=reject;});
cdp.onmessage = e => {
 const r = JSON.parse(e.data); const p = pending.get(r.id); if (!p) return;
 clearTimeout(p.timer); pending.delete(r.id);
 if (r.error) p.reject(Error(r.error.message)); else p.resolve(r.result);
};
await command('Page.navigate', {url:`http://127.0.0.1:${port}/`});
for (let i=0;i<100;i++) {
 if (await evaluate('Boolean(window.detectorReady)')) break;
 await new Promise(resolve => setTimeout(resolve, 100));
}
await evaluate('window.detectorReady');
console.log(`Detector facial local pronto: http://127.0.0.1:${port}/landmarks`);
function close() {cdp?.close(); chrome?.kill(); server.close(); process.exit(0);}
process.on('SIGINT',close); process.on('SIGTERM',close);
