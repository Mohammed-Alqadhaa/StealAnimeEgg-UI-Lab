// PRODUCTION UI (Steal An Anime Egg) — built from the UI Lab design system.
// No sample/demo data: every list is a hidden Template that the client
// (game/src/client/UI/*) clones and binds to the server StateSnapshot.
// The UI Lab preview panel is NOT included (§ "remove preview panel").
const { I, U2, px, UD, E } = require('../lib/rbx');
const { INK, C } = require('../lib/theme');
const K = require('../lib/components');
const { box, label, img, chunky, chunkyFaces, badge, tag, progress, stroke, grad, list, gridLayout, padding, scaleMod, gloss } = K;
const HUD = require('../ui/hud');
const M = require('../ui/menus');

const folder = (name, ...kids) => I('Folder', { Name: name }, ...kids);
const scroll = (name, o, ...kids) => I('ScrollingFrame', {
  Name: name, Position: o.pos, Size: o.size, BackgroundTransparency: 1, BorderSizePixel: 0,
  CanvasSize: U2(0, 0, 0, 0), AutomaticCanvasSize: E(o.dir === 'X' ? 'X' : 'Y'), ScrollingDirection: E(o.dir || 'Y'),
  ScrollBarThickness: 8, ScrollBarImageColor3: K.gprops({ bg: o.bar || INK }).BackgroundColor3, ElasticBehavior: E('WhenScrollable'),
  ZIndex: o.z,
}, ...kids);
const viewport = (name, o = {}) => I('ViewportFrame', {
  Name: name, Size: o.size || U2(1, 0, 1, 0), Position: o.pos, AnchorPoint: o.anchor ? K.gprops({ anchor: o.anchor }).AnchorPoint : undefined,
  BackgroundTransparency: 1, BorderSizePixel: 0, ZIndex: o.z ?? 4,
  $attrs: { Viewport: o.kind || 'Character', ...(o.attrs || {}) },
});
const emptyState = (text, icon) => box('Empty', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(420, 120), visible: false },
  img('Icon', icon, { pos: U2(0.5, 0, 0, 0), anchor: [0.5, 0], size: px(64, 64), rot: -8 }),
  label('Text', text, { pos: U2(0, 0, 0, 70), size: U2(1, 0, 0, 44), ts: 20, font: 'Fredoka', color: INK, stroke: 0, wrap: true }));
const btn = (name, theme, text, o = {}) => chunky(name, { theme, size: o.size || px(140, 48), pos: o.pos, anchor: o.anchor, r: o.r ?? 12, lip: o.lip ?? 6, label: text, ts: o.ts || 22, icon: o.icon, iconSize: o.iconSize, sub: o.sub, subTs: o.subTs, lo: o.lo, z: o.z, visible: o.visible, attrs: o.attrs });

// ------------------------------------------------------------------ HUD
function hud() {
  const h = HUD.hud({ hud: { speed: '0', cash: '$0', income: '+$0/s' } });
  // plus buttons open the Shop instead of the lab's "Buy*" placeholder actions
  return h;
}
function nav() {
  const n = HUD.nav();
  // badges start hidden; the client shows counts (ready eggs, new index entries)
  (function hide(x) { if (x.name === 'Badge') x.props.Visible = false; x.children.forEach(hide); })(n);
  return n;
}

// round / fog-gate timer (top centre) — rendered from workspace PhaseEndsAt
function roundTimer() {
  return box('RoundTimer', { anchor: [0.5, 0], pos: U2(0.5, 0, 0, 10), size: px(300, 64), attrs: { Layer: 'HUD' } },
    scaleMod(),
    box('Pill', { size: U2(1, 0, 1, 0), bg: '#FFFFFF', r: 'pill', grad: [[0, '#3A2A8F'], [1, '#1B1036']] },
      stroke(3.5, INK),
      img('Pattern', 'pattern_diagonal', { tile: 40, imgT: 0.9, r: 'pill' }),
      img('Clock', 'icon_timer', { pos: U2(0, 8, 0.5, 0), anchor: [0, 0.5], size: px(48, 48) }),
      label('Phase', 'ROUND', { pos: U2(0, 62, 0, 6), size: U2(1, -76, 0, 20), ts: 16, xa: 'Left', font: 'Fredoka', color: '#A6F2FF', stroke: 2 }),
      label('Time', '5:00', { pos: U2(0, 62, 0, 22), size: U2(1, -76, 0, 36), ts: 32, xa: 'Left', stroke: 3, grad: ['#FFFFFF', '#E4F6FF'] })));
}

