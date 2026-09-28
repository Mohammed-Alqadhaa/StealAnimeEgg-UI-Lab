// Original eggs, character portraits and FX textures for StealAnimeEgg-UI-Lab.
// Character portraits are original chibi busts designed so that each has a
// unique outline (hair / hat) – the Index uses ImageColor3 = black for the
// locked silhouette state, so the outline must remain recognisable.
const { INK, icon, path, plain, tube, spark } = require('./kit');

const A = {};

// -------------------------------------------------------------------- EGGS
const EGG = 'M128 16 C184 16 222 100 222 154 C222 210 180 240 128 240 C76 240 34 210 34 154 C34 100 72 16 128 16 Z';
function egg(id, base, inner, extra = {}) {
  const k = icon();
  k.def(`<clipPath id="c_${id}"><path d="${EGG}"/></clipPath>`);
  k.add(path(EGG, base, 11));
  k.add(`<g clip-path="url(#c_${id})">${inner(k)}` +
    `<path d="M34 154 C34 210 76 240 128 240 C180 240 222 210 222 154 L222 250 L34 250 Z" fill="#000" opacity="0.16"/>` +
    `<path d="M200 60 C226 110 230 190 170 232 C214 186 214 110 186 60 Z" fill="#000" opacity="0.14"/></g>`);
  k.add(path(EGG, 'none', 0), `<path d="${EGG}" fill="none" stroke="${INK}" stroke-width="11"/>`);
  k.gloss('M84 46 Q104 28 120 36 Q94 62 86 102 Q70 82 84 46 Z', 0.95);
  (extra.sparks || []).forEach(([x, y, s, c]) => k.add(spark(x, y, s, c)));
  return k.done();
}

A.egg_demon = () => egg('demon', '#1FAE6A', (k) => {
  let s = '';
  for (let y = 0; y < 8; y++) for (let x = 0; x < 8; x++) if ((x + y) % 2 === 0) s += `<rect x="${x * 32}" y="${y * 32}" width="32" height="32" fill="#16223A"/>`;
  return `<g transform="rotate(-8 128 128)">${s}</g>` +
    `<rect x="0" y="0" width="256" height="256" fill="${k.lin([[0, '#9BFFC8', 0.55], [0.6, '#1FAE6A', 0], [1, '#000', 0.2]])}"/>` +
    // crimson flame band
    `<path d="M20 128 Q60 104 90 126 Q110 96 136 122 Q160 92 184 124 Q208 104 236 124 L236 164 Q200 150 180 168 Q156 146 132 168 Q110 148 88 168 Q60 150 20 166 Z" fill="${k.tone('#FF8A4D', '#C9163A')}" stroke="${INK}" stroke-width="7" stroke-linejoin="round"/>`;
}, { sparks: [[214, 34, 1.3], [40, 222, 1]] });

A.egg_anime = () => egg('anime', '#7B3FF2', (k) => {
  const g = k.lin([[0, '#FF9DE6'], [0.45, '#8A4DFF'], [1, '#1A2C8F']]);
  let stars = '';
  [[80, 90, 3], [160, 60, 2.5], [180, 140, 3.5], [100, 170, 2], [140, 210, 3], [70, 140, 2], [150, 110, 2]].forEach(([x, y, r]) => { stars += `<circle cx="${x}" cy="${y}" r="${r}" fill="#FFFFFF"/>`; });
  return `<rect width="256" height="256" fill="${g}"/>` +
    `<path d="M20 170 Q90 110 160 150 Q210 180 240 130" fill="none" stroke="#FFFFFF" stroke-width="14" opacity="0.35"/>` +
    `<path d="M20 196 Q100 140 170 178 Q214 200 240 170" fill="none" stroke="#59E1FF" stroke-width="10" opacity="0.6"/>` + stars +
    path('M128 84 L136 104 L158 106 L141 120 L147 142 L128 130 L109 142 L115 120 L98 106 L120 104 Z', '#FFF6A8', 6);
}, { sparks: [[216, 40, 1.3, '#FFE6FF'], [36, 70, 0.9]] });

