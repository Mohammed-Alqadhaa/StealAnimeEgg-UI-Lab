// Minimal typed Roblox instance DSL.
//  - I(className, props, ...children) builds an instance tree
//  - toRbxmx(roots) serializes to Roblox XML model format (version 4)
//  - toJSON(root) produces a plain tree consumed by the browser preview renderer
//
// Property values are either JS primitives (string/number/boolean) or typed
// wrappers created with the helpers below (U2, UD, V2, C3, CS, NS, Font, E, ...).

const T = (t, v) => ({ __t: t, v });

// ---- value helpers ---------------------------------------------------------
const U2 = (xs, xo, ys, yo) => T('UDim2', [xs, xo, ys, yo]);
const px = (w, h) => U2(0, w, 0, h);
const sc = (x, y) => U2(x, 0, y, 0);
const UD = (s, o) => T('UDim', [s, o]);
const V2 = (x, y) => T('Vector2', [x, y]);
const V3 = (x, y, z) => T('Vector3', [x, y, z]);
function hex(h) {
  const n = h.replace('#', '');
  return [parseInt(n.slice(0, 2), 16) / 255, parseInt(n.slice(2, 4), 16) / 255, parseInt(n.slice(4, 6), 16) / 255];
}
const C3 = (h) => T('Color3', hex(h));
// ColorSequence from [[t, '#hex'], ...] or a list of hex (evenly spaced)
function CS(stops) {
  if (typeof stops[0] === 'string') stops = stops.map((c, i) => [i / (stops.length - 1), c]);
  return T('ColorSequence', stops.map(([t, c]) => [t, ...hex(c)]));
}
// NumberSequence from [[t, v], ...] or a single number
const NS = (stops) => T('NumberSequence', typeof stops === 'number' ? [[0, stops], [1, stops]] : stops);
const FONTS = {
  Luckiest: 'rbxasset://fonts/families/LuckiestGuy.json',
  Fredoka: 'rbxasset://fonts/families/FredokaOne.json',
  Gotham: 'rbxasset://fonts/families/GothamSSm.json',
};
const Font = (family, weight = 400) => T('Font', { family: FONTS[family] || family, weight, key: family });
const Content = (url) => T('Content', url);
const CF = (x, y, z, lookAt) => T('CFrame', { p: [x, y, z], lookAt });
const Ref = (name) => T('Ref', name);
const RichSource = (src) => T('ProtectedString', src);

// Enum tokens (integer values from the Roblox API dump)
const ENUMS = {
  ZIndexBehavior: { Global: 0, Sibling: 1 },
  TextXAlignment: { Left: 0, Right: 1, Center: 2 },
  TextYAlignment: { Top: 0, Center: 1, Bottom: 2 },
  ScaleType: { Stretch: 0, Slice: 1, Tile: 2, Fit: 3, Crop: 4 },
  FillDirection: { Horizontal: 0, Vertical: 1 },
  HorizontalAlignment: { Center: 0, Left: 1, Right: 2 },
  VerticalAlignment: { Center: 0, Top: 1, Bottom: 2 },
  SortOrder: { Name: 0, Custom: 1, LayoutOrder: 2 },
  ApplyStrokeMode: { Contextual: 0, Border: 1 },
  LineJoinMode: { Round: 0, Bevel: 1, Miter: 2 },
  AutomaticSize: { None: 0, X: 1, Y: 2, XY: 3 },
  ScrollingDirection: { X: 1, Y: 2, XY: 4 },
  AspectType: { FitWithinMaxSize: 0, ScaleWithParentSize: 1 },
  DominantAxis: { Width: 0, Height: 1 },
  ScreenInsets: { None: 0, DeviceSafeInsets: 1, CoreUISafeInsets: 2, TopbarSafeInsets: 3 },
  StartCorner: { TopLeft: 0, TopRight: 1, BottomLeft: 2, BottomRight: 3 },
  ElasticBehavior: { WhenScrollable: 0, Always: 1, Never: 2 },
  ScrollBarInset: { None: 0, ScrollBar: 1, Always: 2 },
};
// Map property name -> enum type (property names that are enum-typed)
const ENUM_PROPS = {
  ZIndexBehavior: 'ZIndexBehavior', TextXAlignment: 'TextXAlignment', TextYAlignment: 'TextYAlignment',
  ScaleType: 'ScaleType', FillDirection: 'FillDirection', HorizontalAlignment: 'HorizontalAlignment',
  VerticalAlignment: 'VerticalAlignment', SortOrder: 'SortOrder', ApplyStrokeMode: 'ApplyStrokeMode',
  LineJoinMode: 'LineJoinMode', AutomaticSize: 'AutomaticSize', ScrollingDirection: 'ScrollingDirection',
  AspectType: 'AspectType', DominantAxis: 'DominantAxis', ScreenInsets: 'ScreenInsets', StartCorner: 'StartCorner',
  ElasticBehavior: 'ElasticBehavior', VerticalScrollBarInset: 'ScrollBarInset', AutomaticCanvasSize: 'AutomaticSize',
};