// carry banner — "Reach the Farm Safe Zone!" (§ carry text, exact wording)
function carry() {
  const c = HUD.eggCarry({ eggs: [{}, {}, { art: 'egg_anime' }] });
  (function fix(x) {
    if (x.name === 'Sub' && x.props.Text && x.props.Text.startsWith('UNSAFE')) x.props.Text = 'Reach the Farm Safe Zone!';
    if (x.name === 'Sub' && x.props.Text && x.props.Text.startsWith('Safe in')) x.props.Text = 'Safe on your farm - hatching started!';
    if (x.name === 'Egg3D') { x.props.Visible = true; x.attrs = { Viewport: 'Egg' }; }
    if (x.name === 'Egg' && x.cls === 'ImageLabel') x.props.Visible = false;
    x.children.forEach(fix);
  })(c);
  c.props.Visible = false;
  c.attrs = { Layer: 'HUD' };
  return c;
}

// hatch widget — nearest egg on the farm (timer from server hatchAt)
function hatchWidget() {
  const w = HUD.hatchWidget({ eggs: [{ art: 'egg_anime', name: 'Egg', state: 'HATCHING', remaining: 60 }], hatchSeconds: 60 });
  (function fix(x) {
    if (x.name === 'Egg' && x.cls === 'ImageLabel') x.props.Visible = false;
    if (x.name === 'EggSlot') x.add(viewport('Egg3D', { kind: 'Egg', z: 3 }));
    x.children.forEach(fix);
  })(w);
  w.props.Visible = false;
  w.attrs = { Layer: 'HUD' };
  w.add(label('More', '', { pos: U2(1, -12, 0, 6), anchor: [1, 0], size: px(60, 22), ts: 16, xa: 'Right', font: 'Fredoka', stroke: 2, z: 6 }));
  return w;
}

// ----------------------------------------------------------- card faces
// Neutral card face; the client recolours Face.UIGradient with the world palette.
function worldFaces(r = 16) {
  return [
    box('Lip', { size: U2(1, 0, 1, 0), bg: '#16122B', r, z: 1 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -6), bg: '#FFFFFF', r, z: 2, grad: [[0, '#8C84C2'], [0.5, '#443D6B'], [1, '#2A2447']] },
      stroke(2, '#FFFFFF', { name: 'InnerRim', t: 0.55 }),
      img('Pattern', 'pattern_stars', { tile: 64, imgT: 0.8, r }),
      gloss({ r: r - 4, a: 0.55, h: 0.3 })),
  ];
}
function well(o = {}) {
  return box('Well', { pos: o.pos || U2(0.5, 0, 0, 8), anchor: [0.5, 0], size: o.size || U2(1, -12, 0, 104), bg: '#0B0718', bgT: 0.35, r: 12, z: 3 },
    stroke(2.5, INK, { t: 0.2 }),
    img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(170, 170), imgT: 0.7, attrs: { Spin: 14 } }),
    viewport('Model', { kind: o.kind || 'Character', z: 4 }));
}
const namePlate = (text, o = {}) => box('NamePlate', { pos: o.pos || U2(0.5, 0, 1, -10), anchor: [0.5, 1], size: o.size || U2(1, -10, 0, 30), bg: INK, bgT: 0.15, r: 10, z: 4 },
  label('Name', text, { ts: o.ts || 16, stroke: 2, scaled: false, maxTs: o.ts || 16, wrap: true }));

