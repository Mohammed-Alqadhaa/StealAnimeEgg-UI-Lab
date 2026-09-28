// Menus: Shop, Index, Eggs, Characters, Upgrade. All built from real Roblox
// GUI instances. Content is populated from SAMPLE data (tools/sample-data.js);
// the PREVIEW controller toggles the pre-built state frames at runtime.
const { I, U2, px, UD, E } = require('../lib/rbx');
const { INK, C, RARITY } = require('../lib/theme');
const K = require('../lib/components');
const { box, label, img, chunky, chunkyFaces, badge, tag, progress, statRow, stroke, grad, list, gridLayout, padding, scaleMod, pattern, gloss, priceContent } = K;

const W = 760; const H = 520;

// -------------------------------------------------------------- window
function menuWindow(id, th, title, icon, body, o = {}) {
  return box(`${id}Menu`, { anchor: [0.5, 0.5], pos: U2(0.5, 0, 0.5, 4), size: px(W, H), visible: false, attrs: { Layer: 'Menu', Menu: id } },
    scaleMod(),
    box('DropShadow', { pos: U2(0, 0, 0, 10), size: U2(1, 0, 1, 0), bg: INK, bgT: 0.3, r: 30 }),
    box('Rim', { size: U2(1, 0, 1, 0), bg: '#FFFFFF', r: 30, grad: [[0, th.hi], [0.3, th.base], [1, th.lo]] },
      stroke(4.5, INK),
      img('RimPattern', 'pattern_dots', { tile: 40, imgT: 0.82, r: 30 }),
      box('RimGloss', { pos: U2(0, 16, 0, 6), size: U2(1, -32, 0, 30), bg: '#FFFFFF', r: 'pill', grad: ['#FFFFFF', '#FFFFFF'], gradT: [[0, 0.45], [1, 0.95]] }),
      ...[[0, 0], [1, 0], [0, 1], [1, 1]].map(([x, y], i) => img(`Rivet${i + 1}`, 'deco_rivet', {
        pos: U2(x, x ? -9 : 9, y, y ? -9 : 9), anchor: [x, y], size: px(20, 20), z: 3,
      })),
      box('Body', { pos: U2(0, 14, 0, 84), size: U2(1, -28, 1, -98), bg: th.body, r: 20 },
        stroke(3.5, th.lip),
        img('BodyPattern', 'pattern_tiles', { tile: 56, imgT: 0.9, color: th.base, r: 20 }),
        box('TopShade', { size: U2(1, 0, 0, 20), bg: '#000000', r: 20, grad: ['#000000', '#000000'], gradT: [[0, 0.82], [1, 1]] }),
        box('Content', { size: U2(1, 0, 1, 0) }, ...body)),
    ),
    // header
    box('TitleBadge', { pos: U2(0, -30, 0, -38), size: px(128, 128), z: 5 },
      img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(170, 170), imgT: 0.25, color: th.hi }),
      img('Icon', icon, { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(120, 120), rot: -10, attrs: { Bob: true } })),
    label('Title', title, { pos: U2(0, 104, 0, 12), size: px(420, 64), ts: 54, xa: 'Left', stroke: 5, grad: ['#FFFFFF', '#FFFFFF', th.hi], z: 5 }),
    o.headerExtra || null,
    chunky('CloseButton', { theme: 'red', size: px(62, 62), pos: U2(1, 14, 0, -14), anchor: [1, 0], r: 18, lip: 7, sw: 3.5, icon: 'icon_close', iconSize: 30, z: 6, attrs: { Action: 'CloseMenu' } }),
  );
}

// white "info chip" used in top bars
function chip(name, o, ...kids) {
  return box(name, { size: o.size, pos: o.pos, anchor: o.anchor, lo: o.lo, bg: o.bg || '#FFFFFF', r: o.r ?? 14 },
    stroke(3, o.strokeColor || INK), ...kids);
}
function sectionHeader(name, icon, text, th, lo) {
  return box(name, { size: U2(1, 0, 0, 44), lo },
    img('Icon', icon, { size: px(46, 46), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5], rot: -8 }),
    label('Text', text, { pos: U2(0, 54, 0, 0), size: U2(0, 0, 1, 0), auto: 'X', ts: 30, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', th.hi] }),
    box('Line', { pos: U2(0, 54, 1, -4), size: U2(1, -60, 0, 4), bg: th.base, bgT: 0.4, r: 'pill' }));
}
// rarity-coloured face used by collectible cards
function rarityFaces(R, o = {}) {
  const colors = R.rainbow ? R.rainbow.map((c, i) => [i / (R.rainbow.length - 1), c]) : [[0, R.hi], [0.5, R.base], [1, R.lo]];
  const r = o.r ?? 16;
  return [
    box('Lip', { size: U2(1, 0, 1, 0), bg: R.lip, r, z: 1 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -6), bg: '#FFFFFF', r, z: 2, grad: colors, gradRot: R.rainbow ? 45 : 90 },
      stroke(2, '#FFFFFF', { name: 'InnerRim', t: 0.55 }),
      img('Pattern', 'pattern_stars', { tile: 64, imgT: 0.72, r }),
      gloss({ r: r - 4, a: 0.5, h: 0.32 })),
  ];
}
function portraitWell(art, R, o = {}) {
  return box('PortraitWell', { pos: o.pos || U2(0.5, 0, 0, 28), anchor: [0.5, 0], size: o.size || U2(1, -16, 0, 118), bg: o.dark ? '#5B5390' : R.lip, bgT: o.dark ? 0 : 0.45, r: 12, z: 3, clip: false },
    stroke(2.5, INK, { t: 0.2 }),
    img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(180, 180), imgT: o.dark ? 0.8 : 0.55, attrs: { Spin: 14 } }),
    img('Portrait', art, { pos: U2(0.5, 0, 1, -2), anchor: [0.5, 1], size: px(o.ps || 128, o.ps || 128), color: o.dark ? '#000000' : undefined, attrs: { Silhouette: !!o.dark } }));
}