A.egg_flame = () => egg('flame', '#FF6A1F', (k) => {
  return `<rect width="256" height="256" fill="${k.lin([[0, '#FFE680'], [0.5, '#FF8A1F'], [1, '#D8261E']])}"/>` +
    `<path d="M20 250 L20 180 Q40 150 44 120 Q64 150 70 170 Q80 120 104 96 Q108 140 124 160 Q134 110 160 80 Q164 130 180 150 Q192 120 204 110 Q214 150 236 176 L236 250 Z" fill="#FFD23F" stroke="${INK}" stroke-width="6" stroke-linejoin="round"/>` +
    `<path d="M40 250 L44 196 Q60 176 64 160 Q76 184 84 200 Q98 160 112 146 Q116 180 128 196 Q142 160 158 140 Q164 176 176 190 Q188 170 196 160 Q204 190 216 206 L216 250 Z" fill="#FFF6C8"/>`;
}, { sparks: [[212, 36, 1.3], [44, 60, 0.9, '#FFF6A8']] });

A.egg_moon = () => egg('moon', '#243A8F', (k) => {
  let s = '';
  [[70, 80, 2.5], [180, 70, 3], [200, 160, 2], [90, 200, 2.5], [60, 150, 2], [150, 214, 2]].forEach(([x, y, r]) => { s += `<circle cx="${x}" cy="${y}" r="${r}" fill="#FFFFFF"/>`; });
  return `<rect width="256" height="256" fill="${k.lin([[0, '#6F8BFF'], [0.55, '#243A8F'], [1, '#0E1644']])}"/>` + s +
    path('M150 92 Q108 100 108 146 Q108 190 152 198 Q112 214 88 188 Q64 160 78 124 Q96 88 150 92 Z', k.tone('#FFFBE0', '#FFD23F'), 7) +
    `<path d="M20 120 Q128 96 236 120" fill="none" stroke="#9FD8FF" stroke-width="6" stroke-dasharray="4 12" stroke-linecap="round" opacity="0.8"/>`;
}, { sparks: [[216, 40, 1.2, '#DDE7FF'], [180, 120, 0.8]] });

A.egg_golden = () => egg('golden', '#FFC21F', (k) => {
  let d = '';
  for (let y = -32; y < 280; y += 44) for (let x = -32; x < 280; x += 44) d += `<path d="M${x} ${y + 22} L${x + 22} ${y} L${x + 44} ${y + 22} L${x + 22} ${y + 44} Z" fill="none" stroke="#FFF6A8" stroke-width="3" opacity="0.7"/>`;
  return `<rect width="256" height="256" fill="${k.lin([[0, '#FFF9C4'], [0.5, '#FFC21F'], [1, '#C77700']])}"/>` + d +
    path('M128 112 L150 132 L128 176 L106 132 Z', k.tone('#9FF7FF', '#1F8BFF'), 7) +
    `<circle cx="80" cy="150" r="12" fill="#FF4F7E" stroke="${INK}" stroke-width="6"/><circle cx="176" cy="150" r="12" fill="#4BD84A" stroke="${INK}" stroke-width="6"/>`;
}, { sparks: [[214, 34, 1.5], [42, 66, 1.1], [206, 206, 0.9]] });