// ---- instances --------------------------------------------------------------
class Inst {
  constructor(cls, props = {}, children = []) {
    this.cls = cls;
    this.name = props.Name || cls;
    this.props = { ...props };
    delete this.props.Name;
    this.attrs = this.props.$attrs || {};
    delete this.props.$attrs;
    this.children = children.flat(Infinity).filter(Boolean);
  }
  add(...c) { this.children.push(...c.flat(Infinity).filter(Boolean)); return this; }
  find(name) {
    for (const c of this.children) { if (c.name === name) return c; }
    return null;
  }
}
const I = (cls, props = {}, ...children) => new Inst(cls, props, children);

// ---- XML serialization -----------------------------------------------------
const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
const num = (n) => { const r = Math.round(n * 1e6) / 1e6; return String(Object.is(r, -0) ? 0 : r); };

function attrBlob(attrs) {
  // Roblox binary attribute format: u32 count, then (string key, u8 type, value)
  const parts = [];
  const u32 = (n) => { const b = Buffer.alloc(4); b.writeUInt32LE(n); return b; };
  const str = (s) => { const b = Buffer.from(s, 'utf8'); return Buffer.concat([u32(b.length), b]); };
  const keys = Object.keys(attrs);
  parts.push(u32(keys.length));
  for (const k of keys) {
    const v = attrs[k];
    parts.push(str(k));
    if (typeof v === 'string') { parts.push(Buffer.from([0x02]), str(v)); }
    else if (typeof v === 'boolean') { parts.push(Buffer.from([0x03, v ? 1 : 0])); }
    else if (typeof v === 'number') { const b = Buffer.alloc(8); b.writeDoubleLE(v); parts.push(Buffer.from([0x06]), b); }
    else throw new Error(`unsupported attribute ${k}`);
  }
  return Buffer.concat(parts).toString('base64');
}

function lookAtMatrix(p, t) {
  // Camera-style CFrame.lookAt(p, t): -Z points at target
  const sub = (a, b) => [a[0] - b[0], a[1] - b[1], a[2] - b[2]];
  const norm = (v) => { const l = Math.hypot(...v); return v.map((x) => x / l); };
  const cross = (a, b) => [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]];
  const back = norm(sub(p, t));
  const right = norm(cross([0, 1, 0], back));
  const up = cross(back, right);
  return [right[0], up[0], back[0], right[1], up[1], back[1], right[2], up[2], back[2]];
}

