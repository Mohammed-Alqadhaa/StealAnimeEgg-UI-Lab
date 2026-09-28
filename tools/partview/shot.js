// node tools/partview/shot.js <data.json> <out.png> "<query string>"
// Renders exported part JSON with three.js in headless Chromium (review aid only).
const fs = require('fs');
const path = require('path');
const http = require('http');
const { chromium } = require('playwright');

(async () => {
  const [dataPath, outPath, query = ''] = process.argv.slice(2);
  const root = path.resolve(__dirname, '..');
  const data = fs.readFileSync(dataPath, 'utf8');
  const server = http.createServer((req, res) => {
    const url = decodeURIComponent(req.url.split('?')[0]);
    if (url === '/data.js') { res.writeHead(200, { 'content-type': 'text/javascript' }); return res.end('window.PART_DATA=' + data + ';'); }
    const file = path.join(root, url);
    if (!file.startsWith(root) || !fs.existsSync(file)) { res.writeHead(404); return res.end(); }
    const type = file.endsWith('.js') ? 'text/javascript' : file.endsWith('.html') ? 'text/html' : 'application/octet-stream';
    res.writeHead(200, { 'content-type': type }); fs.createReadStream(file).pipe(res);
  }).listen(0);
  const port = server.address().port;
  const q = new URLSearchParams(query);
  const w = +(q.get('w') || 1280), h = +(q.get('h') || 720);
  const browser = await chromium.launch({ args: ['--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  const page = await browser.newPage({ viewport: { width: w, height: h } });
  page.on('pageerror', (e) => console.error('PAGE', e.message));
  page.on('console', (m) => { if (m.type() === 'error') console.error('CONSOLE', m.text()); });
  const html = fs.readFileSync(path.join(__dirname, 'view.html'), 'utf8').replace('<script type="importmap">', '<script src="/data.js"></script><script type="importmap">');
  fs.writeFileSync(path.join(__dirname, '_view.html'), html);
  await page.goto(`http://localhost:${port}/partview/_view.html?${query}`);
  await page.waitForSelector('body[data-ready="1"]', { timeout: 120000 });
  await page.screenshot({ path: outPath });
  await browser.close();
  server.close();
})().catch((e) => { console.error(e); process.exit(1); });
