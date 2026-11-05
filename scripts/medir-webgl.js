// Mede comandos WebGL e desenhos por quadro na build web (Chromium/Playwright).
// Uso: (cd godot-3d/web && python3 -m http.server 8010) & node scripts/medir-webgl.js
const { chromium } = require('playwright');
(async () => {
  const q = process.argv[2] || '';
  const b = await chromium.launch({ args: ['--use-angle=swiftshader','--enable-unsafe-swiftshader','--ignore-gpu-blocklist'] });
  const p = await b.newPage({ viewport: { width: 1280, height: 720 } });
  await p.addInitScript(() => {
    window.__gl = {}; window.__frames = 0;
    const P = WebGL2RenderingContext.prototype;
    for (const k of Object.getOwnPropertyNames(P)) {
      const d = Object.getOwnPropertyDescriptor(P, k);
      if (!d || typeof d.value !== 'function') continue;
      const f = d.value; P[k] = function () { window.__gl[k] = (window.__gl[k] || 0) + 1; return f.apply(this, arguments); };
    }
    const raf = window.requestAnimationFrame.bind(window);
    window.requestAnimationFrame = cb => raf(t => { window.__frames++; cb(t); });
  });
  await p.goto('http://localhost:8010/index.html?x=' + q);
  await p.waitForTimeout(40000);
  await p.mouse.click(640,360); await p.keyboard.press('Enter'); await p.keyboard.press('Space');
  await p.waitForTimeout(15000);
  await p.evaluate(() => { window.__gl = {}; window.__frames = 0; });
  await p.waitForTimeout(6000);
  const r = await p.evaluate(() => ({ gl: window.__gl, frames: window.__frames }));
  const f = Math.max(1, r.frames); const g = r.gl;
  const tot = Object.values(g).reduce((a,b)=>a+b,0);
  console.log(`${q||'normal'}: desenhos/quadro=${(((g.drawElements||0)+(g.drawElementsInstanced||0)+(g.drawArrays||0))/f).toFixed(0)} comandosGL/quadro=${(tot/f).toFixed(0)} useProgram=${((g.useProgram||0)/f).toFixed(0)} quadros=${r.frames}`);
  await p.screenshot({path:'web_'+(q||'normal')+'.png'}); await b.close();
})();
