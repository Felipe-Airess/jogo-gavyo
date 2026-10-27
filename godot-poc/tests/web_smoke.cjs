// Opt-in read-only telemetry (?qa=1); inputs use real browser events.
const { chromium } = require(process.env.PLAYWRIGHT_MODULE || 'playwright');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const output = process.env.QA_OUTPUT || path.join(__dirname, '../.godot/qa-evidence');
fs.mkdirSync(output, { recursive: true });
(async () => {
  const browser = await chromium.launch({headless:true, ...(process.env.PLAYWRIGHT_CHANNEL ? {channel:process.env.PLAYWRIGHT_CHANNEL} : {})});
  const report = [];
  try {
    for (const [name, width, height, mobile] of [['desktop',1280,720,false],['landscape',844,390,true],['portrait',390,844,true]]) {
      const context = await browser.newContext({viewport:{width,height}, hasTouch:mobile, isMobile:mobile, deviceScaleFactor:1});
      const page = await context.newPage();
      const errors = [];
      page.on('pageerror', error => errors.push(String(error)));
      page.on('console', msg => { if (msg.type()==='error') errors.push(msg.text()); });
      await page.goto((process.env.QA_URL || 'http://127.0.0.1:8060/') + '?qa=1');
      await page.waitForFunction(()=>window.__GAVYO_QA?.time > 0.2, null, {timeout:45000});
      const state = () => page.evaluate(()=>window.__GAVYO_QA);
      await page.keyboard.press('r');
      const start = await state();
      await page.keyboard.down('a');
      await page.waitForTimeout(350);
      await page.keyboard.up('a');
      assert((await state()).fighters[0].x < start.fighters[0].x - 8, 'keyboard movement');
      await page.keyboard.press('Escape');
      await page.waitForTimeout(100);
      const frozen = await state();
      await page.waitForTimeout(200);
      assert.equal((await state()).time, frozen.time, 'pause freezes simulation');
      await page.keyboard.press('r');
      await page.waitForTimeout(60);
      if (mobile) {
        const cdp = await context.newCDPSession(page);
        // Logical canvas is 640 wide; Godot expands height according to aspect.
        const controls = await state();
        const scale = width / controls.width;
        const center = i => ({x:(controls.buttons[i][0]+controls.buttons[i][2]/2)*scale, y:(controls.buttons[i][1]+controls.buttons[i][3]/2)*scale});
        await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...center(0),id:1},{...center(5),id:2}]});
        await page.waitForTimeout(220);
        const multi = await state();
        assert(multi.held.left && multi.held.guard, 'two fingers hold movement and guard together');
        await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});
        await page.waitForTimeout(90);
        assert.equal(Object.keys((await state()).held).length, 0, 'touch cancellation clears commands');
        await page.keyboard.press('r');
        await page.waitForTimeout(60);
        await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[{...center(1),id:1},{...center(2),id:2}]});
        await page.waitForTimeout(100);
        const attack = await state();
        assert(attack.held.right && attack.fighters[0].state==='jab', 'move and jab touch input together');
        await cdp.send('Input.dispatchTouchEvent',{type:'touchCancel',touchPoints:[]});
      }
      await page.keyboard.press('r');
      await page.waitForTimeout(90);
      await page.screenshot({path:path.join(output,`${name}.png`)});
      assert.deepEqual(errors,[], 'browser has no script or rendering errors');
      report.push({name,width,height,checks:['load','keyboard movement','pause','reset',...(mobile?['multitouch guard + movement','touch cancellation','multitouch jab + movement']:[])],errors});
      await context.close();
    }
  } finally {
    await browser.close();
    fs.writeFileSync(path.join(output,'web-report.json'), JSON.stringify(report,null,2));
  }
  console.log(JSON.stringify(report,null,2));
})().catch(error=>{console.error(error); process.exitCode=1;});