// =============================================================== INDEX (§ Index: 9 worlds, silhouettes)
function worldTab() {
  const mk = (theme) => chunkyFaces({ theme, r: 12, lip: 5, sw: 3, label: 'WORLD', ts: 17, content: [
    label('Label', 'WORLD', { pos: U2(0, 8, 0, 6), size: U2(1, -56, 1, -12), ts: 16, xa: 'Left', stroke: 2.5, scaled: true, maxTs: 16 }),
    label('Count', '0/5', { pos: U2(1, -8, 0, 0), anchor: [1, 0], size: px(44, 40), ts: 15, xa: 'Right', font: 'Fredoka', stroke: 2 }),
  ] });
  return I('TextButton', { ...K.gprops({ name: 'WorldTab', size: U2(1, -6, 0, 42) }), Text: '', AutoButtonColor: false, $attrs: { Chunky: true, LipDepth: 5 } },
    scaleMod(1, 'PressScale'),
    box('Active', { size: U2(1, 0, 1, 0), visible: false }, ...mk('gold')),
    box('Inactive', { size: U2(1, 0, 1, 0) }, ...mk('slate')));
}
function indexCard() {
  return box('IndexCard', { size: px(98, 176) },
    ...worldFaces(14),
    well({ size: U2(1, -10, 0, 112), pos: U2(0.5, 0, 0, 6) }),
    namePlate('???', { size: U2(1, -8, 0, 44), pos: U2(0.5, 0, 1, -10), ts: 15 }),
    box('LockBadge', { pos: U2(1, 4, 0, -4), anchor: [1, 0], size: px(32, 32), bg: '#FFFFFF', r: 'pill', z: 6, grad: ['#4A4275', '#1B1036'] },
      stroke(2.5, INK), img('Icon', 'icon_lock', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(22, 22) })),
    tag('BossTag', 'BOSS', { theme: 'red', pos: U2(0, -6, 0, -6), w: 46, h: 20, rot: -8, ts: 13, visible: false }),
  );
}
function indexMenu() {
  const th = C.index;
  const body = [
    box('Sidebar', { pos: U2(0, 10, 0, 10), size: U2(0, 170, 1, -20), bg: INK, bgT: 0.85, r: 14 },
      scroll('Tabs', { pos: U2(0, 4, 0, 6), size: U2(1, -6, 1, -12), bar: th.lo }, list('Vertical', 6, 'Center', 'Top'), padding(2, 4, 2, 2))),
    box('Header', { pos: U2(0, 190, 0, 10), size: U2(1, -200, 0, 70), bg: '#FFFFFF', r: 16, grad: [[0, th.hi], [0.5, th.base], [1, th.lo]] },
      stroke(3.5, INK), img('Pattern', 'pattern_diagonal', { tile: 40, imgT: 0.9, r: 16 }), gloss({ r: 12, a: 0.5, h: 0.4 }),
      label('World', 'DEMON SLAYER', { pos: U2(0, 14, 0, 6), size: U2(1, -200, 0, 36), ts: 32, xa: 'Left', stroke: 3.5 }),
      label('Discovered', '0 / 5 Discovered', { pos: U2(0, 16, 0, 40), size: U2(1, -200, 0, 22), ts: 17, xa: 'Left', font: 'Fredoka', color: '#FFF3A6', stroke: 2 }),
      progress('Total', { pos: U2(1, -12, 0.5, 0), anchor: [1, 0.5], size: px(170, 30), theme: 'gold', value: 0, text: '0 / 45', h: 30 })),
    box('Grid', { pos: U2(0, 190, 0, 92), size: U2(1, -200, 0, 190) }, gridLayout(98, 176, 6, 8, 'Center')),
    box('Hint', { pos: U2(0, 190, 1, -12), anchor: [0, 1], size: U2(1, -200, 0, 40), bg: INK, bgT: 0.15, r: 'pill' },
      label('Text', 'Open eggs on your farm to discover characters!', { ts: 17, font: 'Fredoka', stroke: 2 })),
    folder('Templates', worldTab(), indexCard()),
  ];
  return M.menuWindow('Index', th, 'INDEX', 'icon_index', body);
}

// ================================================================ EGGS
function eggCard() {
  return box('EggCard', { size: px(160, 214) },
    ...worldFaces(16),
    well({ kind: 'Egg', size: U2(1, -12, 0, 108) }),
    label('Name', 'EGG', { pos: U2(0, 6, 0, 118), size: U2(1, -12, 0, 22), ts: 16, stroke: 2, z: 4, maxTs: 16 }),
    label('World', 'WORLD', { pos: U2(0, 6, 0, 138), size: U2(1, -12, 0, 16), ts: 13, font: 'Fredoka', color: '#FFF3A6', stroke: 1.5, z: 4 }),
    box('Hatching', { pos: U2(0, 8, 1, -54), size: U2(1, -16, 0, 42), z: 4 },
      label('Timer', '1:00', { size: U2(1, 0, 0, 20), ts: 20, stroke: 2.5 }),
      progress('Bar', { pos: U2(0, 0, 0, 22), size: U2(1, 0, 0, 16), theme: 'speed', value: 0, h: 16, stripes: false })),
    btn('OpenButton', 'upgrade', 'OPEN', { size: U2(1, -16, 0, 40), pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], ts: 22, visible: false, z: 5, attrs: { Action: 'OpenEgg' } }),
  );
}
function eggsMenu() {
  const th = C.eggs;
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 10), size: U2(1, -24, 0, 40), bg: INK, bgT: 0.15, r: 'pill' },
      label('Info', 'Eggs hatch on your farm in 60s - they take no character slots.', { ts: 16, font: 'Fredoka', stroke: 2 })),
    scroll('Grid', { pos: U2(0, 8, 0, 56), size: U2(1, -16, 1, -64), bar: th.lo }, padding(10, 8, 12, 8), gridLayout(160, 214, 10, 12, 'Center')),
    emptyState('No eggs yet. Grab one in a world and reach the Farm Safe Zone!', 'icon_eggs'),
    folder('Templates', eggCard()),
  ];
  return M.menuWindow('Eggs', th, 'EGGS', 'icon_eggs', body);
}

