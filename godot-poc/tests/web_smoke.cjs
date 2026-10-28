// Teste de navegador do duelo Godot exportado. Estado somente leitura (?qa=1);
// as entradas são eventos reais de teclado e toque.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const output = process.env.QA_OUTPUT || path.join(__dirname, '../.godot/qa-evidence');
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({ headless: true, ...(process.env.PLAYWRIGHT_CHANNEL ? { channel: process.env.PLAYWRIGHT_CHANNEL } : {}) });
  const report = [];
  try {
    for (const [name, width, height, mobile] of [['desktop', 1280, 720, false], ['landscape', 844, 390, true], ['portrait', 390, 844, true]]) {
      const context = await browser.newContext({ viewport: { width, height }, hasTouch: mobile, isMobile: mobile, deviceScaleFactor: 1 });
      const page = await context.newPage();
      const errors = [];
      const startupDiagnostics = [];
      page.on('pageerror', error => errors.push(String(error)));
      page.on('console', msg => {
        if (msg.type() !== 'error') return;
        const text = msg.text();
        // Emscripten imprime o progresso em stderr quando o WASM demora a iniciar.
        if (/^(still waiting on run dependencies:|dependency: wasm-instantiate|\(end of list\))$/.test(text)) startupDiagnostics.push(text);
        else errors.push(text);
      });
      await page.goto((process.env.QA_URL || 'http://127.0.0.1:8060/') + '?qa=1');
      await page.waitForFunction(() => window.__GAVYO_QA?.mode === 'select', null, { timeout: 90000 });
      const state = () => page.evaluate(() => window.__GAVYO_QA);
      await page.mouse.click(width / 2, 20);
      // Seleção → luta; os comandos só valem depois do "LUTA!".
      await page.keyboard.press('j');
      await page.waitForFunction(() => window.__GAVYO_QA?.phase === 'fight', null, { timeout: 5000 });
      const start = await state();
      await page.keyboard.down('a');
      await page.waitForTimeout(400);
      await page.keyboard.up('a');
      assert((await state()).fighters[0].x < start.fighters[0].x - 8, 'teclado anda');
      await page.keyboard.press('Escape');
      await page.waitForTimeout(100);
      const frozen = await state();
      assert.equal(frozen.mode, 'paused');
      await page.waitForTimeout(200);
      assert.equal((await state()).time, frozen.time, 'pausa congela a simulação');
      await page.keyboard.press('Escape');
      await page.waitForTimeout(100);
      const checks = ['load', 'select → fight', 'keyboard movement', 'pause'];
      if (mobile) {
        const s = await state();
        assert(s.touch, 'botões de toque visíveis em tela de toque');
        const cdp = await context.newCDPSession(page);
        const scale = width / s.width;
        const at = k => ({ x: s.buttons[k][0] * scale, y: s.buttons[k][1] * scale });
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...at('left'), id: 1 }, { ...at('guard'), id: 2 }] });
        await page.waitForTimeout(150);
        const multi = await state();
        assert(multi.held.left && multi.held.guard, 'dois dedos: direção e defesa juntas');
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchCancel', touchPoints: [] });
        await page.waitForTimeout(90);
        assert.equal(Object.keys((await state()).held).length, 0, 'cancelar o toque limpa os comandos');
        // A IA continua lutando: espera o jogador livre e aceita o soco em até 600 ms
        // (um golpe dela no mesmo instante adiaria o nosso).
        let attacked = false;
        for (let tries = 0; tries < 4 && !attacked; tries++) {
          await page.waitForFunction(() => ['idle', 'walk', 'guard'].includes(window.__GAVYO_QA?.fighters[0].state), null, { timeout: 3000 });
          await cdp.send('Input.dispatchTouchEvent', { type: 'touchStart', touchPoints: [{ ...at('right'), id: 1 }, { ...at('attack'), id: 2 }] });
          attacked = await page.waitForFunction(() => window.__GAVYO_QA?.held.right && window.__GAVYO_QA?.fighters[0].state === 'attack', null, { timeout: 600 }).then(() => true, () => false);
          await cdp.send('Input.dispatchTouchEvent', { type: 'touchCancel', touchPoints: [] });
          await page.waitForTimeout(150);
        }
        assert(attacked, 'direção e soco juntos pelo toque');
        await cdp.send('Input.dispatchTouchEvent', { type: 'touchCancel', touchPoints: [] });
        checks.push('multitouch guard + movement', 'touch cancellation', 'multitouch attack + movement');
      }
      await page.waitForTimeout(400);
      await page.screenshot({ path: path.join(output, `${name}.png`) });
      assert.deepEqual(errors, [], 'navegador sem erros de script ou de desenho');
      report.push({ name, width, height, checks, errors, startupDiagnostics });
      await context.close();
    }
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(output, 'web-report.json'), JSON.stringify(report, null, 2));
  }
  console.log(JSON.stringify(report, null, 2));
})().catch(error => { console.error(error); process.exitCode = 1; });