// ------------------------------------------------------------- PORTRAITS
const FACE = 'M80 110 Q80 62 128 62 Q176 62 176 110 L175 138 Q170 184 128 198 Q86 184 81 138 Z';
function bust(k, o) {
  const skin = o.skin || '#FFE3CF';
  const skinShade = o.skinShade || '#F4C4A8';
  const out = [];
  if (o.backHair) out.push(o.backHair);
  out.push(o.body);
  out.push(path('M108 176 L148 176 L148 214 L108 214 Z', skinShade, 8));
  out.push(`<ellipse cx="80" cy="134" rx="11" ry="15" fill="${skin}" stroke="${INK}" stroke-width="7"/>`, `<ellipse cx="176" cy="134" rx="11" ry="15" fill="${skin}" stroke="${INK}" stroke-width="7"/>`);
  out.push(path(FACE, skin, 9));
  out.push(`<path d="M86 150 Q90 180 128 194 Q166 180 170 150 Q160 176 128 186 Q96 176 86 150 Z" fill="${skinShade}" opacity="0.6"/>`);
  if (o.faceMarks) out.push(o.faceMarks);
  // eyes
  const eye = (cx, flip) => {
    const f = flip ? -1 : 1;
    const lid = o.lid || 0; // 0 = open, >0 = heavier upper lid
    return `<ellipse cx="${cx}" cy="142" rx="12.5" ry="${14 - lid}" fill="${o.sclera || '#FFFFFF'}"/>` +
      `<ellipse cx="${cx + f}" cy="${144}" rx="9.5" ry="${12 - lid * 0.6}" fill="${k.tone(o.iris[0], o.iris[1])}"/>` +
      (o.slit ? `<ellipse cx="${cx + f}" cy="144" rx="2.2" ry="9" fill="${INK}"/>` : `<ellipse cx="${cx + f}" cy="145" rx="4.5" ry="6.5" fill="${INK}"/>`) +
      `<circle cx="${cx - 3 * f}" cy="${138 + lid}" r="3.6" fill="#FFFFFF"/><circle cx="${cx + 4 * f}" cy="150" r="1.8" fill="#FFFFFF"/>` +
      `<path d="M${cx - 15 * f} ${130 + lid} Q${cx} ${122 + lid} ${cx + 15 * f} ${131 + lid}" fill="none" stroke="${INK}" stroke-width="${o.lash || 6}" stroke-linecap="round"/>`;
  };
  out.push(eye(108, false), eye(148, true));
  if (o.brows) out.push(o.brows);
  out.push(`<ellipse cx="94" cy="162" rx="8" ry="4.5" fill="#FF8FA8" opacity="${o.blush ?? 0.55}"/><ellipse cx="162" cy="162" rx="8" ry="4.5" fill="#FF8FA8" opacity="${o.blush ?? 0.55}"/>`);
  out.push(o.mouth);
  if (o.frontHair) out.push(o.frontHair);
  if (o.acc) out.push(o.acc);
  k.add(...out);
}
// Bangs: filled shape, but only the spiky lower edge gets the ink line
// (avoids a 'headband' outline where the bangs meet the back hair).
function bangs(top, zig, fill) {
  const start = top.trim().split(/\s+/).slice(-2).join(' ');
  const first = top.trim().split(/\s+/).slice(0, 2).join(' ').replace('M', '');
  return `<path d="${top} ${zig} Z" fill="${fill}"/>` +
    `<path d="M${start} ${zig} L${first}" fill="none" stroke="${INK}" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"/>`;
}
const hanafuda = (x) => `<path d="M${x} 150 L${x} 158" stroke="${INK}" stroke-width="4"/>` +
  path(`M${x - 9} 158 L${x + 9} 158 L${x + 9} 186 L${x - 9} 186 Z`, '#FFFFFF', 6) + `<circle cx="${x}" cy="168" r="6" fill="#E8321E"/><path d="M${x - 9} 179 L${x + 9} 179" stroke="#2B7A3A" stroke-width="4"/>`;