// ========================================================== CHARACTERS
function unitCard() {
  return box('UnitCard', { size: px(128, 212) },
    ...worldFaces(16),
    well({ size: U2(1, -10, 0, 100), pos: U2(0.5, 0, 0, 6) }),
    label('Level', 'LV 1', { pos: U2(0, 8, 0, 10), size: px(50, 18), ts: 14, xa: 'Left', stroke: 2, z: 6 }),
    label('Name', 'NAME', { pos: U2(0, 4, 0, 108), size: U2(1, -8, 0, 20), ts: 15, stroke: 2, z: 4, maxTs: 15 }),
    K.statRow('Income', 'icon_cash', '$0/s', { pos: U2(0, 0, 0, 130), size: U2(1, 0, 0, 22), ts: 16, is: 18 }),
    tag('EquippedTag', 'ON FARM', { theme: 'upgrade', pos: U2(1, 4, 0, -6), anchor: [1, 0], w: 70, h: 20, rot: 6, ts: 12, visible: false }),
    btn('EquipButton', 'upgrade', 'EQUIP', { size: U2(1, -14, 0, 40), pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], ts: 20, z: 5 }),
  );
}
function charactersMenu() {
  const th = C.chars;
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 10), size: U2(1, -24, 0, 64) },
      M.chip('SlotsChip', { size: px(200, 54), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_slots', { pos: U2(0, 4, 0.5, 0), anchor: [0, 0.5], size: px(44, 44) }),
        label('Caption', 'FARM SLOTS', { pos: U2(0, 52, 0, 5), size: px(140, 16), ts: 13, font: 'Fredoka', color: th.text, stroke: 0, xa: 'Left' }),
        label('Value', '0 / 5', { pos: U2(0, 52, 0, 20), size: px(140, 28), ts: 26, xa: 'Left', stroke: 3, grad: ['#FFFFFF', th.hi] })),
      M.chip('IncomeChip', { size: px(220, 54), pos: U2(0, 210, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_cash', { pos: U2(0, 4, 0.5, 0), anchor: [0, 0.5], size: px(44, 44) }),
        label('Caption', 'FARM INCOME', { pos: U2(0, 52, 0, 5), size: px(150, 16), ts: 13, font: 'Fredoka', color: C.cash.text, stroke: 0, xa: 'Left' }),
        label('Value', '$0/s', { pos: U2(0, 52, 0, 20), size: px(160, 28), ts: 26, xa: 'Left', stroke: 3, grad: ['#FFFFFF', C.cash.hi] })),
      chunky('EquipBestButton', { theme: 'gold', size: px(228, 58), pos: U2(1, 0, 0.5, 0), anchor: [1, 0.5], r: 16, lip: 7, sw: 3.5, icon: 'icon_equip_best', iconSize: 44, label: 'EQUIP BEST', sub: 'highest $/sec', ts: 24, subTs: 13, attrs: { Action: 'EquipBest' } })),
    scroll('Grid', { pos: U2(0, 8, 0, 80), size: U2(1, -16, 1, -88), bar: th.lo }, padding(12, 8, 12, 8), gridLayout(128, 212, 10, 14, 'Center')),
    emptyState('No characters yet. Open a hatched egg to get your first one!', 'icon_characters'),
    folder('Templates', unitCard()),
  ];
  return M.menuWindow('Characters', th, 'CHARACTERS', 'icon_characters', body);
}

