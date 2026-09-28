// Renders the original SVG art to assets/svg + assets/png, packs 1024x1024
// atlases (Roblox max upload size) and writes assets/asset-manifest.json.
//
//   node render-art.js
const fs = require('fs');
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const SVG_DIR = path.join(ROOT, 'assets/svg');
const PNG_DIR = path.join(ROOT, 'assets/png');
const ATLAS_DIR = path.join(PNG_DIR, 'atlas');

const icons = require('./art/icons');
const collect = require('./art/collect');
const all = { ...icons, ...collect };

// Stand-alone images (tiling patterns must be separate uploads in Roblox).
const STANDALONE = ['fx_rays', 'pattern_diagonal', 'pattern_dots', 'pattern_tiles', 'pattern_stars', 'pattern_hazard'];
const CELL = 256; const ATLAS = 1024; const PER = (ATLAS / CELL) ** 2;

async function main() {
  for (const d of [SVG_DIR, PNG_DIR, ATLAS_DIR]) fs.mkdirSync(d, { recursive: true });
  const svgs = {};
  for (const [name, fn] of Object.entries(all)) {
    svgs[name] = fn();
    fs.writeFileSync(path.join(SVG_DIR, `${name}.svg`), svgs[name]);
  }
  const browser = await chromium.launch();
  const page = await browser.newPage({ deviceScaleFactor: 1 });
  const dataUri = (s) => 'data:image/svg+xml;base64,' + Buffer.from(s).toString('base64');

  // individual PNGs
  for (const [name, s] of Object.entries(svgs)) {
    const m = s.match(/width="(\d+)" height="(\d+)"/);
    const w = +m[1]; const h = +m[2];
    await page.setViewportSize({ width: w, height: h });
    await page.setContent(`<html><body style="margin:0;background:transparent"><img src="${dataUri(s)}" width="${w}" height="${h}" style="display:block"></body></html>`);
    await page.waitForFunction(() => document.images[0].complete);
    await page.screenshot({ path: path.join(PNG_DIR, `${name}.png`), omitBackground: true });
  }

  // atlases
  const packed = Object.keys(svgs).filter((n) => !STANDALONE.includes(n));
  const manifest = { cell: CELL, atlasSize: ATLAS, atlases: {}, images: {} };
  for (let a = 0; a * PER < packed.length; a++) {
    const names = packed.slice(a * PER, (a + 1) * PER);
    const atlasName = `atlas_${String.fromCharCode(97 + a)}`;
    manifest.atlases[atlasName] = { file: `assets/png/atlas/${atlasName}.png`, size: [ATLAS, ATLAS] };
    let html = '<html><body style="margin:0;background:transparent;position:relative">';
    names.forEach((n, i) => {
      const x = (i % 4) * CELL; const y = Math.floor(i / 4) * CELL;
      html += `<img src="${dataUri(svgs[n])}" style="position:absolute;left:${x}px;top:${y}px;width:${CELL}px;height:${CELL}px">`;
      manifest.images[n] = { atlas: atlasName, offset: [x, y], size: [CELL, CELL] };
    });
    await page.setViewportSize({ width: ATLAS, height: ATLAS });
    await page.setContent(html + '</body></html>');
    await page.waitForFunction(() => [...document.images].every((i) => i.complete));
    await page.screenshot({ path: path.join(ATLAS_DIR, `${atlasName}.png`), omitBackground: true });
  }
  for (const n of STANDALONE) {
    const m = svgs[n].match(/width="(\d+)" height="(\d+)"/);
    manifest.images[n] = { standalone: n, file: `assets/png/${n}.png`, size: [+m[1], +m[2]] };
  }

  // contact sheet for visual review
  let sheet = '<html><body style="margin:0;padding:16px;background:#3b2f7a;font:12px sans-serif;color:#fff;display:flex;flex-wrap:wrap;gap:10px;width:1568px">';
  for (const n of Object.keys(svgs)) sheet += `<div style="width:140px;text-align:center;background:${n.startsWith('pattern') ? '#7a5cff' : 'rgba(255,255,255,.08)'};border-radius:10px;padding:6px"><img src="${dataUri(svgs[n])}" style="width:128px;height:128px;object-fit:contain"><div>${n}</div></div>`;
  await page.setViewportSize({ width: 1600, height: 900 });
  await page.setContent(sheet + '</body></html>');
  await page.waitForFunction(() => [...document.images].every((i) => i.complete));
  fs.mkdirSync(path.join(ROOT, 'docs/screenshots'), { recursive: true });
  await page.screenshot({ path: path.join(ROOT, 'docs/screenshots/art_contact_sheet.png'), fullPage: true });

  await browser.close();
  fs.writeFileSync(path.join(ROOT, 'assets/asset-manifest.json'), JSON.stringify(manifest, null, 2));
  console.log(`rendered ${Object.keys(svgs).length} svgs, ${Object.keys(manifest.atlases).length} atlases`);
}

main().catch((e) => { console.error(e); process.exit(1); });