A.char_rengoku = () => {
  const k = icon();
  const mane = k.rad([[0, '#FFF27A'], [0.55, '#FFC21F'], [0.8, '#FF7A1A'], [1, '#D8261E']], { cx: 0.5, cy: 0.52, r: 0.55 });
  bust(k, {
    backHair: path('M128 12 L148 38 L176 16 L182 50 L216 38 L206 74 L242 80 L216 106 L244 128 L208 138 L224 172 L186 160 L178 122 Q176 70 128 64 Q80 70 78 122 L70 160 L32 172 L48 138 L12 128 L40 106 L14 80 L50 74 L40 38 L74 50 L80 16 L108 38 Z', mane, 10),
    body: path('M20 256 Q26 212 92 200 L164 200 Q230 212 236 256 Z', '#1E1E3A', 9) +
      path('M20 256 Q26 212 92 200 L110 206 L100 256 Z', '#FFFFFF', 8) + path('M236 256 Q230 212 164 200 L146 206 L156 256 Z', '#FFFFFF', 8) +
      `<path d="M28 256 Q40 236 50 244 Q56 226 70 236 Q76 222 92 232 L96 256 Z" fill="#FF6A1F"/><path d="M228 256 Q216 236 206 244 Q200 226 186 236 Q180 222 164 232 L160 256 Z" fill="#FF6A1F"/>` +
      `<circle cx="128" cy="232" r="5" fill="#FFD23F" stroke="${INK}" stroke-width="3"/><circle cx="128" cy="250" r="5" fill="#FFD23F" stroke="${INK}" stroke-width="3"/>` +
      path('M104 200 L128 218 L152 200 L152 208 L128 226 L104 208 Z', '#FFFFFF', 5),
    iris: ['#FFE14D', '#E8321E'], lash: 7,
    brows: `<path d="M92 118 Q106 108 122 116 L118 122 Q106 116 94 124 Z" fill="#B3201A" stroke="${INK}" stroke-width="3"/><path d="M164 118 Q150 108 134 116 L138 122 Q150 116 162 124 Z" fill="#B3201A" stroke="${INK}" stroke-width="3"/>`,
    mouth: path('M110 168 Q128 164 146 168 Q144 186 128 186 Q112 186 110 168 Z', '#A8203A', 5) + `<path d="M114 169 Q128 166 142 169 L141 174 Q128 172 115 174 Z" fill="#FFFFFF"/>`,
    frontHair: bangs('M78 120 Q74 66 128 58 Q182 66 178 120', 'L168 96 L160 118 L148 86 L136 112 L126 84 L114 112 L104 88 L96 116 L88 96', k.tone('#FFF27A', '#FFA000')) ,
  });
  return k.done();
};

A.char_tanjiro = () => {
  const k = icon();
  k.def(`<pattern id="chk" width="28" height="28" patternUnits="userSpaceOnUse"><rect width="28" height="28" fill="#1FAE6A"/><rect width="14" height="14" fill="#16223A"/><rect x="14" y="14" width="14" height="14" fill="#16223A"/></pattern>`);
  const hair = k.tone('#8E2A2A', '#3A0D14');
  bust(k, {
    backHair: path('M74 132 Q56 100 70 72 L56 50 L88 54 L92 26 L116 44 L134 18 L148 44 L176 26 L178 56 L206 52 L190 80 Q206 106 184 134 Q178 72 128 66 Q80 72 74 132 Z', hair, 10),
    body: path('M20 256 Q26 212 92 200 L164 200 Q230 212 236 256 Z', 'url(#chk)', 9) +
      path('M92 200 L128 240 L164 200 L150 198 L128 222 L106 198 Z', '#1E1E3A', 6) + path('M98 200 L128 232 L158 200', 'none', 0) +
      `<path d="M100 200 L128 230 L156 200" fill="none" stroke="#FFFFFF" stroke-width="5"/>`,
    iris: ['#E0564A', '#5A0F1A'],
    brows: `<path d="M94 120 Q106 114 120 118" fill="none" stroke="#5A0F1A" stroke-width="6" stroke-linecap="round"/><path d="M162 120 Q150 114 136 118" fill="none" stroke="#5A0F1A" stroke-width="6" stroke-linecap="round"/>`,
    mouth: `<path d="M116 170 Q128 180 140 170" fill="#FFFFFF" stroke="${INK}" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>`,
    frontHair: bangs('M78 124 Q72 60 128 53 Q184 60 178 124', 'L170 100 L158 110 L150 88 L138 104 L128 80 L118 104 L106 88 L100 112 L90 100', hair),
    faceMarks: `<path d="M150 98 Q160 92 166 102 Q160 104 162 112 Q154 106 150 112 Q146 104 150 98 Z" fill="#B3201A"/>`,
    acc: hanafuda(78) + hanafuda(178),
  });
  return k.done();
};