// ============================================================== INDEX
function indexCard(id, ch, discovered, lo) {
  const R = RARITY[ch.rarity];
  const LOCK = { ...C.slate, hi: '#6E6699', base: '#443D6B', lo: '#2A2447', lip: '#16122B' };
  const unlocked = box('Unlocked', { size: U2(1, 0, 1, 0), visible: discovered },
    ...rarityFaces(R),
    box('RarityTag', { pos: U2(0.5, 0, 0, 6), anchor: [0.5, 0], size: px(104, 20), bg: R.lip, r: 'pill', z: 4 }, stroke(2, INK),
      label('Text', R.label, { ts: 13, font: 'Fredoka', stroke: 1.5 })),
    portraitWell(ch.art, R),
    box('NamePlate', { pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], size: U2(1, -14, 0, 42), bg: INK, bgT: 0.1, r: 12, z: 4 },
      label('Name', ch.name.toUpperCase(), { ts: 22, stroke: 2.5, grad: ['#FFFFFF', R.hi] })),
  );
  const locked = box('Locked', { size: U2(1, 0, 1, 0), visible: !discovered },
    box('Lip', { size: U2(1, 0, 1, 0), bg: LOCK.lip, r: 16, z: 1 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -6), bg: '#FFFFFF', r: 16, z: 2, grad: [LOCK.hi, LOCK.base, LOCK.lo] },
      img('Pattern', 'pattern_diagonal', { tile: 36, imgT: 0.93, r: 16 })),
    box('RarityTag', { pos: U2(0.5, 0, 0, 6), anchor: [0.5, 0], size: px(104, 20), bg: '#16122B', r: 'pill', z: 4 }, stroke(2, INK),
      label('Text', R.label, { ts: 13, font: 'Fredoka', stroke: 1.5, color: '#A9A3D1' })),
    portraitWell(ch.art, R, { dark: true }),
    box('NamePlate', { pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], size: U2(1, -14, 0, 42), bg: '#0B0718', bgT: 0.2, r: 12, z: 4 },
      label('Name', '???', { ts: 26, stroke: 2.5, color: '#8C84C2' })),
    box('LockBadge', { pos: U2(1, 6, 0, -6), anchor: [1, 0], size: px(40, 40), bg: '#FFFFFF', r: 'pill', z: 6, grad: ['#4A4275', '#1B1036'] },
      stroke(3, INK), img('Icon', 'icon_lock', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(28, 28) })),
  );
  return box(`Card_${id}`, { lo, attrs: { CharId: id } }, unlocked, locked,
    tag('NewTag', 'NEW!', { theme: 'red', pos: U2(0, -8, 0, -8), w: 50, h: 22, rot: -10, ts: 14, visible: false }));
}
function indexMenu(D) {
  const th = C.index;
  const n = D.index.discovered.length; const total = D.index.order.length;
  const body = [
    box('CollectionHeader', { pos: U2(0, 12, 0, 12), size: U2(1, -24, 0, 86), bg: '#FFFFFF', r: 18, grad: [[0, '#FF7A6B'], [0.5, '#E8321E'], [1, '#8E0E2E']] },
      stroke(3.5, INK),
      img('Pattern', 'pattern_diagonal', { tile: 40, imgT: 0.9, r: 18 }),
      gloss({ r: 14, a: 0.5, h: 0.4 }),
      box('Emblem', { pos: U2(0, 10, 0.5, 0), anchor: [0, 0.5], size: px(72, 72), bg: '#FFFFFF', r: 'pill', grad: ['#1FAE6A', '#16223A'] },
        stroke(3.5, INK),
        img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(110, 110), imgT: 0.5, attrs: { Spin: 20 } }),
        img('Egg', 'egg_demon', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(64, 64) })),
      label('Series', D.index.series.toUpperCase(), { pos: U2(0, 94, 0, 10), size: px(300, 38), ts: 36, xa: 'Left', stroke: 4, grad: ['#FFFFFF', '#FFE3C2'] }),
      label('Discovered', `${n} / ${total} Discovered`, { pos: U2(0, 96, 0, 48), size: px(260, 26), ts: 20, xa: 'Left', font: 'Fredoka', stroke: 2.5, color: '#FFF3A6' }),
      progress('Progress', { pos: U2(1, -80, 0.5, -2), anchor: [1, 0.5], size: px(250, 32), theme: 'gold', value: n / total, text: `${Math.round((n / total) * 100)}%`, h: 32 }),
      box('Reward', { pos: U2(1, -12, 0.5, -2), anchor: [1, 0.5], size: px(60, 60), bg: '#FFFFFF', r: 16, grad: [C.gold.hi, C.gold.base, C.gold.lo] },
        stroke(3, INK), img('Icon', 'icon_gift', { pos: U2(0.5, 0, 0.5, -3), anchor: [0.5, 0.5], size: px(52, 52) }),
        label('Text', 'REWARD', { pos: U2(0.5, 0, 1, 2), anchor: [0.5, 0.5], size: px(64, 16), ts: 12, stroke: 2 })),
    ),
    box('Grid', { pos: U2(0, 12, 0, 110), size: U2(1, -24, 0, 236) },
      gridLayout(132, 232, 10, 10, 'Center'),
      ...D.index.order.map((id, i) => indexCard(id, D.characters[id], D.index.discovered.includes(id), i + 1))),
    box('Hint', { pos: U2(0.5, 0, 1, -12), anchor: [0.5, 1], size: U2(1, -24, 0, 46), bg: INK, bgT: 0.15, r: 'pill' },
      stroke(3, th.lip, { t: 0.3 }),
      box('Row', { size: U2(1, 0, 1, 0) }, list('Horizontal', 8, 'Center', 'Center'),
        img('Egg', 'icon_eggs', { size: px(36, 36), lo: 1, rot: -10 }),
        label('Text', 'Hatch <font color="#7CFF5A">Demon Slayer Eggs</font> to discover new characters!', { size: U2(0, 0, 1, 0), auto: 'X', ts: 18, font: 'Fredoka', stroke: 2.5, lo: 2, rich: true }))),
  ];
  return menuWindow('Index', th, 'INDEX', 'icon_index', body);
}

