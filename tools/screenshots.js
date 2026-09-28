// Captures review screenshots of the browser preview.
//   node screenshots.js                 -> all shots into docs/screenshots/
//   node screenshots.js name w h act1,act2 [scrollSelector:px]
const path = require('path');
const { chromium } = require('playwright');

const ROOT = path.resolve(__dirname, '..');
const URL = 'file://' + path.join(ROOT, 'preview/index.html');

const SHOTS = [
  ['hud_desktop', 1280, 720, ''],
  ['menu_shop', 1280, 720, 'menu:Shop'],
  ['menu_shop_scrolled', 1280, 720, 'menu:Shop', 'ShopMenu:560'],
  ['menu_index', 1280, 720, 'menu:Index'],
  ['menu_index_all_unlocked', 1280, 720, 'menu:Index,index:unlockAll'],
  ['menu_eggs', 1280, 720, 'menu:Eggs'],
  ['menu_characters', 1280, 720, 'menu:Characters'],
  ['menu_characters_equipbest', 1280, 720, 'menu:Characters,chars:equipBest'],
  ['menu_upgrade_character', 1280, 720, 'menu:Upgrade'],
  ['menu_upgrade_treadmill', 1280, 720, 'menu:Upgrade,upgrade:tab:Treadmill'],
  ['menu_upgrade_farm', 1280, 720, 'menu:Upgrade,upgrade:tab:Farm'],
  ['carry_secured_ready', 1280, 720, 'carry:secured,hatch:ready'],
  ['phone_hud', 844, 390, ''],
  ['phone_index', 844, 390, 'menu:Index'],
  ['phone_characters', 844, 390, 'menu:Characters'],
  ['desktop_1080p_shop', 1920, 1080, 'menu:Shop'],
  ['tablet_eggs', 1024, 768, 'menu:Eggs'],
];

async function shoot(page, [name, w, h, actions, scroll]) {
  await page.setViewportSize({ width: w + 60, height: h + 48 + 60 });
  await page.addStyleTag({ content: '#note{display:none}' }).catch(() => {});
  await page.goto(`${URL}?w=${w}&h=${h}&actions=${encodeURIComponent(actions)}`);
  await page.waitForSelector('body[data-ready="1"]');
  await page.addStyleTag({ content: '#note{display:none}' });
  if (scroll) {
    const [menu, px] = scroll.split(':');
    await page.evaluate(([m, y]) => {
      const el = [...document.querySelectorAll('.rbx.scroll')].find((e) => e.closest(`[data-name="${m}"]`));
      if (el) el.scrollTop = +y;
    }, [menu, px]);
  }
  await page.waitForTimeout(150);
  await page.locator('#stage').screenshot({ path: path.join(ROOT, 'docs/screenshots', `${name}.png`) });
}

(async () => {
  const browser = await chromium.launch();
  const page = await browser.newPage();
  page.on('pageerror', (e) => console.error('PAGE ERROR', e.message));
  const args = process.argv.slice(2);
  if (args.length) await shoot(page, [args[0], +args[1], +args[2], args[3] || '', args[4]]);
  else {
    for (const s of SHOTS) await shoot(page, s);
    // interaction states of the nav buttons: normal / hover / pressed / selected
    await page.setViewportSize({ width: 1340, height: 828 });
    await page.goto(`${URL}?w=1280&h=720&actions=menu:Upgrade`);
    await page.waitForSelector('body[data-ready="1"]');
    await page.addStyleTag({ content: '#note{display:none}' });
    const btn = (n) => page.locator(`[data-name="${n}"]`).first();
    await btn('ShopButton').hover();
    await page.waitForTimeout(200);
    const eggs = await btn('EggsButton').boundingBox();
    await page.mouse.move(eggs.x + 60, eggs.y + 30);
    await page.waitForTimeout(150);
    await page.mouse.down();
    await page.waitForTimeout(150);
    const nav = await btn('Nav').boundingBox();
    await page.screenshot({ path: path.join(ROOT, 'docs/screenshots/nav_states_pressed_eggs.png'), clip: { x: nav.x - 20, y: nav.y - 20, width: nav.width + 50, height: nav.height + 40 } });
    await page.mouse.up();
    await page.mouse.move(5, 5);
    await btn('ShopButton').hover();
    await page.waitForTimeout(200);
    await page.screenshot({ path: path.join(ROOT, 'docs/screenshots/nav_states_hover_shop.png'), clip: { x: nav.x - 20, y: nav.y - 20, width: nav.width + 50, height: nav.height + 40 } });
  }
  await browser.close();
})();