A.char_muzan = () => {
  const k = icon();
  const hair = k.tone('#3A3150', '#0E0A18');
  bust(k, {
    skin: '#FFF1EA', skinShade: '#E8CFC6',
    backHair: path('M72 96 Q50 132 62 170 Q70 192 56 210 Q88 212 94 188 L162 188 Q168 212 200 210 Q186 192 194 170 Q206 132 184 96 Z', hair, 10),
    body: path('M20 256 Q26 212 92 200 L164 200 Q230 212 236 256 Z', '#22223A', 9) +
      path('M100 200 L128 244 L156 200 Z', '#FFFFFF', 6) + path('M122 212 L134 212 L138 250 L128 256 L118 250 Z', '#9A1030', 5) +
      path('M20 256 Q26 212 92 200 L106 204 L118 256 Z', '#2E2E4A', 7) + path('M236 256 Q230 212 164 200 L150 204 L138 256 Z', '#2E2E4A', 7),
    iris: ['#FF4D4D', '#8E0A1E'], slit: true, lid: 3, blush: 0,
    brows: `<path d="M94 124 L120 122" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M162 124 L136 122" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>`,
    mouth: `<path d="M118 172 Q128 168 138 172" fill="none" stroke="#9A1030" stroke-width="5" stroke-linecap="round"/>`,
    frontHair: path('M80 126 Q74 94 96 90 Q86 110 98 120 Q98 100 116 94 Q110 110 124 116 Q124 96 140 94 Q134 110 150 116 Q152 98 166 96 Q160 112 176 126 Q184 96 160 88 L96 88 Q72 96 80 126 Z', hair, 8),
    acc: path('M68 92 Q64 30 128 26 Q192 30 188 92 Q128 80 68 92 Z', k.tone('#FFFFFF', '#C9CFE8'), 9) +
      path('M68 84 Q128 70 188 84 L188 94 Q128 80 68 94 Z', '#16131F', 5) +
      path('M30 98 Q128 66 226 98 Q236 110 216 112 Q128 86 40 112 Q20 110 30 98 Z', k.tone('#FFFFFF', '#DDE2F4'), 9) +
      `<path d="M86 40 Q100 32 118 32" fill="none" stroke="#FFFFFF" stroke-width="7" stroke-linecap="round" opacity="0.9"/>`,
  });
  return k.done();
};

A.char_akaza = () => {
  const k = icon();
  const hair = k.tone('#FFB3D6', '#E0457B');
  const tat = '#2F5BFF';
  bust(k, {
    skin: '#FFE8E4', skinShade: '#F2C6C4',
    backHair: path('M76 124 Q66 92 78 72 L70 44 L96 58 L104 28 L124 52 L140 22 L152 52 L176 30 L178 60 L204 54 L186 84 Q194 106 180 124 Q176 72 128 66 Q80 72 76 124 Z', hair, 10),
    body: path('M20 256 Q26 212 92 200 L164 200 Q230 212 236 256 Z', '#FFE8E4', 9) +
      path('M20 256 Q26 212 92 200 L108 208 L96 256 Z', k.tone('#FF6FB8', '#B0206A'), 8) + path('M236 256 Q230 212 164 200 L148 208 L160 256 Z', k.tone('#FF6FB8', '#B0206A'), 8) +
      `<path d="M108 222 L148 222 M104 236 L152 236 M102 250 L154 250" stroke="${tat}" stroke-width="5" stroke-linecap="round"/>`,
    iris: ['#FFF27A', '#FFA000'], sclera: '#A8DCFF', lid: 1,
    faceMarks: `<path d="M86 108 L112 108 M144 108 L170 108 M90 158 L102 158 M154 158 L166 158 M84 170 L98 170 M158 170 L172 170" stroke="${tat}" stroke-width="4.5" stroke-linecap="round"/>`,
    brows: `<path d="M94 122 L120 128" stroke="${INK}" stroke-width="6" stroke-linecap="round"/><path d="M162 122 L136 128" stroke="${INK}" stroke-width="6" stroke-linecap="round"/>`,
    blush: 0,
    mouth: `<path d="M112 170 Q128 180 146 166" fill="none" stroke="${INK}" stroke-width="5" stroke-linecap="round"/><path d="M138 172 L141 180 L144 170 Z" fill="#FFFFFF" stroke="${INK}" stroke-width="2"/>`,
    frontHair: bangs('M80 118 Q78 72 128 64 Q178 72 176 118', 'L168 94 L158 108 L150 84 L138 102 L128 80 L118 102 L106 84 L98 108 L88 94', hair),
    acc: `<path d="M84 128 L90 124 M172 128 L166 124" stroke="${tat}" stroke-width="4" stroke-linecap="round"/>`,
  });
  return k.done();
};

