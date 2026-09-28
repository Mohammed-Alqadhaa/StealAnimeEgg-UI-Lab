// Reusable UI building blocks. Every component returns a real Roblox instance
// tree (Frame / TextLabel / ImageLabel / TextButton + UI* modifiers).
const fs = require('fs');
const path = require('path');
const { I, U2, px, UD, V2, C3, CS, NS, Font, Content, E } = require('./rbx');
const { INK, C } = require('./theme');

const MANIFEST = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../../assets/asset-manifest.json'), 'utf8'));

// ---------------------------------------------------------------- modifiers
const corner = (r) => I('UICorner', { CornerRadius: typeof r === 'object' ? r : UD(0, r) });
const pill = () => I('UICorner', { CornerRadius: UD(1, 0) });
const stroke = (th = 3, color = INK, o = {}) => I('UIStroke', {
  Name: o.name || 'UIStroke', Thickness: th, Color: C3(color), Transparency: o.t || 0,
  ApplyStrokeMode: E(o.mode || 'Border'), LineJoinMode: E('Round'),
});
const tstroke = (th = 2.5, color = INK, t = 0) => I('UIStroke', { Thickness: th, Color: C3(color), Transparency: t, ApplyStrokeMode: E('Contextual'), LineJoinMode: E('Round') });
const grad = (colors, rot = 90, transp, name) => I('UIGradient', { Name: name || 'UIGradient', Color: CS(colors), Rotation: rot, Transparency: transp !== undefined ? NS(transp) : undefined });
const padding = (t, r = t, b = t, l = r) => I('UIPadding', { PaddingTop: UD(0, t), PaddingRight: UD(0, r), PaddingBottom: UD(0, b), PaddingLeft: UD(0, l) });
const list = (dir = 'Vertical', pad = 8, h = 'Center', v = 'Center', o = {}) => I('UIListLayout', {
  FillDirection: E(dir), Padding: UD(0, pad), HorizontalAlignment: E(h), VerticalAlignment: E(v), SortOrder: E('LayoutOrder'), ...o,
});
const gridLayout = (cw, ch, px_ = 10, py = 10, h = 'Center', o = {}) => I('UIGridLayout', {
  CellSize: U2(0, cw, 0, ch), CellPadding: U2(0, px_, 0, py), HorizontalAlignment: E(h), VerticalAlignment: E('Top'), SortOrder: E('LayoutOrder'), ...o,
});
const aspect = (r) => I('UIAspectRatioConstraint', { AspectRatio: r, AspectType: E('FitWithinMaxSize'), DominantAxis: E('Width') });
const scaleMod = (s = 1, name = 'AutoScale') => I('UIScale', { Name: name, Scale: s });

// Common GuiObject props from a compact option bag
function gprops(o = {}) {
  const p = {};
  if (o.name) p.Name = o.name;
  p.Size = o.size || U2(1, 0, 1, 0);
  if (o.pos) p.Position = o.pos;
  if (o.anchor) p.AnchorPoint = V2(...o.anchor);
  p.BackgroundColor3 = C3(o.bg || '#FFFFFF');
  p.BackgroundTransparency = o.bg ? (o.bgT || 0) : (o.bgT !== undefined ? o.bgT : 1);
  p.BorderSizePixel = 0;
  if (o.z !== undefined) p.ZIndex = o.z;
  if (o.lo !== undefined) p.LayoutOrder = o.lo;
  if (o.visible === false) p.Visible = false;
  if (o.clip) p.ClipsDescendants = true;
  if (o.rot) p.Rotation = o.rot;
  if (o.auto) p.AutomaticSize = E(o.auto);
  if (o.attrs) p.$attrs = o.attrs;
  return p;
}

// Frame with optional corner / stroke / gradient shortcuts
function box(name, o = {}, ...children) {
  const kids = [];
  if (o.r !== undefined) kids.push(o.r === 'pill' ? pill() : corner(o.r));
  if (o.stroke) kids.push(stroke(...(Array.isArray(o.stroke) ? o.stroke : [o.stroke])));
  if (o.grad) kids.push(grad(o.grad, o.gradRot ?? 90, o.gradT));
  return I('Frame', gprops({ ...o, name }), ...kids, ...children);
}

