// node prod/shots.js [outDir]  — screenshots of the production UI review page
const path = require('path');
const { chromium } = require('playwright');
const out = process.argv[2] || path.resolve(__dirname, '../../docs/screenshots/production');
const STATES = [['hud', 1280, 720], ['index', 1280, 720], ['eggs', 1280, 720], ['characters', 1280, 720], ['upgrade', 1280, 720], ['trails', 1280, 720], ['sell', 1280, 720], ['shop', 1280, 720], ['reveal', 1280, 720], ['carrysafe', 1280, 720], ['hud', 844, 390, 'phone_hud'], ['sell', 844, 390, 'phone_sell'], ['index', 844, 390, 'phone_index']];
(async () => {
  require('fs').mkdirSync(out, { recursive: true });
  const b = await chromium.launch();
  const p = await b.newPage();
  p.on('pageerror', (e) => console.error('PAGE', e.message));
  for (const [s, w, h, name] of STATES) {
    await p.setViewportSize({ width: w, height: h });
    await p.goto('file://' + path.resolve(__dirname, 'review/index.html') + `?state=${s}&w=${w}&h=${h}`);
    await p.waitForSelector('body[data-ready="1"]');
    await p.waitForTimeout(150);
    await p.screenshot({ path: path.join(out, `${name || s}.png`) });
  }
  await b.close();
  console.log('shots ->', out);
})();