// =============================================================== EGGS
const STATE_THEME = { OWNED: C.white, HATCHING: C.speed, READY: C.gold, OPENED: C.chars };
function eggStateFrame(state, egg, D, visible) {
  const th = STATE_THEME[state];
  const R = RARITY[egg.rarity];
  const faces = chunkyFaces({ theme: th, r: 18, lip: 7, sw: 3.5, pattern: true, patternKey: state === 'OPENED' ? 'pattern_stars' : 'pattern_dots', patternT: 0.84, content: [] });
  const dark = state === 'OWNED';
  const tc = dark ? INK : '#FFFFFF';
  const stageKids = [];
  if (state === 'OPENED') {
    const ch = D.characters[egg.result];
    stageKids.push(
      img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(200, 200), imgT: 0.25, color: RARITY[ch.rarity].hi, attrs: { Spin: 25 } }),
      img('Portrait', ch.art, { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(124, 124) }),
      tag('NewTag', 'NEW!', { theme: 'red', pos: U2(0, -2, 0, 2), w: 52, h: 24, rot: -12, ts: 15 }));
  } else {
    stageKids.push(
      img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(160, 160), imgT: state === 'READY' ? 0 : 0.5, color: state === 'READY' ? '#FFF3A6' : '#FFFFFF' }),
      state !== 'OWNED' ? img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(190, 190), imgT: state === 'READY' ? 0.15 : 0.6, attrs: { Spin: state === 'READY' ? 40 : 12 } }) : null,
      img('Egg', egg.art, { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(112, 112), rot: state === 'READY' ? 8 : 0, attrs: { Wobble: state === 'READY' || state === 'HATCHING' } }),
      state === 'OWNED' ? badge('Count', `x${egg.count || 1}`, { theme: 'eggs', pos: U2(1, -14, 1, -18), w: 46, s: 30, ts: 18 }) : null);
  }
  let action;
  if (state === 'OWNED') {
    action = [
      label('Info', 'Tap HATCH to start the timer', { pos: U2(0, 0, 0, 0), size: U2(1, 0, 0, 20), ts: 15, font: 'Fredoka', color: '#5A5480', stroke: 0, xa: 'Left' }),
      chunky('HatchButton', { theme: 'upgrade', size: U2(1, 0, 0, 52), pos: U2(0, 0, 0, 26), r: 14, lip: 6, icon: 'icon_timer', iconSize: 36, label: 'HATCH', sub: `${D.hatchSeconds}s timer (dev)`, ts: 24, subTs: 13, attrs: { EggAction: 'Hatch', EggId: egg.id } }),
    ];
  } else if (state === 'HATCHING') {
    const rem = egg.remaining ?? 42;
    action = [
      box('TimerRow', { size: U2(1, 0, 0, 34) },
        img('Clock', 'icon_timer', { size: px(32, 32), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] }),
        label('Timer', `0:${String(rem).padStart(2, '0')}`, { pos: U2(0, 38, 0, 0), size: U2(0, 80, 1, 0), ts: 32, xa: 'Left', stroke: 3.5 }),
        label('Caption', 'remaining', { pos: U2(0, 120, 0, 2), size: U2(1, -120, 1, 0), ts: 15, font: 'Fredoka', xa: 'Left', stroke: 2 })),
      progress('Bar', { pos: U2(0, 0, 0, 42), size: U2(1, -74, 0, 28), theme: 'upgrade', value: 1 - rem / D.hatchSeconds, h: 28, text: `${Math.round((1 - rem / D.hatchSeconds) * 100)}%` }),
      chunky('SkipButton', { theme: 'gold', size: px(66, 34), pos: U2(1, 0, 0, 39), anchor: [1, 0], r: 10, lip: 5, content: priceContent('icon_gem', '15', { is: 18, ts: 17 }), attrs: { EggAction: 'Skip', EggId: egg.id } }),
    ];
  } else if (state === 'READY') {
    action = [
      chunky('OpenButton', { theme: 'upgrade', size: U2(1, 0, 0, 60), pos: U2(0, 0, 0, 16), r: 16, lip: 7, icon: 'icon_sparkle', iconSize: 40, label: 'OPEN!', ts: 32, attrs: { EggAction: 'Open', EggId: egg.id, Pulse: true } }),
    ];
  } else {
    const ch = D.characters[egg.result]; const CR = RARITY[ch.rarity];
    action = [
      label('YouGot', 'You got', { size: U2(1, 0, 0, 18), ts: 16, font: 'Fredoka', stroke: 2, xa: 'Left' }),
      label('Result', `${ch.name.toUpperCase()}!`, { pos: U2(0, 0, 0, 16), size: U2(1, 0, 0, 30), ts: 30, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', CR.hi, CR.base] }),
      chunky('CollectButton', { theme: 'index', size: U2(1, 0, 0, 40), pos: U2(0, 0, 0, 48), r: 12, lip: 6, label: 'COLLECT', ts: 22, attrs: { EggAction: 'Collect', EggId: egg.id } }),
    ];
  }
  const stateLabel = { OWNED: 'OWNED', HATCHING: 'HATCHING', READY: 'READY', OPENED: 'OPENED' }[state];
  const pillTheme = { OWNED: 'slate', HATCHING: 'speed', READY: 'upgrade', OPENED: 'chars' }[state];
  return box(`State${state[0]}${state.slice(1).toLowerCase()}`, { size: U2(1, 0, 1, 0), visible },
    ...faces,
    box('Stage', { pos: U2(0, 8, 0.5, -4), anchor: [0, 0.5], size: px(132, 132), bg: dark ? '#FFE9B8' : INK, bgT: dark ? 0 : 0.55, r: 'pill', z: 3 },
      stroke(3, dark ? C.eggs.lip : INK, { t: 0.2 }), ...stageKids),
    box('Info', { pos: U2(0, 152, 0, 12), size: U2(1, -164, 1, -30), z: 4 },
      label('Name', egg.name.toUpperCase(), { size: U2(1, 0, 0, 26), ts: 23, scaled: true, maxTs: 23, xa: 'Left', stroke: dark ? 0 : 3, color: tc }),
      box('Pills', { pos: U2(0, 0, 0, 28), size: U2(1, 0, 0, 22) }, list('Horizontal', 6, 'Left', 'Center'),
        box('StatePill', { size: U2(0, 0, 1, 0), auto: 'X', bg: '#FFFFFF', r: 'pill', grad: [C[pillTheme].hi, C[pillTheme].lo], lo: 1 }, stroke(2.5, INK), padding(0, 10),
          label('Text', stateLabel, { size: U2(0, 0, 1, 0), auto: 'X', ts: 14, stroke: 2 })),
        box('RarityPill', { size: U2(0, 0, 1, 0), auto: 'X', bg: R.lip, r: 'pill', lo: 2 }, stroke(2.5, INK), padding(0, 10),
          label('Text', R.label, { size: U2(0, 0, 1, 0), auto: 'X', ts: 13, font: 'Fredoka', stroke: 1.5 }))),
      box('Action', { pos: U2(0, 0, 0, 56), size: U2(1, 0, 1, -56) }, ...action)),
  );
}
function eggCard(egg, D, i) {
  const states = ['OWNED', 'HATCHING', 'READY', 'OPENED'];
  return box(`EggCard_${egg.id}`, { lo: i, attrs: { EggId: egg.id, PreviewState: egg.state } },
    ...states.map((s) => eggStateFrame(s, egg, D, s === egg.state)));
}
function eggsMenu(D) {
  const th = C.eggs;
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 12), size: U2(1, -24, 0, 56) },
      chip('Storage', { size: px(210, 50), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_eggs', { pos: U2(0, -6, 0.5, 0), anchor: [0, 0.5], size: px(54, 54), rot: -10 }),
        label('Caption', 'STORAGE', { pos: U2(0, 52, 0, 4), size: px(150, 16), ts: 14, font: 'Fredoka', color: th.text, stroke: 0, xa: 'Left' }),
        label('Value', `${D.eggStorage.used} / ${D.eggStorage.max}`, { pos: U2(0, 52, 0, 18), size: px(150, 28), ts: 26, xa: 'Left', stroke: 3 })),
      chip('HatchTime', { size: px(230, 50), pos: U2(0, 222, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_hourglass', { pos: U2(0, 4, 0.5, 0), anchor: [0, 0.5], size: px(40, 40) }),
        label('Caption', 'HATCH TIME', { pos: U2(0, 50, 0, 4), size: px(170, 16), ts: 14, font: 'Fredoka', color: th.text, stroke: 0, xa: 'Left' }),
        label('Value', `${D.hatchSeconds}s (dev timer)`, { pos: U2(0, 50, 0, 18), size: px(170, 28), ts: 22, xa: 'Left', stroke: 3 })),
      chunky('HatchAllButton', { theme: 'gold', size: px(236, 56), pos: U2(1, 0, 0.5, 0), anchor: [1, 0.5], r: 16, lip: 7, sw: 3.5,
        content: [
          img('Icon', 'icon_skip', { pos: U2(0, 10, 0.5, 0), anchor: [0, 0.5], size: px(34, 34) }),
          label('Label', 'HATCH ALL', { pos: U2(0, 50, 0, 0), size: px(110, 49), ts: 22, xa: 'Left', stroke: 3 }),
          box('Price', { pos: U2(1, -8, 0.5, 0), anchor: [1, 0.5], size: px(70, 32), bg: INK, bgT: 0.35, r: 'pill' }, ...priceContent('icon_gem', '199', { is: 20, ts: 18 })),
        ], attrs: { EggAction: 'HatchAll' } })),
    box('Grid', { pos: U2(0, 12, 0, 80), size: U2(1, -24, 1, -92) },
      gridLayout(348, 160, 12, 12, 'Center'),
      ...D.eggs.map((e, i) => eggCard(e, D, i + 1))),
  ];
  return menuWindow('Eggs', th, 'EGGS', 'icon_eggs', body);
}

