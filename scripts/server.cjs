// Servidor local sem dependências. Restrito ao computador atual.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const { spawn } = require('node:child_process');
const root = path.resolve(__dirname, '..');
const port = Number(process.env.PORT || 4173);
const mime = { '.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.mjs':'text/javascript; charset=utf-8','.css':'text/css; charset=utf-8','.png':'image/png','.json':'application/json','.md':'text/plain; charset=utf-8' };
const server = http.createServer((req, res) => {
  let pathname;
  try { pathname = decodeURIComponent(new URL(req.url, 'http://localhost').pathname); } catch { res.writeHead(400).end(); return; }
  const file = path.resolve(root, '.' + (pathname === '/' ? '/index.html' : pathname));
  if (file !== root && !file.startsWith(root + path.sep)) { res.writeHead(403).end(); return; }
  fs.stat(file, (error, stat) => {
    if (error || !stat.isFile()) { res.writeHead(404).end('Arquivo não encontrado'); return; }
    res.writeHead(200, {'Content-Type':mime[path.extname(file)] || 'application/octet-stream','Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});
    if (req.method === 'HEAD') res.end(); else fs.createReadStream(file).pipe(res);
  });
});
server.on('error', error => { console.error('Não foi possível abrir o jogo:', error.message); process.exitCode = 1; });
server.listen(port, '127.0.0.1', () => {
  const url = `http://127.0.0.1:${port}`;
  console.log(`GAVIÃO disponível em ${url}\nCtrl+C para encerrar.`);
  if (process.argv.includes('--open')) {
    const child = process.platform === 'win32'
      ? spawn('cmd.exe', ['/c', 'start', '', url], { windowsHide:true, stdio:'ignore' })
      : spawn(process.platform === 'darwin' ? 'open' : 'xdg-open', [url], { stdio:'ignore' });
    child.on('error', () => console.log('Abra o endereço acima no navegador.'));
    child.unref();
  }
});