function propXml(name, v, refs) {
  if (typeof v === 'string') return `<string name="${name}">${esc(v)}</string>`;
  if (typeof v === 'boolean') return `<bool name="${name}">${v}</bool>`;
  if (typeof v === 'number') {
    if (ENUM_PROPS[name]) return `<token name="${name}">${v}</token>`;
    const ints = ['ZIndex', 'LayoutOrder', 'FillDirectionMaxCells', 'DisplayOrder', 'MaxVisibleGraphemes', 'ScrollBarThickness', 'BorderSizePixel', 'SelectionOrder', 'MaxTextSize', 'MinTextSize'];
    return ints.includes(name) ? `<int name="${name}">${Math.round(v)}</int>` : `<float name="${name}">${num(v)}</float>`;
  }
  const { __t: t, v: d } = v;
  switch (t) {
    case 'Enum': return `<token name="${name}">${ENUMS[ENUM_PROPS[name]][d]}</token>`;
    case 'UDim2': return `<UDim2 name="${name}"><XS>${num(d[0])}</XS><XO>${Math.round(d[1])}</XO><YS>${num(d[2])}</YS><YO>${Math.round(d[3])}</YO></UDim2>`;
    case 'UDim': return `<UDim name="${name}"><S>${num(d[0])}</S><O>${Math.round(d[1])}</O></UDim>`;
    case 'Vector2': return `<Vector2 name="${name}"><X>${num(d[0])}</X><Y>${num(d[1])}</Y></Vector2>`;
    case 'Vector3': return `<Vector3 name="${name}"><X>${num(d[0])}</X><Y>${num(d[1])}</Y><Z>${num(d[2])}</Z></Vector3>`;
    case 'Color3': return `<Color3 name="${name}"><R>${num(d[0])}</R><G>${num(d[1])}</G><B>${num(d[2])}</B></Color3>`;
    case 'Color3uint8': {
      const n = ((255 << 24) >>> 0) + (Math.round(d[0] * 255) << 16) + (Math.round(d[1] * 255) << 8) + Math.round(d[2] * 255);
      return `<Color3uint8 name="${name}">${n >>> 0}</Color3uint8>`;
    }
    case 'ColorSequence': return `<ColorSequence name="${name}">${d.map((k) => `${num(k[0])} ${num(k[1])} ${num(k[2])} ${num(k[3])} 0`).join(' ')} </ColorSequence>`;
    case 'NumberSequence': return `<NumberSequence name="${name}">${d.map((k) => `${num(k[0])} ${num(k[1])} 0`).join(' ')} </NumberSequence>`;
    case 'Font': return `<Font name="${name}"><Family><url>${d.family}</url></Family><Weight>${d.weight}</Weight><Style>Normal</Style></Font>`;
    case 'Content': return d ? `<Content name="${name}"><url>${esc(d)}</url></Content>` : `<Content name="${name}"><null></null></Content>`;
    case 'ProtectedString': return `<ProtectedString name="${name}"><![CDATA[${d}]]></ProtectedString>`;
    case 'Ref': return `<Ref name="${name}">${refs.get(d) || 'null'}</Ref>`;
    case 'CFrame': {
      const m = d.lookAt ? lookAtMatrix(d.p, d.lookAt) : [1, 0, 0, 0, 1, 0, 0, 0, 1];
      const k = ['R00', 'R01', 'R02', 'R10', 'R11', 'R12', 'R20', 'R21', 'R22'];
      return `<CoordinateFrame name="${name}"><X>${num(d.p[0])}</X><Y>${num(d.p[1])}</Y><Z>${num(d.p[2])}</Z>${m.map((x, i) => `<${k[i]}>${num(x)}</${k[i]}>`).join('')}</CoordinateFrame>`;
    }
    default: throw new Error(`unknown type ${t} for ${name}`);
  }
}

function toRbxmx(roots) {
  let n = 0;
  const refs = new Map(); // instance-name path lookups for Ref props (by unique name)
  const assign = (inst) => { inst.ref = `RBX${(n++).toString(16).toUpperCase().padStart(8, '0')}`; refs.set(inst.props.$refName || inst.name + '#' + inst.ref, inst.ref); if (inst.props.$refName) refs.set(inst.props.$refName, inst.ref); inst.children.forEach(assign); };
  roots.forEach(assign);
  const out = [];
  const walk = (inst, depth) => {
    const pad = '  '.repeat(depth);
    out.push(`${pad}<Item class="${inst.cls}" referent="${inst.ref}">`);
    out.push(`${pad}  <Properties>`);
    out.push(`${pad}    <string name="Name">${esc(inst.name)}</string>`);
    for (const [k, v] of Object.entries(inst.props)) {
      if (k.startsWith('$') || v === undefined || v === null) continue;
      out.push(`${pad}    ${propXml(k, v, refs)}`);
    }
    if (Object.keys(inst.attrs).length) out.push(`${pad}    <BinaryString name="AttributesSerialize">${attrBlob(inst.attrs)}</BinaryString>`);
    out.push(`${pad}  </Properties>`);
    inst.children.forEach((c) => walk(c, depth + 1));
    out.push(`${pad}</Item>`);
  };
  roots.forEach((r) => walk(r, 1));
  return `<roblox xmlns:xmime="http://www.w3.org/2005/05/xmlmime" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:noNamespaceSchemaLocation="http://www.roblox.com/roblox.xsd" version="4">\n${out.join('\n')}\n</roblox>\n`;
}

// ---- JSON for the browser preview -----------------------------------------
function toJSON(inst) {
  const p = {};
  for (const [k, v] of Object.entries(inst.props)) {
    if (k.startsWith('$') || v === undefined || v === null) continue;
    if (typeof v === 'object' && v.__t === 'Enum') p[k] = v.v;
    else if (typeof v === 'number' && ENUM_PROPS[k]) p[k] = Object.entries(ENUMS[ENUM_PROPS[k]]).find(([, x]) => x === v)[0];
    else if (typeof v === 'object') p[k] = { t: v.__t, v: v.v };
    else p[k] = v;
  }
  return { c: inst.cls, n: inst.name, p, a: inst.attrs, ch: inst.children.map(toJSON) };
}

const E = (name) => T('Enum', name);

module.exports = { I, Inst, U2, px, sc, UD, V2, V3, C3, CS, NS, Font, Content, CF, Ref, RichSource, E, hex, toRbxmx, toJSON, T, ENUMS };