// ========================================================== CHARACTERS
function unitCard(u, D, lo) {
  const ch = D.characters[u.char]; const R = RARITY[ch.rarity];
  return box(`Unit_${u.id}`, { lo, attrs: { UnitId: u.id, Income: u.income } },
    box('EquippedRing', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: U2(1, 10, 1, 10), r: 20, bg: '#7CFF5A', bgT: 0.55, visible: u.equipped, z: 0 }, stroke(4, '#7CFF5A')),
    ...rarityFaces(R),
    portraitWell(ch.art, R, { pos: U2(0.5, 0, 0, 8), size: U2(1, -14, 0, 104), ps: 116 }),
    box('LevelPill', { pos: U2(0, 4, 0, 4), size: px(50, 22), bg: INK, r: 'pill', z: 5 }, stroke(2, '#FFFFFF', { t: 0.4 }),
      label('Text', `Lv.${u.level}`, { ts: 15, stroke: 0, grad: ['#FFFFFF', '#FFF3A6'] })),
    box('UnitChip', { pos: U2(1, -4, 0, 4), anchor: [1, 0], size: px(36, 22), bg: '#FFFFFF', r: 'pill', z: 5, grad: [C.gold.hi, C.gold.lo] }, stroke(2.5, INK),
      label('Text', `#${u.unit}`, { ts: 16, stroke: 2 })),
    label('Name', ch.name.toUpperCase(), { pos: U2(0, 0, 0, 114), size: U2(1, 0, 0, 24), ts: 21, stroke: 3, grad: ['#FFFFFF', R.hi], z: 4 }),
    box('IncomeRow', { pos: U2(0.5, 0, 0, 138), anchor: [0.5, 0], size: px(110, 22), bg: INK, bgT: 0.35, r: 'pill', z: 4 },
      statRow('Stat', 'icon_cash', `$${u.income}/s`, { is: 22, ts: 17, color: '#C2FFA3', size: U2(1, 0, 1, 0) })),
    chunky('EquipButton', { theme: 'upgrade', size: U2(1, -14, 0, 40), pos: U2(0.5, 0, 1, -8), anchor: [0.5, 1], r: 12, lip: 5, label: 'EQUIP', ts: 21, z: 4, visible: !u.equipped, attrs: { UnitAction: 'Equip', UnitId: u.id } }),
    chunky('UnequipButton', { theme: 'red', size: U2(1, -14, 0, 40), pos: U2(0.5, 0, 1, -8), anchor: [0.5, 1], r: 12, lip: 5, label: 'UNEQUIP', ts: 19, z: 4, visible: u.equipped, attrs: { UnitAction: 'Unequip', UnitId: u.id } }),
    box('EquippedBadge', { pos: U2(1, -2, 0, 86), anchor: [1, 0], size: px(30, 30), z: 7, visible: u.equipped }, img('Icon', 'icon_check', { size: U2(1, 0, 1, 0) })),
  );
}
function charactersMenu(D) {
  const th = C.chars;
  const eq = D.units.filter((u) => u.equipped);
  const income = eq.reduce((s, u) => s + u.income, 0);
  const body = [
    box('TopBar', { pos: U2(0, 12, 0, 12), size: U2(1, -24, 0, 60) },
      chip('Equipped', { size: px(248, 56), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_slots', { pos: U2(0, 6, 0.5, 0), anchor: [0, 0.5], size: px(44, 44) }),
        label('Caption', 'EQUIPPED', { pos: U2(0, 58, 0, 5), size: px(90, 16), ts: 14, font: 'Fredoka', color: th.text, stroke: 0, xa: 'Left' }),
        label('Value', `${eq.length} / ${D.equipSlots}`, { pos: U2(0, 58, 0, 20), size: px(80, 30), ts: 28, xa: 'Left', stroke: 3 }),
        box('Slots', { pos: U2(1, -10, 0.5, 0), anchor: [1, 0.5], size: px(96, 26) }, list('Horizontal', 4, 'Right', 'Center'),
          ...Array.from({ length: D.equipSlots }, (_, i) => box(`Slot${i + 1}`, { size: px(21, 26), bg: i < eq.length ? th.base : '#D9D2F0', r: 6, lo: i }, stroke(2.5, INK))))),
      chip('Income', { size: px(200, 56), pos: U2(0, 260, 0.5, 0), anchor: [0, 0.5] },
        img('Icon', 'icon_cash', { pos: U2(0, 2, 0.5, 0), anchor: [0, 0.5], size: px(50, 50) }),
        label('Caption', 'TOTAL INCOME', { pos: U2(0, 56, 0, 5), size: px(130, 16), ts: 14, font: 'Fredoka', color: C.cash.text, stroke: 0, xa: 'Left' }),
        label('Value', `$${income}/s`, { pos: U2(0, 56, 0, 20), size: px(130, 30), ts: 28, xa: 'Left', stroke: 3, grad: ['#FFFFFF', C.cash.hi] })),
      chunky('EquipBestButton', { theme: 'gold', size: px(228, 60), pos: U2(1, 0, 0.5, 0), anchor: [1, 0.5], r: 16, lip: 7, sw: 3.5, icon: 'icon_equip_best', iconSize: 46, label: 'EQUIP BEST', sub: 'highest $/sec', ts: 24, subTs: 13, attrs: { UnitAction: 'EquipBest' } })),
    I('ScrollingFrame', {
      Name: 'Grid', Position: U2(0, 8, 0, 82), Size: U2(1, -16, 1, -90), BackgroundTransparency: 1, BorderSizePixel: 0,
      CanvasSize: U2(0, 0, 0, 0), AutomaticCanvasSize: E('Y'), ScrollingDirection: E('Y'), ScrollBarThickness: 8,
      ScrollBarImageColor3: K.gprops({ bg: th.lo }).BackgroundColor3, ElasticBehavior: E('WhenScrollable'),
    }, padding(12, 8, 12, 8), gridLayout(130, 222, 10, 14, 'Center'),
    ...D.units.map((u, i) => unitCard(u, D, i + 1))),
  ];
  return menuWindow('Characters', th, 'CHARACTERS', 'icon_characters', body);
}

// ============================================================ UPGRADE
function tabButton(id, icon, text, active, lo) {
  const mk = (theme) => chunkyFaces({ theme, r: 14, lip: 6, sw: 3.5, icon, iconSize: 42, label: text, ts: 22, iconX: 6 });
  return I('TextButton', { ...K.gprops({ name: `Tab_${id}`, size: px(222, 56), lo }), Text: '', AutoButtonColor: false, $attrs: { Tab: id, Chunky: true, LipDepth: 6 } },
    scaleMod(1, 'PressScale'),
    box('Active', { size: U2(1, 0, 1, 0), visible: active }, ...mk('gold')),
    box('Inactive', { size: U2(1, 0, 1, 0), visible: !active }, ...mk('slate')));
}
function levelPips(name, level, max, th, o = {}) {
  return box(name, { pos: o.pos, size: o.size || px(max * 14, 12), anchor: o.anchor },
    list('Horizontal', 3, 'Left', 'Center'),
    ...Array.from({ length: max }, (_, i) => box(`Pip${i + 1}`, { size: px(o.w || 11, o.h || 12), lo: i, bg: i < level ? th.base : '#D6D9EA', r: 4 }, stroke(1.5, INK, { t: i < level ? 0 : 0.5 }))));
}
function upgradeRow(row, D, lo) {
  const u = D.units.find((x) => x.id === row.unit); const ch = D.characters[u.char]; const R = RARITY[ch.rarity];
  const maxed = row.level >= D.upgrade.maxLevel;
  return box(`Row_${row.unit}`, { size: U2(1, 0, 0, 92), lo, attrs: { UnitId: row.unit, Level: row.level } },
    box('Lip', { size: U2(1, 0, 1, 0), bg: '#C9CCE0', r: 18 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -5), bg: '#FFFFFF', r: 18, grad: ['#FFFFFF', '#F3F4FB'] },
      box('RarityStrip', { size: U2(0, 14, 1, 0), bg: R.base, r: 8 })),
    box('Tile', { pos: U2(0, 10, 0.5, -3), anchor: [0, 0.5], size: px(72, 72), bg: '#FFFFFF', r: 14, grad: R.rainbow || [R.hi, R.base, R.lo], z: 3 }, stroke(3, INK),
      img('Pattern', 'pattern_stars', { tile: 48, imgT: 0.7, r: 14 }),
      img('Portrait', ch.art, { pos: U2(0.5, 0, 1, 0), anchor: [0.5, 1], size: px(84, 84) })),
    label('Name', ch.name.toUpperCase(), { pos: U2(0, 94, 0, 8), size: px(170, 28), ts: 25, xa: 'Left', stroke: 3, grad: [R.hi, R.base], z: 3 }),
    box('UnitChip', { pos: U2(0, 94 + ch.name.length * 16 + 10, 0, 12), size: px(34, 20), bg: '#FFFFFF', r: 'pill', grad: [C.gold.hi, C.gold.lo], z: 3 }, stroke(2, INK), label('Text', `#${u.unit}`, { ts: 14, stroke: 1.5 })),
    label('Level', `Lv.${row.level}`, { pos: U2(0, 94, 0, 38), size: px(56, 20), ts: 18, xa: 'Left', stroke: 0, color: INK, z: 3 }),
    levelPips('Pips', row.level, D.upgrade.maxLevel, R, { pos: U2(0, 150, 0, 42) }),
    box('Income', { pos: U2(0, 94, 0, 62), size: px(300, 22), z: 3 }, list('Horizontal', 6, 'Left', 'Center'),
      img('Cash', 'icon_cash', { size: px(24, 24), lo: 1 }),
      label('Current', `$${row.income}/s`, { size: U2(0, 0, 1, 0), auto: 'X', ts: 19, stroke: 0, color: '#3A3F63', lo: 2 }),
      img('Arrow', 'icon_arrow', { size: px(20, 16), lo: 3, visible: !maxed }),
      label('Next', row.next ? `$${row.next}/s` : '', { size: U2(0, 0, 1, 0), auto: 'X', ts: 19, stroke: 0, color: '#15A34A', lo: 4, visible: !maxed })),
    chunky('UpgradeButton', { theme: 'upgrade', size: px(178, 66), pos: U2(1, -12, 0.5, -3), anchor: [1, 0.5], r: 16, lip: 7, sw: 3.5, visible: !maxed, z: 4,
      content: [
        label('Label', 'UPGRADE', { pos: U2(0, 0, 0, 6), size: U2(1, 0, 0, 26), ts: 24, stroke: 3 }),
        box('Price', { pos: U2(0.5, 0, 0, 32), anchor: [0.5, 0], size: px(120, 22) }, statRow('Cost', 'icon_cash', row.cost || '', { is: 22, ts: 19, size: U2(1, 0, 1, 0) })),
      ], attrs: { UpgradeAction: 'Character', UnitId: row.unit } }),
    chunky('MaxLevelButton', { theme: 'slate', size: px(178, 66), pos: U2(1, -12, 0.5, -3), anchor: [1, 0.5], r: 16, lip: 7, sw: 3.5, visible: maxed, z: 4, icon: 'icon_star', iconSize: 36, label: 'MAX LEVEL', ts: 21, attrs: { Disabled: true } }),
  );
}
function statCard(name, caption, from, to, th, o = {}) {
  return box(name, { pos: o.pos, size: o.size || U2(1, 0, 0, 86), bg: '#FFFFFF', r: 16 }, stroke(3, INK),
    box('Header', { size: U2(1, 0, 0, 26), bg: th.base, r: 16, grad: [th.hi, th.base] },
      box('Square', { pos: U2(0, 0, 1, -10), size: U2(1, 0, 0, 10), bg: th.base }),
      label('Caption', caption, { ts: 16, stroke: 2 })),
    box('Values', { pos: U2(0, 0, 0, 28), size: U2(1, 0, 1, -28) }, list('Horizontal', 12, 'Center', 'Center'),
      label('From', from, { size: U2(0, 0, 1, 0), auto: 'X', ts: 30, stroke: 0, color: '#3A3F63', lo: 1 }),
      img('Arrow', 'icon_arrow', { size: px(34, 26), lo: 2 }),
      label('To', to, { size: U2(0, 0, 1, 0), auto: 'X', ts: 34, stroke: 3, grad: ['#FFFFFF', th.hi, th.base], lo: 3 })));
}
function showcasePage(name, icon, title, th, lvl, max, statA, extra, cost, visible) {
  return box(name, { size: U2(1, 0, 1, 0), visible },
    box('Showcase', { pos: U2(0, 12, 0, 8), size: px(270, 312), bg: '#FFFFFF', r: 22, grad: [[0, th.hi], [0.5, th.base], [1, th.lo]] },
      stroke(4, INK),
      img('Pattern', 'pattern_dots', { tile: 40, imgT: 0.8, r: 22 }),
      img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.45, 0), anchor: [0.5, 0.5], size: px(380, 380), imgT: 0.45, attrs: { Spin: 10 } }),
      img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0.45, 0), anchor: [0.5, 0.5], size: px(240, 240), imgT: 0.3 }),
      img('Icon', icon, { pos: U2(0.5, 0, 0.45, 0), anchor: [0.5, 0.5], size: px(210, 210), attrs: { Bob: true } }),
      box('LevelRibbon', { pos: U2(0.5, 0, 1, -14), anchor: [0.5, 1], size: px(170, 44), bg: '#FFFFFF', r: 12, grad: [C.gold.hi, C.gold.base, C.gold.lo] },
        stroke(3.5, INK), label('Text', `LEVEL ${lvl}`, { ts: 28, stroke: 3 }))),
    box('Info', { pos: U2(0, 298, 0, 8), size: U2(1, -310, 0, 312) },
      label('Title', title, { size: U2(1, 0, 0, 44), ts: 42, xa: 'Left', stroke: 4, grad: ['#FFFFFF', th.hi, th.base] }),
      progress('LevelBar', { pos: U2(0, 0, 0, 50), size: U2(1, 0, 0, 30), theme: th === C.speed ? 'speed' : 'eggs', value: lvl / max, h: 30, text: `Level ${lvl} / ${max}` }),
      statA,
      extra,
      chunky('UpgradeButton', { theme: 'upgrade', size: U2(1, 0, 0, 72), pos: U2(0, 0, 1, 0), anchor: [0, 1], r: 18, lip: 8, sw: 3.5,
        content: [
          img('Icon', 'icon_upgrade', { pos: U2(0, 10, 0.5, 0), anchor: [0, 0.5], size: px(52, 52) }),
          label('Label', 'UPGRADE', { pos: U2(0, 70, 0, 0), size: px(160, 64), ts: 32, xa: 'Left', stroke: 3.5 }),
          box('Price', { pos: U2(1, -10, 0.5, 0), anchor: [1, 0.5], size: px(130, 42), bg: INK, bgT: 0.35, r: 'pill' }, ...priceContent('icon_cash', cost, { is: 32, ts: 26 })),
        ], attrs: { UpgradeAction: name.replace('Page', '') } }),
      chunky('MaxLevelButton', { theme: 'slate', size: U2(1, 0, 0, 72), pos: U2(0, 0, 1, 0), anchor: [0, 1], r: 18, lip: 8, sw: 3.5, visible: false, icon: 'icon_star', iconSize: 48, label: 'MAX LEVEL', ts: 30, attrs: { Disabled: true } }),
    ));
}
function upgradeMenu(D) {
  const th = C.upgrade; const U = D.upgrade;
  const slotsViz = box('SlotsRow', { pos: U2(0, 0, 0, 186), size: U2(1, 0, 0, 40) }, list('Horizontal', 6, 'Left', 'Center'),
    ...Array.from({ length: U.farm.nextSlots }, (_, i) => {
      const filled = i < U.farm.slots;
      const ids = ['rengoku', 'muzan', 'akaza', 'tanjiro'];
      return box(`Slot${i + 1}`, { size: px(40, 40), lo: i, bg: filled ? C.chars.base : '#FFFFFF', bgT: filled ? 0 : 0.2, r: 10, grad: filled ? [C.chars.hi, C.chars.lo] : undefined },
        stroke(3, filled ? INK : C.upgrade.lo),
        filled ? img('Portrait', D.characters[ids[i]].art, { size: U2(1, 4, 1, 4), pos: U2(0.5, 0, 1, 0), anchor: [0.5, 1] }) : img('Plus', 'icon_plus', { size: px(20, 20), pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], color: '#1DA53C' }));
    }),
    label('Note', 'NEXT', { size: px(50, 20), lo: 99, ts: 16, stroke: 2, color: '#FFD23F' }));
  const body = [
    box('Tabs', { pos: U2(0, 12, 0, 12), size: U2(1, -24, 0, 58) }, list('Horizontal', 12, 'Center', 'Center'),
      tabButton('Character', 'icon_characters', 'CHARACTER', true, 1),
      tabButton('Treadmill', 'icon_treadmill', 'TREADMILL', false, 2),
      tabButton('Farm', 'icon_farm', 'FARM', false, 3)),
    box('Pages', { pos: U2(0, 0, 0, 80), size: U2(1, 0, 1, -80) },
      I('ScrollingFrame', {
        Name: 'CharacterPage', Size: U2(1, 0, 1, -4), BackgroundTransparency: 1, BorderSizePixel: 0,
        CanvasSize: U2(0, 0, 0, 0), AutomaticCanvasSize: E('Y'), ScrollingDirection: E('Y'), ScrollBarThickness: 8,
      }, padding(6, 16, 12, 12), list('Vertical', 10, 'Center', 'Top'),
      ...U.characters.map((r, i) => upgradeRow(r, D, i + 1))),
      showcasePage('TreadmillPage', 'icon_treadmill', 'TREADMILL', C.speed, U.treadmill.level, U.treadmill.max,
        statCard('SpeedGain', 'SPEED GAIN PER STEP', U.treadmill.gain, U.treadmill.next, C.speed, { pos: U2(0, 0, 0, 92) }),
        label('Hint', 'Faster steps = more Speed while running!', { pos: U2(0, 0, 0, 186), size: U2(1, 0, 0, 22), ts: 16, font: 'Fredoka', stroke: 0, color: '#3A3F63', xa: 'Left' }),
        U.treadmill.cost, false),
      showcasePage('FarmPage', 'icon_farm', 'FARM', C.eggs, U.farm.level, U.farm.max,
        statCard('Slots', 'CHARACTER SLOTS', String(U.farm.slots), String(U.farm.nextSlots), C.chars, { pos: U2(0, 0, 0, 92) }),
        slotsViz, U.farm.cost, false)),
  ];
  return menuWindow('Upgrade', th, 'UPGRADE', 'icon_upgrade', body);
}