// ============================================================= UPGRADE
function upgradeRow() {
  return box('UpgradeRow', { size: U2(1, -8, 0, 84), bg: '#FFFFFF', r: 16 },
    stroke(3, INK),
    box('Thumb', { pos: U2(0, 6, 0.5, 0), anchor: [0, 0.5], size: px(72, 72), bg: '#2A2447', r: 12 }, stroke(2, INK, { t: 0.3 }), viewport('Model', { z: 3 })),
    label('Name', 'NAME', { pos: U2(0, 88, 0, 8), size: U2(0.42, 0, 0, 26), ts: 22, xa: 'Left', color: INK, stroke: 0 }),
    label('Level', 'LV 1 / 10', { pos: U2(0, 88, 0, 34), size: U2(0.42, 0, 0, 18), ts: 15, xa: 'Left', font: 'Fredoka', color: C.upgrade.text, stroke: 0 }),
    M.levelPips('Pips', 1, 10, C.upgrade, { pos: U2(0, 88, 0, 56), w: 12, h: 12 }),
    label('Income', '$0/s  >  $0/s', { pos: U2(0.5, 0, 0, 0), size: U2(0.24, 0, 1, 0), ts: 18, font: 'Fredoka', color: C.cash.text, stroke: 0, rich: true }),
    chunky('UpgradeButton', { theme: 'upgrade', size: px(170, 60), pos: U2(1, -8, 0.5, -2), anchor: [1, 0.5], r: 14, lip: 6, label: 'UPGRADE', sub: '$0', ts: 22, subTs: 16 }),
  );
}
function infoCard(name, th, icon, title) {
  return box(name, { size: U2(0.5, -6, 1, 0), bg: '#FFFFFF', r: 16, grad: [[0, th.hi], [0.5, th.base], [1, th.lo]] },
    stroke(3.5, INK), img('Pattern', 'pattern_dots', { tile: 40, imgT: 0.85, r: 16 }), gloss({ r: 12, a: 0.45, h: 0.35 }),
    img('Icon', icon, { pos: U2(0, 6, 0.5, 0), anchor: [0, 0.5], size: px(62, 62), rot: -6 }),
    label('Title', title, { pos: U2(0, 74, 0, 6), size: U2(1, -220, 0, 26), ts: 22, xa: 'Left', stroke: 2.5 }),
    label('Stat', '', { pos: U2(0, 74, 0, 32), size: U2(1, -220, 0, 44), ts: 13, xa: 'Left', font: 'Fredoka', stroke: 2, wrap: true, ya: 'Top' }),
    chunky('UpgradeButton', { theme: 'gold', size: px(136, 56), pos: U2(1, -8, 0.5, -2), anchor: [1, 0.5], r: 14, lip: 6, label: 'UPGRADE', sub: '$0', ts: 20, subTs: 15 }));
}
function upgradeMenu() {
  const th = C.upgrade;
  const body = [
    box('Cards', { pos: U2(0, 12, 0, 10), size: U2(1, -24, 0, 84) },
      list('Horizontal', 12, 'Center', 'Center'),
      infoCard('FarmCard', C.chars, 'icon_farm', 'FARM'),
      infoCard('TreadmillCard', C.speed, 'icon_treadmill', 'TREADMILL')),
    label('ListTitle', 'CHARACTER UPGRADES', { pos: U2(0, 16, 0, 100), size: U2(1, -32, 0, 26), ts: 22, xa: 'Left', stroke: 2.5, grad: ['#FFFFFF', th.hi] }),
    scroll('List', { pos: U2(0, 8, 0, 128), size: U2(1, -16, 1, -134), bar: th.lo }, padding(6, 8, 10, 8), list('Vertical', 8, 'Center', 'Top')),
    emptyState('Characters you own can be upgraded here. Prices are set by the server.', 'icon_upgrade'),
    folder('Templates', upgradeRow()),
  ];
  return M.menuWindow('Upgrade', th, 'UPGRADE', 'icon_upgrade', body);
}