A.char_yoriichi = () => {
  const k = icon();
  const hair = k.tone('#9A2A36', '#34080F');
  bust(k, {
    backHair: path('M150 60 Q196 30 232 40 Q210 54 244 66 Q214 74 236 94 Q206 92 214 116 Q190 104 184 132 L182 190 Q196 214 184 226 L166 196 L90 196 L72 226 Q60 214 74 190 L72 120 Q80 64 150 60 Z', hair, 10),
    body: path('M20 256 Q26 212 92 200 L164 200 Q230 212 236 256 Z', k.tone('#C0293F', '#6A0F1E'), 9) +
      path('M100 200 L128 244 L156 200 Z', '#1E1E3A', 6) + `<path d="M104 200 L128 236 L152 200" fill="none" stroke="#FFFFFF" stroke-width="4"/>` +
      `<path d="M40 238 Q60 226 76 236 M180 236 Q196 226 216 238" stroke="#FF8A4D" stroke-width="5" fill="none" stroke-linecap="round"/>`,
    iris: ['#D8453A', '#4A0A12'], lid: 4,
    brows: `<path d="M94 120 Q106 118 120 120" fill="none" stroke="#4A0A12" stroke-width="5" stroke-linecap="round"/><path d="M162 120 Q150 118 136 120" fill="none" stroke="#4A0A12" stroke-width="5" stroke-linecap="round"/>`,
    mouth: `<path d="M120 172 L136 172" stroke="${INK}" stroke-width="5" stroke-linecap="round"/>`,
    blush: 0.3,
    frontHair: bangs('M78 128 Q70 70 128 60 Q186 70 178 128', 'Q176 100 162 92 L166 118 Q150 100 136 94 L138 110 Q124 96 110 94 L112 110 Q98 100 94 92 Q80 102 78 128', hair) +
      path('M78 126 Q70 160 80 190 L90 188 Q82 160 88 128 Z', hair, 6) + path('M178 126 Q186 160 176 190 L166 188 Q174 160 168 128 Z', hair, 6),
    faceMarks: `<path d="M148 96 Q156 84 166 92 Q162 96 170 104 Q160 104 158 112 Q150 106 146 110 Q148 102 148 96 Z" fill="#D8261E"/>`,
    acc: hanafuda(78) + hanafuda(178),
  });
  return k.done();
};