// ------------------------------------------------------------------ text
function label(name, text, o = {}) {
  const p = gprops({ ...o, name });
  Object.assign(p, {
    Text: text, TextSize: o.ts || 22, FontFace: Font(o.font || 'Luckiest', o.weight || 400),
    TextColor3: C3(o.color || '#FFFFFF'),
    TextXAlignment: E(o.xa || 'Center'), TextYAlignment: E(o.ya || 'Center'),
  });
  if (o.rich) p.RichText = true;
  if (o.wrap) p.TextWrapped = true;
  if (o.scaled) p.TextScaled = true;
  if (o.textT) p.TextTransparency = o.textT;
  const kids = [];
  if (o.stroke !== 0) kids.push(tstroke(o.stroke ?? 2.5, o.strokeColor || INK));
  if (o.grad) kids.push(grad(o.grad, o.gradRot ?? 90));
  if (o.maxTs) kids.push(I('UITextSizeConstraint', { MaxTextSize: o.maxTs, MinTextSize: o.minTs || 8 }));
  return I('TextLabel', p, ...kids, ...(o.children || []));
}

// ----------------------------------------------------------------- images
// Image placeholders are bound at runtime (AssetBinder) from AssetIds.lua;
// the atlas rect is baked here so designers can see crop data in Studio.
function img(name, key, o = {}) {
  const m = MANIFEST.images[key];
  if (!m) throw new Error(`unknown asset ${key}`);
  const p = gprops({ ...o, name });
  p.Image = Content('');
  p.ScaleType = E(o.tile ? 'Tile' : (o.scale || 'Fit'));
  if (o.tile) p.TileSize = U2(0, o.tile, 0, o.tile);
  if (m.atlas) { p.ImageRectOffset = V2(...m.offset); p.ImageRectSize = V2(...m.size); }
  if (o.color) p.ImageColor3 = C3(o.color);
  if (o.imgT !== undefined) p.ImageTransparency = o.imgT;
  p.$attrs = { AssetKey: key, ...(o.attrs || {}) };
  const kids = [];
  if (o.r !== undefined) kids.push(o.r === 'pill' ? pill() : corner(o.r));
  if (o.grad) kids.push(grad(o.grad, o.gradRot ?? 90, o.gradT));
  return I(o.button ? 'ImageButton' : 'ImageLabel', p, ...kids, ...(o.children || []));
}

// ------------------------------------------------------------ gloss / fx
function gloss(o = {}) {
  return box('Gloss', {
    pos: U2(0, o.inset ?? 4, 0, o.top ?? 3), size: U2(1, -(o.inset ?? 4) * 2, o.h ?? 0.46, 0),
    bg: '#FFFFFF', r: o.r ?? 8, grad: ['#FFFFFF', '#FFFFFF'], gradT: [[0, o.a ?? 0.45], [1, 0.95]], z: o.z,
  });
}
function pattern(key = 'pattern_diagonal', o = {}) {
  return img('Pattern', key, { tile: o.tile || 48, imgT: o.t ?? 0.88, color: o.color, r: o.r, z: o.z, pos: o.pos, size: o.size });
}

// ------------------------------------------------------------ chunky button
// Three-layer toy button: Lip (3D edge + outline) → Face (gradient) → Gloss.
// UIController animates Face on press and a UIScale on hover.
function chunkyFaces(o = {}) {
  const th = typeof o.theme === 'string' ? C[o.theme] : (o.theme || C.upgrade);
  const r = o.r ?? 12; const lip = o.lip ?? 6; const sw = o.sw ?? 3;
  const face = box('Face', {
    size: U2(1, 0, 1, -lip), bg: '#FFFFFF', r, z: 2,
    grad: [[0, th.hi], [0.5, th.base], [1, th.lo]],
  },
  stroke(2, th.hi, { name: 'InnerRim', t: 0.35 }),
  o.pattern !== false ? pattern(o.patternKey || 'pattern_diagonal', { r, t: o.patternT ?? 0.9, tile: o.tile || 40 }) : null,
  o.gloss !== false ? gloss({ r: Math.max(r - 3, 2), a: o.glossA }) : null,
  box('Content', { size: U2(1, 0, 1, 0) }, ...(o.content || defaultContent(o, th))),
  );
  const lipF = box('Lip', { size: U2(1, 0, 1, 0), bg: th.lip, r, z: 1 }, stroke(sw, INK));
  return [lipF, face];
}
function chunky(name, o = {}) {
  const lip = o.lip ?? 6;
  return I('TextButton', {
    ...gprops({ ...o, name }), Text: '', AutoButtonColor: false,
    $attrs: { Chunky: true, LipDepth: lip, ...(o.attrs || {}) },
  }, scaleMod(1, 'PressScale'), ...chunkyFaces(o), ...(o.extra || []));
}
function defaultContent(o, th) {
  const kids = [];
  const hasIcon = !!o.icon;
  const is = o.iconSize || 34;
  if (hasIcon) {
    kids.push(img('Icon', o.icon, {
      size: px(is, is), anchor: o.label ? [0, 0.5] : [0.5, 0.5],
      pos: o.label ? U2(0, o.iconX ?? 8, 0.5, o.iconY ?? 0) : U2(0.5, 0, 0.5, o.iconY ?? 0), rot: o.iconRot,
    }));
  }
  if (o.label) {
    const left = hasIcon ? (o.iconX ?? 8) + is + 2 : 0;
    kids.push(label('Label', o.label, {
      pos: U2(0, left, 0, o.sub ? 3 : 0), size: U2(1, -left - (o.padR ?? 4), o.sub ? 0.58 : 1, 0),
      ts: o.ts || 22, xa: o.xa || 'Center', ya: o.sub ? 'Bottom' : 'Center', stroke: o.textStroke ?? 2.5,
      color: o.textColor || '#FFFFFF',
    }));
    if (o.sub) {
      kids.push(label('Sub', o.sub, {
        pos: U2(0, left, 0.58, 0), size: U2(1, -left - 4, 0.42, -3), ts: o.subTs || 15, font: 'Fredoka',
        xa: o.xa || 'Center', ya: 'Top', stroke: 2, color: o.subColor || '#FFFFFF',
      }));
    }
  }
  return kids;
}