// ============================================================ TRAIL SHOP (Makima kiosk)
function trailCard() {
  return box('TrailCard', { size: px(160, 214) },
    ...worldFaces(16),
    box('Swatch', { pos: U2(0.5, 0, 0, 10), anchor: [0.5, 0], size: U2(1, -16, 0, 84), bg: '#FFFFFF', r: 12, z: 3, grad: ['#FFFFFF', '#9FE3FF'], gradRot: 0 },
      stroke(2.5, INK),
      img('Streak', 'pattern_diagonal', { tile: 30, imgT: 0.55, r: 12 }),
      label('Mult', 'x1.5', { ts: 40, stroke: 4, z: 5 })),
    label('Name', 'TRAIL', { pos: U2(0, 6, 0, 100), size: U2(1, -12, 0, 22), ts: 17, stroke: 2, z: 4, maxTs: 17 }),
    label('Family', 'WIND', { pos: U2(0, 6, 0, 122), size: U2(1, -12, 0, 16), ts: 13, font: 'Fredoka', color: '#FFF3A6', stroke: 1.5, z: 4 }),
    tag('EquippedTag', 'EQUIPPED', { theme: 'upgrade', pos: U2(1, 4, 0, -6), anchor: [1, 0], w: 80, h: 20, rot: 6, ts: 12, visible: false }),
    chunky('BuyButton', { theme: 'gold', size: U2(1, -14, 0, 48), pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], r: 12, lip: 6, label: 'BUY', sub: '$0', ts: 18, subTs: 14, z: 5 }),
  );
}
function trailShopMenu() {
  const th = C.speed;
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 10), size: U2(1, -24, 0, 50) },
      M.chip('Current', { size: px(420, 46), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_speed', { pos: U2(0, 4, 0.5, 0), anchor: [0, 0.5], size: px(38, 38) }),
        label('Text', 'No trail equipped (x1)', { pos: U2(0, 48, 0, 0), size: U2(1, -56, 1, 0), ts: 18, xa: 'Left', font: 'Fredoka', color: INK, stroke: 0 })),
      btn('UnequipButton', 'slate', 'UNEQUIP', { size: px(150, 46), pos: U2(1, 0, 0.5, 0), anchor: [1, 0.5], ts: 20, attrs: { Action: 'UnequipTrail' } })),
    scroll('Grid', { pos: U2(0, 8, 0, 64), size: U2(1, -16, 1, -72), bar: th.lo }, padding(10, 8, 12, 8), gridLayout(160, 214, 10, 12, 'Center')),
    folder('Templates', trailCard()),
  ];
  return M.menuWindow('TrailShop', th, 'TRAILS', 'icon_speed', body, {
    headerExtra: label('Sub', 'One trail at a time - trails never stack', { pos: U2(0, 108, 0, 64), size: px(420, 18), ts: 15, xa: 'Left', font: 'Fredoka', stroke: 2, z: 5 }),
  });
}

