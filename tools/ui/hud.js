// HUD layer: Speed + Cash bars, main navigation, hatch timer widget, egg carry.
const { I, U2, px, UD, V2 } = require('../lib/rbx');
const { INK, C } = require('../lib/theme');
const K = require('../lib/components');
const { box, label, img, chunky, badge, tag, progress, stroke, grad, list, scaleMod, pattern, gloss, corner } = K;

// ------------------------------------------------------------ currency bar
function currencyBar(name, th, icon, value, caption, o = {}) {
  return box(name, { size: px(300, 64), pos: o.pos, lo: o.lo },
    // pill
    box('Pill', { pos: U2(0, 34, 0.5, 4), anchor: [0, 0.5], size: U2(1, -34, 0, 50), bg: '#FFFFFF', r: 'pill', grad: [[0, th.base], [1, th.lip]], z: 1 },
      stroke(3.5, INK),
      img('Pattern', 'pattern_diagonal', { tile: 50, imgT: 0.9, r: 'pill' }),
      box('Gloss', { pos: U2(0, 30, 0, 4), size: U2(1, -52, 0.4, 0), bg: '#FFFFFF', r: 'pill', grad: ['#FFFFFF', '#FFFFFF'], gradT: [[0, 0.55], [1, 0.95]] }),
      label('Value', value, { pos: U2(0, 46, 0, 0), size: U2(1, -46, 1, 2), ts: 36, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', th.hi] }),
      o.rate ? label('Rate', o.rate, { pos: U2(1, -46, 0, 0), anchor: [1, 0], size: U2(0, 90, 1, 0), ts: 17, xa: 'Right', font: 'Fredoka', color: th.hi, stroke: 2.5 }) : null,
    ),
    // caption tab
    box('Caption', { pos: U2(0, 62, 0, -1), size: px(o.capW || 64, 20), bg: '#FFFFFF', r: 'pill', grad: [th.lo, th.lip], z: 3 },
      stroke(2.5, INK), label('Text', caption, { ts: 14, font: 'Fredoka', stroke: 2 })),
    // icon badge
    box('IconBadge', { pos: U2(0, 0, 0.5, 4), anchor: [0, 0.5], size: px(70, 70), bg: '#FFFFFF', r: 'pill', grad: ['#FFFFFF', th.hi, th.base], z: 4 },
      stroke(3.5, INK),
      box('Ring', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: U2(1, -10, 1, -10), r: 'pill' }, stroke(3, '#FFFFFF', { t: 0.3 })),
      img('Icon', icon, { pos: U2(0.5, 0, 0.5, -2), anchor: [0.5, 0.5], size: px(78, 78), rot: o.iconRot || 0 })),
    // plus button
    chunky('PlusButton', { theme: 'gold', size: px(40, 40), pos: U2(1, 6, 0.5, 4), anchor: [1, 0.5], r: 10, lip: 5, icon: 'icon_plus', iconSize: 22, z: 5, attrs: { Action: `Buy${name}` } }),
  );
}

function hud(D) {
  return box('HUD', { anchor: [0, 1], pos: U2(0, 18, 1, -18), size: px(310, 140), attrs: { Layer: 'HUD' } },
    scaleMod(),
    currencyBar('Speed', C.speed, 'icon_speed', D.hud.speed, 'SPEED', { pos: U2(0, 0, 0, 0) }),
    currencyBar('Cash', C.cash, 'icon_cash', D.hud.cash, 'CASH', { pos: U2(0, 0, 0, 72), rate: D.hud.income, capW: 56 }),
  );
}

// ------------------------------------------------------------ navigation
const NAV = [
  { id: 'Shop', label: 'SHOP', icon: 'icon_shop', theme: 'shop', badge: ['!', 'red'] },
  { id: 'Index', label: 'INDEX', icon: 'icon_index', theme: 'index', tag: 'NEW' },
  { id: 'Eggs', label: 'EGGS', icon: 'icon_eggs', theme: 'eggs', badge: ['1', 'upgrade'] },
  { id: 'Characters', label: 'CHARACTERS', icon: 'icon_characters', theme: 'chars', badge: ['8', 'chars'] },
  { id: 'Upgrade', label: 'UPGRADE', icon: 'icon_upgrade', theme: 'upgrade', badge: ['!', 'gold'] },
];

function navButton(n, i) {
  const th = C[n.theme];
  const long = n.label.length > 7;
  return chunky(`${n.id}Button`, {
    theme: n.theme, size: px(226, 68), lo: i, r: 16, lip: 7, sw: 3.5,
    attrs: { NavTarget: n.id },
    content: [
      img('Icon', n.icon, { pos: U2(0, -14, 0.5, -6), anchor: [0, 0.5], size: px(82, 82), rot: -6 }),
      label('Label', n.label, { pos: U2(0, 70, 0, 0), size: U2(1, -76, 1, 0), ts: long ? 23 : 31, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', '#FFFFFF', th.hi] }),
    ],
    extra: [
      // selected state (toggled by UIController)
      // selected state (toggled by UIController): bright double ring + glow
      box('SelectedGlow', { pos: U2(0.5, 0, 0.5, -2), anchor: [0.5, 0.5], size: U2(1, 14, 1, 12), r: 22, z: 0, visible: false, bg: '#FFFFFF', bgT: 0.55 },
        stroke(5, '#FFFFFF'),
        box('OuterRing', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: U2(1, 10, 1, 10), r: 26 }, stroke(3, th.lo, { t: 0.1 })),
        img('Sparkle', 'icon_sparkle', { pos: U2(0, -14, 0, -14), size: px(34, 34), attrs: { Spin: 40 } })),
      n.badge ? badge('Badge', n.badge[0], { theme: n.badge[1], pos: U2(1, -6, 0, 4), s: 30, ts: 19 }) : null,
      n.tag ? tag('Badge', n.tag, { theme: 'gold', pos: U2(1, -40, 0, -10), w: 50, h: 22, rot: 8, ts: 14 }) : null,
    ],
  });
}

function nav() {
  return box('Nav', { anchor: [0, 0.5], pos: U2(0, 20, 0.47, 0), size: px(234, 5 * 68 + 4 * 12), attrs: { Layer: 'Nav' } },
    scaleMod(),
    list('Vertical', 12, 'Left', 'Center'),
    ...NAV.map(navButton));
}

// ---------------------------------------------------------- hatch widget
function hatchWidget(D) {
  const egg = D.eggs.find((e) => e.state === 'HATCHING') || D.eggs[0];
  const th = C.eggs;
  return box('HatchTimer', { anchor: [1, 1], pos: U2(1, -18, 1, -22), size: px(250, 150), attrs: { Layer: 'HUD', PreviewState: 'HATCHING' } },
    scaleMod(),
    box('Shadow', { pos: U2(0, 0, 0, 6), size: U2(1, 0, 1, 0), bg: INK, bgT: 0.4, r: 20 }),
    box('Card', { size: U2(1, 0, 1, 0), bg: '#FFFFFF', r: 20, grad: [[0, th.hi], [0.55, th.base], [1, th.lo]] },
      stroke(3.5, INK),
      img('Pattern', 'pattern_dots', { tile: 40, imgT: 0.82, r: 20 }),
      box('Inner', { pos: U2(0, 8, 0, 30), size: U2(1, -16, 1, -38), bg: '#FFF8E6', r: 14 }, stroke(3, th.lip),
        img('Pattern', 'pattern_tiles', { tile: 36, imgT: 0.9, color: th.base, r: 14 })),
    ),
    // title ribbon
    box('TitleRibbon', { pos: U2(0.5, 0, 0, -6), anchor: [0.5, 0], size: px(170, 34), bg: '#FFFFFF', r: 10, grad: [C.eggs.lo, C.eggs.lip], z: 3 },
      stroke(3, INK), label('Title', 'HATCHING', { ts: 22, stroke: 3 })),
    // egg display
    box('EggSlot', { pos: U2(0, 14, 0, 38), size: px(96, 100), z: 2 },
      img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(150, 150), imgT: 0.35, color: '#FFFFFF', attrs: { Spin: 20 } }),
      img('Egg', egg.art, { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(92, 92), attrs: { Wobble: true } }),
    ),
    // HATCHING state
    box('StateHatching', { pos: U2(0, 116, 0, 40), size: U2(1, -128, 0, 96), z: 2 },
      label('EggName', egg.name, { size: U2(1, 0, 0, 20), ts: 16, font: 'Fredoka', color: C.eggs.text, stroke: 0, xa: 'Left' }),
      statRowTimer(`0:${String(egg.remaining ?? 42).padStart(2, '0')}`),
      progress('Bar', { pos: U2(0, 0, 0, 68), size: U2(1, 0, 0, 22), theme: 'speed', value: 1 - (egg.remaining ?? 42) / D.hatchSeconds, h: 22 }),
    ),
    // READY state
    box('StateReady', { pos: U2(0, 116, 0, 40), size: U2(1, -128, 0, 96), z: 2, visible: false },
      label('Ready', 'READY!', { size: U2(1, 0, 0, 40), ts: 36, stroke: 3.5, grad: ['#FFFFFF', '#FFF3A6', '#FFC21F'], attrs: { Pulse: true } }),
      chunky('OpenButton', { theme: 'upgrade', size: U2(1, 0, 0, 46), pos: U2(0, 0, 0, 48), r: 12, label: 'OPEN', ts: 26, attrs: { Action: 'OpenEgg' } }),
    ),
  );
}
function statRowTimer(t) {
  return box('TimerRow', { pos: U2(0, 0, 0, 22), size: U2(1, 0, 0, 40) },
    img('Clock', 'icon_timer', { size: px(36, 36), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5] }),
    label('Timer', t, { pos: U2(0, 42, 0, 0), size: U2(1, -42, 1, 0), ts: 36, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', '#E4F6FF'] }));
}

// -------------------------------------------------------------- egg carry
function eggCarry(D) {
  const egg = D.eggs[2];
  const eggSlot = (th) => box('EggSlot', { pos: U2(0, -10, 0.5, -4), anchor: [0, 0.5], size: px(100, 100), bg: '#FFFFFF', r: 'pill', grad: ['#FFFFFF', th.hi, th.base], z: 4 },
    stroke(4, INK),
    img('Rays', 'fx_rays', { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(130, 130), imgT: 0.3, attrs: { Spin: 30 } }),
    img('Egg', egg.art, { pos: U2(0.5, 0, 0.5, 0), anchor: [0.5, 0.5], size: px(84, 84), attrs: { Wobble: true } }),
    I('ViewportFrame', { Name: 'Egg3D', Size: U2(1, 0, 1, 0), BackgroundTransparency: 1, Visible: false, ZIndex: 5, $attrs: { EggColor: '#FF8A1F', Note: 'Runtime 3D egg (UIController); ImageLabel Egg is the static fallback' } }));
  return box('EggCarry', { anchor: [0.5, 1], pos: U2(0.5, 0, 1, -22), size: px(560, 96), attrs: { Layer: 'HUD', PreviewState: 'UNSAFE' } },
    scaleMod(),
    // ---------------- UNSAFE
    box('Unsafe', { size: U2(1, 0, 1, 0) },
      box('Banner', { pos: U2(0, 40, 0.5, 0), anchor: [0, 0.5], size: U2(1, -40, 0, 78), bg: '#FFFFFF', r: 20, grad: [[0, '#3A2A8F'], [1, '#1B1036']], z: 1 },
        stroke(4, INK),
        box('HazardClip', { pos: U2(0, 4, 0, 4), size: U2(1, -8, 0, 14), bg: '#FFFFFF', r: 8 }, img('Hazard', 'pattern_hazard', { tile: 28, r: 8 })),
        box('Glow', { pos: U2(0, 4, 1, -4), anchor: [0, 1], size: U2(1, -8, 0, 30), bg: '#FF4D4D', r: 16, gradT: [[0, 1], [1, 0.55]], grad: ['#FF4D4D', '#FF4D4D'] }),
        label('Title', 'CARRYING EGG', { pos: U2(0, 76, 0, 18), size: U2(1, -250, 0, 30), ts: 28, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', '#FFE3E3'] }),
        box('WarnRow', { pos: U2(0, 76, 0, 48), size: U2(1, -250, 0, 22) },
          img('Warn', 'icon_warning', { size: px(22, 22), pos: U2(0, 0, 0.5, 0), anchor: [0, 0.5], attrs: { Pulse: true } }),
          label('Sub', 'UNSAFE! Run it back to your base', { pos: U2(0, 28, 0, 0), size: U2(1, -28, 1, 0), ts: 16, xa: 'Left', font: 'Fredoka', color: '#FFD23F', stroke: 2.5 })),
      ),
      eggSlot(C.red),
      chunky('DropButton', { theme: 'red', size: px(150, 66), pos: U2(1, -12, 0.5, 0), anchor: [1, 0.5], r: 16, lip: 7, icon: 'icon_drop', iconSize: 40, label: 'DROP', ts: 30, z: 5, attrs: { Action: 'DropEgg' } }),
    ),
    // ---------------- SECURED (no DROP)
    box('Secured', { size: U2(1, 0, 1, 0), visible: false },
      box('Banner', { pos: U2(0, 40, 0.5, 0), anchor: [0, 0.5], size: U2(1, -40, 0, 78), bg: '#FFFFFF', r: 20, grad: [[0, C.upgrade.hi], [0.5, C.upgrade.base], [1, C.upgrade.lo]], z: 1 },
        stroke(4, INK),
        img('Pattern', 'pattern_diagonal', { tile: 44, imgT: 0.86, r: 20 }),
        gloss({ r: 16, a: 0.5, h: 0.42 }),
        label('Title', 'EGG SECURED!', { pos: U2(0, 76, 0, 12), size: U2(1, -170, 0, 34), ts: 32, xa: 'Left', stroke: 3.5, grad: ['#FFFFFF', '#EFFFE0'] }),
        label('Sub', 'Safe in your base  -  start hatching!', { pos: U2(0, 76, 0, 46), size: U2(1, -170, 0, 22), ts: 17, xa: 'Left', font: 'Fredoka', color: '#FFFFFF', stroke: 2.5 }),
        img('Shield', 'icon_shield', { pos: U2(1, -16, 0.5, 0), anchor: [1, 0.5], size: px(84, 84), rot: 8 }),
      ),
      eggSlot(C.upgrade),
    ),
  );
}

// Full-screen dim behind open menus (nav stays above it so players can switch menus)
function backdrop() {
  return box('MenuBackdrop', { size: U2(1, 0, 1, 0), bg: INK, bgT: 0.45, visible: false, attrs: { Layer: 'Backdrop' } },
    box('Vignette', { size: U2(1, 0, 1, 0), bg: '#000000', grad: ['#000000', '#000000'], gradT: [[0, 0.55], [0.5, 1], [1, 0.55]], gradRot: 0 }));
}

module.exports = { hud, nav, hatchWidget, eggCarry, backdrop, NAV };