// Price button content: [icon] amount
function priceContent(icon, amount, o = {}) {
  return [box('Row', { size: U2(1, 0, 1, 0) },
    list('Horizontal', 4, 'Center', 'Center'),
    img('Icon', icon, { size: px(o.is || 24, o.is || 24), lo: 1 }),
    label('Amount', amount, { size: U2(0, 0, 1, 0), auto: 'X', ts: o.ts || 22, lo: 2, stroke: 2.5 }))];
}

// -------------------------------------------------------------- badges
function badge(name, text, o = {}) {
  const th = C[o.theme || 'red'];
  const s = o.s || 28;
  return box(name, {
    size: px(o.w || s, s), pos: o.pos, anchor: o.anchor || [0.5, 0.5], bg: '#FFFFFF', r: 'pill', z: o.z ?? 5,
    grad: [th.hi, th.base, th.lo], stroke: [2.5, INK], visible: o.visible, rot: o.rot,
  }, label('Text', text, { ts: o.ts || 18, stroke: 2 }));
}

// ribbon tag like "NEW!" / "BEST VALUE"
function tag(name, text, o = {}) {
  const th = C[o.theme || 'red'];
  return box(name, {
    size: px(o.w || 70, o.h || 24), pos: o.pos, anchor: o.anchor || [0, 0], bg: '#FFFFFF', r: o.r ?? 6, rot: o.rot, z: o.z ?? 6, visible: o.visible,
    grad: [th.hi, th.base, th.lo], stroke: [2.5, INK],
  }, label('Text', text, { ts: o.ts || 15, stroke: 2 }));
}

// ---------------------------------------------------------- progress bar
function progress(name, o = {}) {
  const th = C[o.theme || 'upgrade'];
  const h = o.h || 26;
  return box(name, {
    size: o.size || U2(1, 0, 0, h), pos: o.pos, anchor: o.anchor, bg: o.track || '#2A1F5C', r: 'pill', stroke: [o.sw ?? 3, INK], lo: o.lo, z: o.z,
  },
  box('InnerShade', { size: U2(1, 0, 0.5, 0), bg: '#000000', bgT: 0.75, r: 'pill' }),
  box('Fill', {
    size: U2(o.value ?? 0.5, 0, 1, 0), bg: '#FFFFFF', r: 'pill',
    grad: [[0, th.hi], [0.5, th.base], [1, th.lo]],
  }, box('Shine', { pos: U2(0, 4, 0, 3), size: U2(1, -8, 0.38, 0), bg: '#FFFFFF', bgT: 0.45, r: 'pill' }),
  o.stripes !== false ? img('Stripes', 'pattern_diagonal', { tile: h, imgT: 0.8, r: 'pill' }) : null),
  o.text !== undefined ? label('Text', o.text, { ts: o.ts || Math.round(h * 0.7), stroke: 2.5, z: 3 }) : null);
}

// icon + text pair row used on cards (e.g. $/s)
function statRow(name, icon, text, o = {}) {
  return box(name, { size: o.size || U2(1, 0, 0, o.h || 22), pos: o.pos, anchor: o.anchor, lo: o.lo },
    list('Horizontal', o.gap ?? 4, o.align || 'Center', 'Center'),
    img('Icon', icon, { size: px(o.is || 20, o.is || 20), lo: 1 }),
    label('Text', text, { size: U2(0, 0, 1, 0), auto: 'X', ts: o.ts || 18, lo: 2, color: o.color, stroke: o.stroke ?? 2, font: o.font || 'Luckiest', rich: o.rich }));
}

module.exports = {
  MANIFEST, corner, pill, stroke, tstroke, grad, padding, list, gridLayout, aspect, scaleMod, gprops,
  box, label, img, gloss, pattern, chunky, chunkyFaces, priceContent, badge, tag, progress, statRow,
};