// ================================================================ SELL (Rem kiosk)
function sellCard() {
  return I('TextButton', { ...K.gprops({ name: 'SellCard', size: px(104, 164) }), Text: '', AutoButtonColor: false },
    ...worldFaces(14),
    well({ size: U2(1, -10, 0, 84), pos: U2(0.5, 0, 0, 6) }),
    label('Level', 'LV 1', { pos: U2(0, 8, 0, 8), size: px(44, 16), ts: 13, xa: 'Left', stroke: 2, z: 6 }),
    label('Name', 'NAME', { pos: U2(0, 4, 0, 92), size: U2(1, -8, 0, 18), ts: 13, stroke: 2, z: 4, maxTs: 13 }),
    label('Value', '$0', { pos: U2(0, 4, 0, 112), size: U2(1, -8, 0, 22), ts: 18, stroke: 2.5, z: 4, grad: ['#FFFFFF', C.cash.hi] }),
    tag('EquippedTag', 'ON FARM', { theme: 'upgrade', pos: U2(0.5, 0, 1, -8), anchor: [0.5, 1], w: 70, h: 18, ts: 11, visible: false }),
    box('Selected', { size: U2(1, 0, 1, 0), bg: '#46D95F', bgT: 0.6, r: 14, z: 8, visible: false },
      stroke(4, '#FFFFFF'),
      box('Check', { pos: U2(1, -6, 0, 6), anchor: [1, 0], size: px(30, 30), bg: '#FFFFFF', r: 'pill', grad: [C.upgrade.hi, C.upgrade.lo] },
        stroke(2.5, INK), img('Icon', 'icon_check', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(22, 22) }))),
  );
}
function sellMenu() {
  const th = C.cash;
  const sortBtn = (id, text, lo) => btn(`Sort_${id}`, 'slate', text, { size: px(96, 38), ts: 15, lo, attrs: { Sort: id } });
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 8), size: U2(1, -24, 0, 42) },
      list('Horizontal', 8, 'Left', 'Center'),
      label('SortLabel', 'SORT:', { size: px(56, 38), ts: 16, font: 'Fredoka', color: INK, stroke: 0, lo: 0 }),
      sortBtn('Value', 'VALUE', 1), sortBtn('Income', '$/SEC', 2), sortBtn('World', 'WORLD', 3), sortBtn('Name', 'NAME', 4),
      btn('SelectAll', 'index', 'ALL', { size: px(80, 38), ts: 15, lo: 5, attrs: { Action: 'SellSelectAll' } }),
      btn('SelectNone', 'red', 'NONE', { size: px(80, 38), ts: 15, lo: 6, attrs: { Action: 'SellSelectNone' } })),
    scroll('Grid', { pos: U2(0, 8, 0, 54), size: U2(1, -16, 1, -128), bar: th.lo }, padding(8, 6, 10, 6), gridLayout(104, 164, 8, 10, 'Center')),
    emptyState('Nothing to sell yet.', 'icon_moneybag'),
    box('BottomBar', { pos: U2(0, 12, 1, -10), anchor: [0, 1], size: U2(1, -24, 0, 62), bg: INK, bgT: 0.1, r: 16 },
      img('Icon', 'icon_moneybag', { pos: U2(0, 6, 0.5, 0), anchor: [0, 0.5], size: px(50, 50) }),
      label('Count', '0 selected', { pos: U2(0, 62, 0, 6), size: px(240, 20), ts: 15, xa: 'Left', font: 'Fredoka', color: '#A6F2FF', stroke: 1.5 }),
      label('Total', '$0', { pos: U2(0, 62, 0, 24), size: px(300, 32), ts: 30, xa: 'Left', stroke: 3, grad: ['#FFFFFF', th.hi] }),
      chunky('SellButton', { theme: 'cash', size: px(200, 52), pos: U2(1, -6, 0.5, -2), anchor: [1, 0.5], r: 14, lip: 6, label: 'SELL', ts: 26, icon: 'icon_cash', iconSize: 36, attrs: { Action: 'SellSelected' } })),
    folder('Templates', sellCard()),
  ];
  return M.menuWindow('Sell', th, 'SELL', 'icon_moneybag', body, {
    headerExtra: label('Sub', 'Final value is calculated by the server', { pos: U2(0, 108, 0, 64), size: px(420, 18), ts: 15, xa: 'Left', font: 'Fredoka', stroke: 2, z: 5 }),
  });
}

// ================================================================ SHOP (Robux; nil ids -> "Coming soon")
function shopCard() {
  return box('ShopCard', { size: px(160, 200) },
    box('Lip', { size: U2(1, 0, 1, 0), bg: C.shop.lip, r: 16, z: 1 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -6), bg: '#FFFFFF', r: 16, z: 2, grad: [[0, C.shop.hi], [0.5, C.shop.base], [1, C.shop.lo]] },
      img('Pattern', 'pattern_dots', { tile: 40, imgT: 0.85, r: 16 }), gloss({ r: 12, a: 0.5, h: 0.3 })),
    img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0, 52), anchor: [0.5, 0.5], size: px(120, 120), imgT: 0.4, z: 3 }),
    img('Icon', 'icon_cash', { pos: U2(0.5, 0, 0, 52), anchor: [0.5, 0.5], size: px(80, 80), z: 4, attrs: { Bob: true } }),
    label('Title', 'ITEM', { pos: U2(0, 6, 0, 98), size: U2(1, -12, 0, 26), ts: 20, stroke: 2.5, z: 4, maxTs: 20 }),
    label('Desc', '', { pos: U2(0, 6, 0, 122), size: U2(1, -12, 0, 18), ts: 13, font: 'Fredoka', stroke: 1.5, z: 4 }),
    chunky('BuyButton', { theme: 'upgrade', size: U2(1, -14, 0, 44), pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], r: 12, lip: 6, label: 'COMING SOON', ts: 16, z: 5 }),
  );
}
function shopMenu() {
  const th = C.shop;
  const body = [
    scroll('Grid', { pos: U2(0, 8, 0, 8), size: U2(1, -16, 1, -16), bar: th.lo }, padding(10, 8, 12, 8), gridLayout(160, 200, 10, 12, 'Center')),
    folder('Templates', shopCard()),
  ];
  return M.menuWindow('Shop', th, 'SHOP', 'icon_shop', body);
}