// =============================================================== SHOP
function priceButton(name, amount, sub, theme, o = {}) {
  return chunky(name, {
    theme, size: o.size || px(150, 58), pos: o.pos, anchor: o.anchor, lo: o.lo, r: 14, lip: 6, sw: 3.5,
    content: [
      box('Row', { size: U2(1, 0, sub ? 0.62 : 1, 0), pos: U2(0, 0, 0, sub ? 3 : 0) }, list('Horizontal', 4, 'Center', 'Center'),
        img('Icon', 'icon_gem', { size: px(o.is || 26, o.is || 26), lo: 1 }),
        label('Amount', amount, { size: U2(0, 0, 1, 0), auto: 'X', ts: o.ts || 26, lo: 2, stroke: 3 })),
      sub ? label('Sub', sub, { pos: U2(0, 0, 0.6, 0), size: U2(1, 0, 0.4, -2), ts: 14, font: 'Fredoka', stroke: 2 }) : null,
    ],
    extra: o.best ? [tag('BestTag', 'BEST!', { theme: 'gold', pos: U2(1, -26, 0, -12), w: 52, h: 22, rot: 10, ts: 14 })] : [],
    attrs: { Purchase: name, SamplePrice: amount },
  });
}
function dropTile(id, ch, big, lo) {
  const R = RARITY[ch.rarity];
  const s = big ? 74 : 62;
  return box(`Drop_${id}`, { size: px(s, big ? 86 : 74), lo, bg: '#FFFFFF', r: 12, grad: R.rainbow || [R.hi, R.base, R.lo], gradRot: R.rainbow ? 45 : 90 },
    stroke(big ? 4 : 3, big ? '#FFD23F' : INK),
    img('Portrait', ch.art, { pos: U2(0.5, 0, 1, -2), anchor: [0.5, 1], size: px(s + 4, s + 4) }),
    label('Chance', ch.chance, { pos: U2(1, -3, 1, -1), anchor: [1, 1], size: px(50, 22), ts: big ? 24 : 19, xa: 'Right', stroke: 3, color: big ? '#FFD23F' : '#FFFFFF' }),
    big ? label('Rare', 'RARE DROP', { pos: U2(0.5, 0, 0, -12), anchor: [0.5, 0], size: px(90, 16), ts: 14, stroke: 2.5, color: '#FFD23F' }) : null);
}
function packCard(name, th, icon, title, o, ...kids) {
  return box(name, { size: o.size, lo: o.lo },
    box('Lip', { size: U2(1, 0, 1, 0), bg: th.lip, r: 20 }, stroke(4, INK)),
    box('Face', { size: U2(1, 0, 1, -7), bg: '#FFFFFF', r: 20, grad: [[0, th.hi], [0.45, th.base], [1, th.lo]] },
      img('Pattern', o.pattern || 'pattern_diagonal', { tile: 44, imgT: 0.86, r: 20 }),
      gloss({ r: 16, a: 0.45, h: 0.35 }),
      box('IconStage', { pos: o.iconPos || U2(0, 8, 0.5, 0), anchor: [0, 0.5], size: px(o.iconSize || 120, o.iconSize || 120) },
        img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: U2(1.5, 0, 1.5, 0), imgT: 0.45, attrs: { Spin: 16 } }),
        img('Icon', icon, { size: U2(1, 0, 1, 0), attrs: { Bob: true } })),
      title ? label('Title', title, { pos: o.titlePos || U2(0, 136, 0, 12), size: px(o.titleW || 200, 34), ts: o.titleTs || 30, xa: 'Left', stroke: 4, grad: ['#FFFFFF', th.hi] }) : null,
      ...kids));
}
function shopMenu(D) {
  const th = C.shop; const S = D.shop;
  const order = ['tanjiro', 'akaza', 'rengoku', 'muzan', 'yoriichi'];
  const featured = box('Featured', { size: U2(1, 0, 0, 266), lo: 1 },
    box('Outer', { size: U2(1, 0, 1, 0), bg: '#FFFFFF', r: 22, grad: [[0, '#FF6FD8'], [0.45, '#6A2FE0'], [1, '#1A2C8F']], gradRot: 60 },
      stroke(4.5, INK),
      img('Stars', 'pattern_stars', { tile: 72, imgT: 0.45, r: 22 }),
      box('NeonRim', { pos: U2(0, 5, 0, 5), size: U2(1, -10, 1, -10), r: 18 }, stroke(3, '#59E1FF')),
      box('EggStage', { pos: U2(0, 14, 0.5, 6), anchor: [0, 0.5], size: px(196, 196) },
        img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(300, 300), imgT: 0.3, color: '#FFB8F2', attrs: { Spin: 12 } }),
        img('Glow', 'fx_glow', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(220, 220), imgT: 0.35, color: '#B98CFF' }),
        img('Egg', 'egg_anime', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(186, 186), rot: -6, attrs: { Wobble: true } })),
      tag('NewTag', 'NEW!', { theme: 'red', pos: U2(0, 14, 0, 12), w: 68, h: 28, rot: -10, ts: 20 }),
      label('Title', S.featured.name, { pos: U2(0, 214, 0, 10), size: px(360, 50), ts: 50, xa: 'Left', stroke: 5, grad: ['#FF9DE6', '#FFFFFF', '#59E1FF'] }),
      label('Subtitle', 'EXCLUSIVE DEMON SLAYER CHARACTERS', { pos: U2(0, 216, 0, 58), size: px(380, 20), ts: 16, font: 'Fredoka', xa: 'Left', stroke: 2.5, color: '#FFF3A6' }),
      chunky('DetailsButton', { theme: 'night', size: px(106, 34), pos: U2(1, -14, 0, 14), anchor: [1, 0], r: 10, lip: 4, icon: 'icon_info', iconSize: 22, label: 'DETAILS', ts: 16 }),
      box('DropStrip', { pos: U2(0, 214, 0, 86), size: px(460, 88) }, list('Horizontal', 8, 'Left', 'Bottom'),
        ...order.map((id, i) => dropTile(id, D.characters[id], id === 'yoriichi', i + 1))),
      box('Prices', { pos: U2(0, 214, 1, -14), anchor: [0, 1], size: px(490, 60) }, list('Horizontal', 10, 'Left', 'Center'),
        ...S.featured.prices.map((p, i) => priceButton(`Buy${i + 1}`, p.p, p.n, p.best ? 'eggs' : 'upgrade', { size: px(150, 56), lo: i, best: p.best }))),
    ));
  const starter = packCard('StarterPack', C.shop, 'icon_gift', 'STARTER PACK', { size: px(344, 192), lo: 1, titleTs: 26, titleW: 200 },
    box('Contents', { pos: U2(0, 136, 0, 50), size: px(196, 60) }, list('Vertical', 3, 'Left', 'Top'),
      ...[['icon_coin', S.starter.contents[0]], ['icon_bolt', S.starter.contents[1]], ['icon_eggs', S.starter.contents[2]]].map(([ic, t], i) =>
        statRow(`Item${i + 1}`, ic, t, { size: px(190, 19), is: 20, ts: 17, align: 'Left', lo: i }))),
    label('Was', `WAS ${S.starter.was}`, { pos: U2(0, 136, 1, -46), size: px(80, 16), ts: 14, font: 'Fredoka', xa: 'Left', stroke: 2, color: '#FFD0DC' }),
    priceButton('BuyStarter', S.starter.price, null, 'upgrade', { size: px(118, 50), pos: U2(1, -12, 1, -10), anchor: [1, 1] }),
    box('Burst', { pos: U2(0, 84, 0, 2), size: px(62, 62), rot: -12, z: 6 },
      img('Star', 'icon_star', { size: U2(1, 0, 1, 0) }), label('Text', '-70%', { ts: 18, stroke: 2.5, pos: U2(0, 0, 0, 4) })));
  const vip = packCard('VIP', C.night, 'icon_crown', 'VIP', { size: px(344, 192), lo: 2, titleTs: 42, titleW: 120, pattern: 'pattern_stars' },
    box('Perks', { pos: U2(0, 136, 0, 50), size: px(200, 66) }, list('Vertical', 3, 'Left', 'Top'),
      ...S.vip.perks.map((t, i) => statRow(`Perk${i + 1}`, 'icon_check', t, { size: px(200, 20), is: 20, ts: 16, align: 'Left', font: 'Fredoka', lo: i, stroke: 2 }))),
    priceButton('BuyVIP', S.vip.price, null, 'gold', { size: px(118, 50), pos: U2(1, -12, 1, -10), anchor: [1, 1] }));
  const tile = (name, th2, icon, title, sub, price, lo, o = {}) => box(name, { size: px(162, o.h || 196), lo },
    box('Lip', { size: U2(1, 0, 1, 0), bg: th2.lip, r: 18 }, stroke(3.5, INK)),
    box('Face', { size: U2(1, 0, 1, -6), bg: '#FFFFFF', r: 18, grad: [[0, th2.hi], [0.5, th2.base], [1, th2.lo]] },
      img('Pattern', 'pattern_dots', { tile: 36, imgT: 0.82, r: 18 }), gloss({ r: 14, a: 0.45, h: 0.3 }),
      img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0, o.iy || 58), anchor: [0.5, 0.5], size: px(170, 170), imgT: 0.5, attrs: { Spin: 12 } }),
      img('Icon', icon, { pos: U2(0.5, 0, 0, o.iy || 58), anchor: [0.5, 0.5], size: px(o.is || 96, o.is || 96), attrs: { Bob: true } }),
      label('Title', title, { pos: U2(0, 0, 0, o.ty || 108), size: U2(1, 0, 0, 30), ts: o.tts || 28, stroke: 3.5 }),
      sub ? box('SubPill', { pos: U2(0.5, 0, 0, (o.ty || 108) + 30), anchor: [0.5, 0], size: px(84, 20), bg: INK, bgT: 0.3, r: 'pill' }, label('Text', sub, { ts: 13, font: 'Fredoka', stroke: 1.5 })) : null,
      priceButton('Buy', price, null, 'upgrade', { size: U2(1, -16, 0, 44), pos: U2(0.5, 0, 1, -8), anchor: [0.5, 1], ts: 22, is: 22 })),
    o.best ? tag('BestTag', 'BEST VALUE', { theme: 'red', pos: U2(0.5, 0, 0, -12), anchor: [0.5, 0], w: 110, h: 24, ts: 15 }) : null);
  const row = (name, lo, h, ...kids) => box(name, { size: U2(1, 0, 0, h), lo }, list('Horizontal', 12, 'Center', 'Center'), ...kids);
  const body = [I('ScrollingFrame', {
    Name: 'Scroll', Position: U2(0, 4, 0, 4), Size: U2(1, -8, 1, -8), BackgroundTransparency: 1, BorderSizePixel: 0,
    CanvasSize: U2(0, 0, 0, 0), AutomaticCanvasSize: E('Y'), ScrollingDirection: E('Y'), ScrollBarThickness: 8,
  }, padding(14, 14, 16, 10), list('Vertical', 16, 'Center', 'Top'),
  featured,
  row('PacksRow', 2, 196, starter, vip),
  sectionHeader('CashHeader', 'icon_cash', 'CASH PACKS', C.cash, 3),
  row('CashRow', 4, 204, ...S.cash.map((c, i) => tile(`Cash${i + 1}`, C.cash, c.icon, c.amt, null, c.p, i, { is: 76 + i * 8, best: c.best }))),
  sectionHeader('BoostHeader', 'icon_bolt', 'BOOSTS', C.gold, 5),
  row('BoostRow', 6, 204, ...S.boosts.map((b, i) => tile(`Boost${i + 1}`, C[b.theme], b.icon, b.name.toUpperCase(), b.time, b.p, i, { is: 84, tts: 22 }))),
  sectionHeader('SpecialHeader', 'icon_gift', 'SPECIAL PACKS', C.shop, 7),
  row('SpecialRow', 8, 150, ...S.special.map((s, i) => packCard(`Special${i + 1}`, C[s.theme], s.icon, s.name, { size: px(344, 140), lo: i, iconSize: 104, titleTs: 26, titlePos: U2(0, 124, 0, 14) },
    label('Desc', s.desc, { pos: U2(0, 126, 0, 48), size: px(200, 20), ts: 17, font: 'Fredoka', xa: 'Left', stroke: 2 }),
    priceButton('Buy', s.p, null, 'upgrade', { size: px(120, 50), pos: U2(1, -12, 1, -10), anchor: [1, 1] })))),
  )];
  const sampleTag = tag('SampleTag', 'SAMPLE PRICES', { theme: 'slate', pos: U2(0, 290, 0, 26), w: 140, h: 26, rot: -4, ts: 15, z: 6 });
  return menuWindow('Shop', th, 'SHOP', 'icon_shop', body, { headerExtra: sampleTag });
}

function all(D) { return [shopMenu(D), indexMenu(D), eggsMenu(D), charactersMenu(D), upgradeMenu(D)]; }
module.exports = { all };
