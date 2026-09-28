// Shared SVG drawing kit for StealAnimeEgg-UI-Lab original art.
// Every asset uses the same "ink" outline + glossy gradient construction so
// icons read as one family (see docs/DESIGN_SYSTEM.md).

const INK = '#1B1036';

let gid = 0;
function uid(p) { gid += 1; return `${p}${gid}`; }

// Vertical linear gradient def. stops: [[offset, color, opacity?], ...]
function lin(stops, { x1 = 0, y1 = 0, x2 = 0, y2 = 1 } = {}) {
  const id = uid('g');
  const s = stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('');
  return { id, def: `<linearGradient id="${id}" x1="${x1}" y1="${y1}" x2="${x2}" y2="${y2}">${s}</linearGradient>`, url: `url(#${id})` };
}

function rad(stops, { cx = 0.5, cy = 0.5, r = 0.5, fx, fy } = {}) {
  const id = uid('r');
  const s = stops.map(([o, c, a = 1]) => `<stop offset="${o}" stop-color="${c}" stop-opacity="${a}"/>`).join('');
  const f = fx !== undefined ? ` fx="${fx}" fy="${fy}"` : '';
  return { id, def: `<radialGradient id="${id}" cx="${cx}" cy="${cy}" r="${r}"${f}>${s}</radialGradient>`, url: `url(#${id})` };
}

// Two-tone "toy plastic" gradient from a light top to a saturated bottom.
function tone(top, bottom, mid) {
  return mid ? lin([[0, top], [0.5, mid], [1, bottom]]) : lin([[0, top], [1, bottom]]);
}

// Shape with ink outline painted behind the fill (sticker look).
function ink(tag, attrs, w = 10) {
  const a = Object.entries(attrs).map(([k, v]) => `${k}="${v}"`).join(' ');
  return `<${tag} ${a} stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" paint-order="stroke"/>`;
}
function path(d, fill, w = 10, extra = '') {
  return `<path d="${d}" fill="${fill}" stroke="${INK}" stroke-width="${w}" stroke-linejoin="round" stroke-linecap="round" paint-order="stroke" ${extra}/>`;
}
function plain(d, fill, extra = '') { return `<path d="${d}" fill="${fill}" ${extra}/>`; }
// Thick rounded stroke with an ink outline (two passes) – used for limbs, streaks.
function tube(d, color, w, outline = 10, extra = '') {
  return `<path d="${d}" fill="none" stroke="${INK}" stroke-width="${w + outline * 2}" stroke-linecap="round" stroke-linejoin="round"/>` +
    `<path d="${d}" fill="none" stroke="${color}" stroke-width="${w}" stroke-linecap="round" stroke-linejoin="round" ${extra}/>`;
}
// White gloss highlight (a soft crescent) – the signature shine.
function gloss(d, a = 0.75) {
  const g = lin([[0, '#FFFFFF', a], [1, '#FFFFFF', 0]]);
  return { def: g.def, svg: `<path d="${d}" fill="${g.url}"/>` };
}
function spark(x, y, s = 1, color = '#FFFFFF') {
  const d = `M${x} ${y - 14 * s} Q${x + 2.5 * s} ${y - 2.5 * s} ${x + 14 * s} ${y} Q${x + 2.5 * s} ${y + 2.5 * s} ${x} ${y + 14 * s} Q${x - 2.5 * s} ${y + 2.5 * s} ${x - 14 * s} ${y} Q${x - 2.5 * s} ${y - 2.5 * s} ${x} ${y - 14 * s}Z`;
  return `<path d="${d}" fill="${color}" stroke="${INK}" stroke-width="${4 * s}" paint-order="stroke" stroke-linejoin="round"/>`;
}

function svg(size, defs, body, vb) {
  const [w, h] = Array.isArray(size) ? size : [size, size];
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="${vb || `0 0 ${w} ${h}`}"><defs>${defs.join('')}</defs>${body.join('')}</svg>\n`;
}

// Tiny builder so each icon can collect defs + body in order.
function icon(size = 256) {
  const defs = []; const body = [];
  return {
    INK,
    lin(...a) { const g = lin(...a); defs.push(g.def); return g.url; },
    rad(...a) { const g = rad(...a); defs.push(g.def); return g.url; },
    tone(...a) { const g = tone(...a); defs.push(g.def); return g.url; },
    gloss(d, a) { const g = gloss(d, a); defs.push(g.def); body.push(g.svg); },
    add(...s) { body.push(...s); },
    def(s) { defs.push(s); },
    done(vb) { return svg(size, defs, body, vb); },
  };
}

module.exports = { INK, icon, path, plain, ink, tube, spark, svg, lin, rad, uid };