// ========================================================= HATCH REVEAL (real model)
function hatchReveal() {
  return box('HatchReveal', { size: U2(1, 0, 1, 0), bg: INK, bgT: 0.25, visible: false, z: 20, attrs: { Layer: 'Overlay' } },
    box('Center', { anchor: [0.5, 0.5], pos: U2(0.5, 0, 0.5, 0), size: px(560, 560) },
      scaleMod(),
      img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.45, 0), anchor: [0.5, 0.5], size: px(620, 620), imgT: 0.3, attrs: { Spin: 18 } }),
      img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0.45, 0), anchor: [0.5, 0.5], size: px(420, 420), imgT: 0.2 }),
      viewport('Model', { size: px(380, 380), pos: U2(0.5, 0, 0.42, 0), anchor: [0.5, 0.5], z: 3, kind: 'Reveal' }),
      tag('NewTag', 'NEW DISCOVERY!', { theme: 'red', pos: U2(0.5, 0, 0, 8), anchor: [0.5, 0], w: 200, h: 34, ts: 20, rot: -4, visible: false }),
      tag('BossTag', 'BOSS', { theme: 'gold', pos: U2(0.5, 110, 0, 50), anchor: [0.5, 0], w: 70, h: 26, ts: 16, rot: 8, visible: false }),
      label('Name', 'CHARACTER', { pos: U2(0.5, 0, 1, -140), anchor: [0.5, 0], size: px(560, 56), ts: 50, stroke: 5, grad: ['#FFFFFF', '#FFF3A6', '#FFC21F'] }),
      label('World', 'WORLD', { pos: U2(0.5, 0, 1, -86), anchor: [0.5, 0], size: px(560, 24), ts: 20, font: 'Fredoka', color: '#A6F2FF', stroke: 2 }),
      btn('ContinueButton', 'upgrade', 'AWESOME!', { size: px(220, 56), pos: U2(0.5, 0, 1, -4), anchor: [0.5, 1], ts: 26, attrs: { Action: 'CloseReveal' } })));
}

// ================================================================ TOASTS
function toasts() {
  const t = box('Toast', { size: px(420, 44), bg: '#FFFFFF', r: 'pill', grad: [C.slate.base, C.slate.lip] },
    stroke(3, INK), label('Text', '', { pos: U2(0, 16, 0, 0), size: U2(1, -32, 1, 0), ts: 18, font: 'Fredoka', stroke: 2 }));
  return box('Toasts', { anchor: [0.5, 0], pos: U2(0.5, 0, 0, 84), size: px(440, 220), attrs: { Layer: 'HUD' } },
    scaleMod(), list('Vertical', 6, 'Center', 'Top'), folder('Templates', t));
}

// ============================================================ DEV PANEL (Studio / whitelist only)
function devPanel() {
  const cmds = [['cash', '+$1M', 1000000], ['speed', '+1K SPD', 1000], ['grantEgg', 'GIVE EGG', 'random'], ['hatchNow', 'HATCH NOW', ''], ['skipPhase', 'SKIP PHASE', ''], ['wipe', 'RESET DATA', '']];
  return box('DevPanel', { anchor: [1, 0], pos: U2(1, -10, 0, 90), size: px(160, 44 + cmds.length * 40), bg: '#000000', bgT: 0.35, r: 12, visible: false, attrs: { Layer: 'Dev', DevOnly: true } },
    label('Title', 'DEV (Studio only)', { pos: U2(0, 0, 0, 6), size: U2(1, 0, 0, 24), ts: 14, font: 'Fredoka', stroke: 1.5, color: '#FFD23F' }),
    box('Buttons', { pos: U2(0, 8, 0, 34), size: U2(1, -16, 1, -40) }, list('Vertical', 6, 'Center', 'Top'),
      ...cmds.map(([c, t, arg], i) => btn(`Dev_${c}`, i === cmds.length - 1 ? 'red' : 'slate', t, { size: U2(1, 0, 0, 34), ts: 15, lip: 4, lo: i, attrs: { DevCmd: c, DevArg: String(arg) } }))));
}

function build() {
  const top = [hud(), roundTimer(), hatchWidget(), carry(), toasts(), HUD.backdrop(), nav(),
    shopMenu(), indexMenu(), eggsMenu(), charactersMenu(), upgradeMenu(), trailShopMenu(), sellMenu(), hatchReveal(), devPanel()];
  // Speed/Cash "+" buttons → Shop
  (function fix(x) { if (x.attrs && /^Buy(Speed|Cash)$/.test(x.attrs.Action || '')) x.attrs.Action = 'OpenShop'; x.children.forEach(fix); })({ children: top, attrs: {} });
  return top;
}
module.exports = { build };