// ---------------------------------------------------------- FX + PATTERNS
A.fx_rays = () => { // 512 sunburst, white – tint with ImageColor3
  const k = icon(512);
  const g = k.rad([[0, '#FFFFFF', 1], [0.35, '#FFFFFF', 0.85], [1, '#FFFFFF', 0]], { r: 0.5 });
  let s = '';
  for (let i = 0; i < 16; i++) {
    const a0 = (i / 16) * Math.PI * 2; const a1 = a0 + Math.PI / 22;
    s += `<path d="M256 256 L${256 + Math.cos(a0) * 300} ${256 + Math.sin(a0) * 300} L${256 + Math.cos(a1) * 300} ${256 + Math.sin(a1) * 300} Z" fill="${g}"/>`;
  }
  k.add(s);
  return k.done();
};
A.fx_glow = () => {
  const k = icon();
  k.add(`<circle cx="128" cy="128" r="128" fill="${k.rad([[0, '#FFFFFF', 1], [0.4, '#FFFFFF', 0.55], [1, '#FFFFFF', 0]])}"/>`);
  return k.done();
};
A.fx_sparkles = () => {
  const k = icon();
  [[40, 50, 1.2], [200, 40, 0.8], [220, 180, 1.4], [60, 200, 0.9], [130, 120, 0.6]].forEach(([x, y, s]) => k.add(`<path d="M${x} ${y - 20 * s} Q${x + 3 * s} ${y - 3 * s} ${x + 20 * s} ${y} Q${x + 3 * s} ${y + 3 * s} ${x} ${y + 20 * s} Q${x - 3 * s} ${y + 3 * s} ${x - 20 * s} ${y} Q${x - 3 * s} ${y - 3 * s} ${x} ${y - 20 * s} Z" fill="#FFFFFF"/>`));
  return k.done();
};
// Seamless tiles (128) – white on transparent, tinted/faded in Roblox via ImageColor3/ImageTransparency.
A.pattern_diagonal = () => {
  const k = icon(128);
  k.add(`<path d="M0 32 L32 0 L64 0 L0 64 Z M0 96 L96 0 L128 0 L0 128 Z M32 128 L128 32 L128 64 L64 128 Z M96 128 L128 96 L128 128 Z" fill="#FFFFFF"/>`);
  return k.done();
};
A.pattern_dots = () => {
  const k = icon(128);
  k.add(`<circle cx="32" cy="32" r="9" fill="#FFFFFF"/><circle cx="96" cy="96" r="9" fill="#FFFFFF"/><circle cx="96" cy="32" r="4" fill="#FFFFFF"/><circle cx="32" cy="96" r="4" fill="#FFFFFF"/>`);
  return k.done();
};
A.pattern_tiles = () => { // embossed square tiles (cf. R2 panel texture)
  const k = icon(128);
  k.add(`<path d="M6 6 L58 6 L58 58 L6 58 Z M70 70 L122 70 L122 122 L70 122 Z" fill="none" stroke="#FFFFFF" stroke-width="5" stroke-linejoin="round"/>` +
    `<path d="M70 6 L122 6 L122 58 L70 58 Z M6 70 L58 70 L58 122 L6 122 Z" fill="#FFFFFF" opacity="0.45"/>`);
  return k.done();
};
A.pattern_stars = () => {
  const k = icon(128);
  const st = (x, y, s) => `<path d="M${x} ${y - 8 * s} L${x + 2 * s} ${y - 2 * s} L${x + 8 * s} ${y} L${x + 2 * s} ${y + 2 * s} L${x} ${y + 8 * s} L${x - 2 * s} ${y + 2 * s} L${x - 8 * s} ${y} L${x - 2 * s} ${y - 2 * s} Z" fill="#FFFFFF"/>`;
  k.add(st(24, 28, 1.3), st(92, 20, 0.7), st(70, 70, 1), st(110, 100, 1.2), st(30, 104, 0.8), `<circle cx="56" cy="40" r="2" fill="#FFF"/><circle cx="100" cy="60" r="2.5" fill="#FFF"/><circle cx="16" cy="70" r="2" fill="#FFF"/><circle cx="70" cy="116" r="2" fill="#FFF"/>`);
  return k.done();
};
A.pattern_hazard = () => { // diagonal hazard stripes for UNSAFE carry banner
  const k = icon(128);
  k.add(`<rect width="128" height="128" fill="#FFD23F"/><path d="M0 64 L64 0 L96 0 L0 96 Z M32 128 L128 32 L128 64 L64 128 Z M0 0 L32 0 L0 32 Z M96 128 L128 96 L128 128 Z" fill="${INK}"/>`);
  return k.done();
};
A.deco_rivet = () => { // corner bolt for panel rims (cf. R2)
  const k = icon(64);
  k.add(`<rect x="6" y="6" width="52" height="52" rx="14" fill="${k.tone('#FFF6A8', '#D98300', '#FFC21F')}" stroke="${INK}" stroke-width="6"/>`);
  k.add(`<rect x="14" y="12" width="36" height="14" rx="7" fill="#FFFFFF" opacity="0.6"/>`);
  return k.done();
};
A.deco_corner = () => { // ornamental gold corner bracket (top-left orientation)
  const k = icon(128);
  k.add(path('M12 12 L96 12 Q104 12 104 20 L104 30 L40 30 Q30 30 30 40 L30 104 L20 104 Q12 104 12 96 Z', k.tone('#FFF6A8', '#D98300', '#FFC21F'), 7));
  k.add(`<circle cx="30" cy="30" r="14" fill="#FF4F7E" stroke="${INK}" stroke-width="6"/><circle cx="26" cy="26" r="4" fill="#FFFFFF" opacity="0.8"/>`);
  return k.done();
};

module.exports = A;
