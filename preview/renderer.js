/* StealAnimeEgg-UI-Lab — browser approximation of the Roblox GUI tree.
 *
 * Interprets the same instance tree that is exported to .rbxmx (preview/data/ui-tree.js)
 * using Roblox layout semantics: UDim2 + AnchorPoint, UIPadding, UIListLayout,
 * UIGridLayout, UIScale, UIAspectRatioConstraint, AutomaticSize, UICorner,
 * UIStroke (Border/Contextual), UIGradient, ImageRect atlases, ImageColor3 multiply.
 *
 * It is a design-review tool, NOT a Roblox renderer: fonts, text metrics and some
 * edge cases differ slightly from Roblox Studio.
 */
(function () {
  const FONT = {
    'rbxasset://fonts/families/LuckiestGuy.json': { family: "'Luckiest Guy'", weight: 400, lh: 1.0, dy: 0.08 },
    'rbxasset://fonts/families/FredokaOne.json': { family: "'Fredoka'", weight: 600, lh: 1.05, dy: 0.02 },
  };
  const LAYOUT_CLASSES = new Set(['UIListLayout', 'UIGridLayout']);
  const GUI = new Set(['Frame', 'TextLabel', 'TextButton', 'ImageLabel', 'ImageButton', 'ScrollingFrame', 'ViewportFrame', 'CanvasGroup', 'TextBox']);

  const mctx = document.createElement('canvas').getContext('2d');

  const P = (n, k, d) => (n.p[k] !== undefined ? n.p[k] : d);
  const V = (x) => (x && x.v !== undefined ? x.v : x);
  const rgb = (c, a = 1) => `rgba(${Math.round(c[0] * 255)},${Math.round(c[1] * 255)},${Math.round(c[2] * 255)},${a})`;
  const mods = (n, cls) => n.ch.filter((c) => c.c === cls);
  const mod = (n, cls) => n.ch.find((c) => c.c === cls);

  function fontOf(n) {
    const f = V(P(n, 'FontFace', null));
    return FONT[f && f.family] || FONT['rbxasset://fonts/families/FredokaOne.json'];
  }
  function richToHtml(t, rich) {
    const e = t.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
    if (!rich) return e.replace(/\n/g, '<br>');
    return e.replace(/&lt;font color="([^"]+)"&gt;/g, '<span style="color:$1">').replace(/&lt;\/font&gt;/g, '</span>')
      .replace(/&lt;b&gt;/g, '<b>').replace(/&lt;\/b&gt;/g, '</b>').replace(/&lt;br\s*\/?&gt;/g, '<br>').replace(/\n/g, '<br>');
  }
  function stripRich(t) { return t.replace(/<[^>]+>/g, ''); }
  function measure(n) {
    const f = fontOf(n); const ts = P(n, 'TextSize', 14);
    mctx.font = `${f.weight} ${ts}px ${f.family}`;
    const st = mod(n, 'UIStroke');
    const lines = stripRich(P(n, 'Text', '')).split('\n');
    const w = Math.max(...lines.map((l) => mctx.measureText(l).width));
    return { w: Math.ceil(w + (st ? V(st.p.Thickness) * 2 : 0) + 2), h: Math.ceil(ts * f.lh * lines.length) };
  }

  // ------------------------------------------------------------- geometry
  function resolveSize(n, cw, ch) {
    const s = V(P(n, 'Size', { v: [0, 100, 0, 100] })) || [0, 100, 0, 100];
    let w = s[0] * cw + s[1]; let h = s[2] * ch + s[3];
    const ar = mod(n, 'UIAspectRatioConstraint');
    if (ar) {
      const r = P(ar, 'AspectRatio', 1);
      if (w / h > r) w = h * r; else h = w / r;
    }
    const sc = mod(n, 'UISizeConstraint');
    if (sc) {
      const mn = V(sc.p.MinSize) || [0, 0]; const mx = V(sc.p.MaxSize) || [1e9, 1e9];
      w = Math.min(Math.max(w, mn[0]), mx[0]); h = Math.min(Math.max(h, mn[1]), mx[1]);
    }
    const auto = P(n, 'AutomaticSize', 'None');
    if (auto !== 'None') {
      const content = autoContent(n, w, h);
      if (auto === 'X' || auto === 'XY') w = Math.max(w, content.w);
      if (auto === 'Y' || auto === 'XY') h = Math.max(h, content.h);
    }
    return { w, h };
  }
  function paddingOf(n, w, h) {
    const p = mod(n, 'UIPadding');
    if (!p) return { t: 0, r: 0, b: 0, l: 0 };
    const u = (k, base) => { const x = V(p.p[k]) || [0, 0]; return x[0] * base + x[1]; };
    return { t: u('PaddingTop', h), r: u('PaddingRight', w), b: u('PaddingBottom', h), l: u('PaddingLeft', w) };
  }
  function autoContent(n, w, h) {
    if (n.c === 'TextLabel' || n.c === 'TextButton') { const m = measure(n); const pd = paddingOf(n, w, h); return { w: m.w + pd.l + pd.r, h: m.h + pd.t + pd.b }; }
    const pd = paddingOf(n, w, h);
    const rects = layoutChildren(n, w - pd.l - pd.r, h - pd.t - pd.b);
    let mx = 0; let my = 0;
    rects.forEach((r) => { mx = Math.max(mx, r.x + r.w); my = Math.max(my, r.y + r.h); });
    return { w: mx + pd.l + pd.r, h: my + pd.t + pd.b };
  }
  function guiKids(n) { return n.ch.filter((c) => GUI.has(c.c) && P(c, 'Visible', true) !== false); }
  function sortKids(kids, layout) {
    const idx = new Map(kids.map((k, i) => [k, i]));
    if (layout && P(layout, 'SortOrder', 'LayoutOrder') === 'Name') return kids.slice().sort((a, b) => a.n.localeCompare(b.n));
    return kids.slice().sort((a, b) => (P(a, 'LayoutOrder', 0) - P(b, 'LayoutOrder', 0)) || (idx.get(a) - idx.get(b)));
  }
  // Returns array of {n, x, y, w, h} in the parent's content box.
  function layoutChildren(n, cw, ch) {
    const kids = guiKids(n);
    const layout = n.ch.find((c) => LAYOUT_CLASSES.has(c.c));
    if (!layout) {
      return kids.map((k) => {
        const { w, h } = resolveSize(k, cw, ch);
        const pos = V(P(k, 'Position', null)) || [0, 0, 0, 0];
        const ap = V(P(k, 'AnchorPoint', null)) || [0, 0];
        return { n: k, x: pos[0] * cw + pos[1] - ap[0] * w, y: pos[2] * ch + pos[3] - ap[1] * h, w, h };
      });
    }
    const sorted = sortKids(kids, layout);
    const ha = P(layout, 'HorizontalAlignment', 'Center'); const va = P(layout, 'VerticalAlignment', 'Center');
    if (layout.c === 'UIListLayout') {
      const dir = P(layout, 'FillDirection', 'Vertical');
      const pad = V(P(layout, 'Padding', null)) || [0, 0];
      const padPx = pad[0] * (dir === 'Vertical' ? ch : cw) + pad[1];
      const sizes = sorted.map((k) => ({ n: k, ...resolveSize(k, cw, ch) }));
      const total = sizes.reduce((s, r) => s + (dir === 'Vertical' ? r.h : r.w), 0) + padPx * Math.max(0, sizes.length - 1);
      let cur;
      if (dir === 'Vertical') cur = va === 'Top' ? 0 : va === 'Bottom' ? ch - total : (ch - total) / 2;
      else cur = ha === 'Left' ? 0 : ha === 'Right' ? cw - total : (cw - total) / 2;
      return sizes.map((r) => {
        let x; let y;
        if (dir === 'Vertical') { y = cur; cur += r.h + padPx; x = ha === 'Left' ? 0 : ha === 'Right' ? cw - r.w : (cw - r.w) / 2; }
        else { x = cur; cur += r.w + padPx; y = va === 'Top' ? 0 : va === 'Bottom' ? ch - r.h : (ch - r.h) / 2; }
        return { ...r, x, y };
      });
    }
    // UIGridLayout
    const cs = V(P(layout, 'CellSize', null)) || [0, 100, 0, 100];
    const cp = V(P(layout, 'CellPadding', null)) || [0, 5, 0, 5];
    const cellW = cs[0] * cw + cs[1]; const cellH = cs[2] * ch + cs[3];
    const padX = cp[0] * cw + cp[1]; const padY = cp[2] * ch + cp[3];
    const maxCells = P(layout, 'FillDirectionMaxCells', 0);
    let cols = Math.max(1, Math.floor((cw + padX) / (cellW + padX)));
    if (maxCells > 0) cols = Math.min(cols, maxCells);
    cols = Math.min(cols, Math.max(1, sorted.length));
    const rows = Math.ceil(sorted.length / cols);
    const blockW = cols * cellW + (cols - 1) * padX; const blockH = rows * cellH + (rows - 1) * padY;
    const ox = ha === 'Left' ? 0 : ha === 'Right' ? cw - blockW : (cw - blockW) / 2;
    const oy = va === 'Top' ? 0 : va === 'Bottom' ? ch - blockH : (ch - blockH) / 2;
    return sorted.map((k, i) => ({ n: k, x: ox + (i % cols) * (cellW + padX), y: oy + Math.floor(i / cols) * (cellH + padY), w: cellW, h: cellH }));
  }

  // --------------------------------------------------------------- paint
  function gradientCss(g, base, alpha, w, h) {
    const cs = V(g.p.Color) || [[0, 1, 1, 1], [1, 1, 1, 1]];
    const ts = V(g.p.Transparency) || [[0, 0], [1, 0]];
    const rot = P(g, 'Rotation', 0);
    const times = [...new Set([...cs.map((k) => k[0]), ...ts.map((k) => k[0])])].sort((a, b) => a - b);
    const at = (seq, t, n) => {
      for (let i = 0; i < seq.length - 1; i++) {
        if (t >= seq[i][0] && t <= seq[i + 1][0]) {
          const f = (t - seq[i][0]) / ((seq[i + 1][0] - seq[i][0]) || 1);
          return seq[i].slice(1, 1 + n).map((v, j) => v + (seq[i + 1][1 + j] - v) * f);
        }
      }
      return seq[seq.length - 1].slice(1, 1 + n);
    };
    const stops = times.map((t) => {
      const c = at(cs, t, 3); const tr = at(ts, t, 1)[0];
      return `${rgb([c[0] * base[0], c[1] * base[1], c[2] * base[2]], alpha * (1 - tr))} ${(t * 100).toFixed(2)}%`;
    });
    // Roblox gradients span the box along the rotated axis; approximate with CSS angle.
    return `linear-gradient(${rot + 90}deg, ${stops.join(', ')})`;
  }
  function radiusOf(n, w, h) {
    const c = mod(n, 'UICorner'); if (!c) return 0;
    const r = V(c.p.CornerRadius) || [0, 8];
    return Math.min(r[0] * Math.min(w, h) + r[1], Math.min(w, h) / 2);
  }

  function render(n, parentEl, rect, ctx) {
    const el = document.createElement('div');
    el.className = `rbx ${n.c}`;
    el.dataset.name = n.n;
    el.__node = n;
    const s = el.style;
    s.left = `${rect.x}px`; s.top = `${rect.y}px`; s.width = `${rect.w}px`; s.height = `${rect.h}px`;
    const { w, h } = rect;
    const radius = radiusOf(n, w, h);
    if (radius) s.borderRadius = `${radius}px`;

    // transforms: UIScale about anchor point + Rotation about centre
    const tf = [];
    const us = mod(n, 'UIScale');
    const scale = us ? P(us, 'Scale', 1) : 1;
    if (scale !== 1) {
      const ap = V(P(n, 'AnchorPoint', null)) || [0, 0];
      const dx = (ap[0] - 0.5) * w; const dy = (ap[1] - 0.5) * h;
      tf.push(`translate(${dx}px,${dy}px) scale(${scale}) translate(${-dx}px,${-dy}px)`);
    }
    const rot = P(n, 'Rotation', 0);
    if (rot) tf.push(`rotate(${rot}deg)`);
    if (tf.length) s.transform = tf.join(' ');

    // background
    const bgT = P(n, 'BackgroundTransparency', 0);
    const bg = V(P(n, 'BackgroundColor3', null)) || [0.64, 0.64, 0.64];
    const grad = mod(n, 'UIGradient');
    const isText = n.c === 'TextLabel' || n.c === 'TextButton';
    const isImage = n.c === 'ImageLabel' || n.c === 'ImageButton';
    if (bgT < 1) {
      if (grad && !isText && !isImage) s.backgroundImage = gradientCss(grad, bg, 1 - bgT, w, h);
      else s.backgroundColor = rgb(bg, 1 - bgT);
    }
    // border strokes (outside, like UIStroke Border)
    const strokes = mods(n, 'UIStroke').filter((st) => !isText || P(st, 'ApplyStrokeMode', 'Contextual') === 'Border');
    if (strokes.length) {
      let acc = 0;
      s.boxShadow = strokes.map((st) => { const t = P(st, 'Thickness', 1); acc += t; return `0 0 0 ${t}px ${rgb(V(st.p.Color) || [0, 0, 0], 1 - P(st, 'Transparency', 0))}`; }).reverse().join(',');
      // Roblox draws each stroke independently at the same edge; approximate by nesting spreads
      s.boxShadow = strokes.map((st) => `0 0 0 ${P(st, 'Thickness', 1)}px ${rgb(V(st.p.Color) || [0, 0, 0], 1 - P(st, 'Transparency', 0))}`).join(',');
    }
    if (P(n, 'ClipsDescendants', false) || n.c === 'ScrollingFrame') s.overflow = 'hidden';
    if (n.c === 'TextButton' || n.c === 'ImageButton') { el.classList.add('btn'); }

    if (isImage) paintImage(n, el, w, h, ctx);
    if (isText) paintText(n, el, w, h, grad);

    parentEl.appendChild(el);
    ctx.onElement && ctx.onElement(el, n);

    // children
    const pd = paddingOf(n, w, h);
    let cw = w - pd.l - pd.r; let chh = h - pd.t - pd.b;
    let container = el;
    if (n.c === 'ScrollingFrame') {
      const canvas = document.createElement('div');
      canvas.className = 'canvas';
      const auto = P(n, 'AutomaticCanvasSize', 'None');
      const cvs = V(P(n, 'CanvasSize', null)) || [0, 0, 2, 0];
      let canvasH = cvs[2] * h + cvs[3];
      if (auto === 'Y' || auto === 'XY') {
        const rects = layoutChildren(n, cw, chh);
        rects.forEach((r) => { canvasH = Math.max(canvasH, r.y + r.h + pd.t + pd.b); });
      }
      canvasH = Math.max(canvasH, h);
      el.style.overflowY = 'auto'; el.classList.add('scroll');
      canvas.style.height = `${canvasH}px`;
      el.appendChild(canvas);
      container = canvas;
      chh = canvasH - pd.t - pd.b;
      if (auto === 'Y' || auto === 'XY') chh = h - pd.t - pd.b; // scale children against visible size
    }
    const rects = layoutChildren(n, cw, chh);
    const order = rects.map((r, i) => ({ r, i })).sort((a, b) => (P(a.r.n, 'ZIndex', 1) - P(b.r.n, 'ZIndex', 1)) || (a.i - b.i));
    order.forEach(({ r }) => render(r.n, container, { x: r.x + pd.l, y: r.y + pd.t, w: r.w, h: r.h }, ctx));
    return el;
  }

  function paintText(n, el, w, h, grad) {
    const f = fontOf(n);
    const ts = P(n, 'TextSize', 14);
    let size = ts;
    const text = P(n, 'Text', '');
    if (P(n, 'TextScaled', false)) {
      const c = mod(n, 'UITextSizeConstraint');
      size = Math.min(h / f.lh, c ? P(c, 'MaxTextSize', 100) : 100);
      mctx.font = `${f.weight} ${size}px ${f.family}`;
      const tw = mctx.measureText(stripRich(text)).width;
      if (tw > w) size *= w / tw;
    }
    const xa = P(n, 'TextXAlignment', 'Center'); const ya = P(n, 'TextYAlignment', 'Center');
    const color = V(P(n, 'TextColor3', null)) || [0, 0, 0];
    const tt = P(n, 'TextTransparency', 0);
    const st = mods(n, 'UIStroke').find((x) => P(x, 'ApplyStrokeMode', 'Contextual') === 'Contextual');
    const html = richToHtml(text, P(n, 'RichText', false));
    const mk = (cls) => {
      const d = document.createElement('div');
      d.className = `txt ${cls}`;
      const ds = d.style;
      ds.fontFamily = f.family; ds.fontWeight = f.weight; ds.fontSize = `${size}px`; ds.lineHeight = `${f.lh}`;
      ds.justifyContent = xa === 'Left' ? 'flex-start' : xa === 'Right' ? 'flex-end' : 'center';
      ds.textAlign = xa === 'Left' ? 'left' : xa === 'Right' ? 'right' : 'center';
      ds.alignItems = ya === 'Top' ? 'flex-start' : ya === 'Bottom' ? 'flex-end' : 'center';
      ds.whiteSpace = P(n, 'TextWrapped', false) ? 'normal' : 'nowrap';
      ds.paddingTop = `${size * f.dy}px`;
      const pd = paddingOf(n, w, h);
      ds.padding = `${pd.t + size * f.dy}px ${pd.r}px ${pd.b}px ${pd.l}px`;
      d.innerHTML = `<span>${html}</span>`;
      return d;
    };
    if (st) {
      const t = P(st, 'Thickness', 1);
      const sc = V(st.p.Color) || [0, 0, 0];
      const d = mk('stroke');
      d.style.color = rgb(sc, (1 - P(st, 'Transparency', 0)) * (1 - tt));
      d.style.webkitTextStroke = `${t * 2}px ${rgb(sc, (1 - P(st, 'Transparency', 0)) * (1 - tt))}`;
      d.querySelectorAll('span span').forEach((x) => { x.style.color = 'inherit'; });
      el.appendChild(d);
    }
    const d = mk('fill');
    if (grad) {
      const span = d.firstChild;
      span.style.backgroundImage = gradientCss(grad, color, 1 - tt, w, h).replace(/linear-gradient\((\d+(\.\d+)?)deg/, (m, a) => `linear-gradient(${a}deg`);
      span.style.webkitBackgroundClip = 'text'; span.style.backgroundClip = 'text';
      span.style.color = 'transparent';
    } else {
      d.style.color = rgb(color, 1 - tt);
    }
    el.appendChild(d);
  }

  function paintImage(n, el, w, h, ctx) {
    const key = n.a && n.a.AssetKey;
    const m = key && ctx.manifest.images[key];
    if (!m) return;
    const src = ctx.assetUrl(m.atlas ? m.atlas : m.standalone);
    const atlasSize = m.atlas ? ctx.manifest.atlases[m.atlas].size : m.size;
    const rw = m.size[0]; const rh = m.size[1];
    const ox = m.atlas ? m.offset[0] : 0; const oy = m.atlas ? m.offset[1] : 0;
    const inner = document.createElement('div');
    inner.className = 'img';
    const is = inner.style;
    const scaleType = P(n, 'ScaleType', 'Stretch');
    let bgSize; let bgPos; let repeat = 'no-repeat';
    if (scaleType === 'Tile') {
      const t = V(P(n, 'TileSize', null)) || [1, 0, 1, 0];
      const tw = t[0] * w + t[1]; const th = t[2] * h + t[3];
      is.left = '0px'; is.top = '0px'; is.width = `${w}px`; is.height = `${h}px`;
      bgSize = `${tw}px ${th}px`; bgPos = '0 0'; repeat = 'repeat';
    } else {
      let sx = w / rw; let sy = h / rh;
      if (scaleType === 'Fit') { sx = sy = Math.min(sx, sy); } else if (scaleType === 'Crop') { sx = sy = Math.max(sx, sy); }
      const dw = rw * sx; const dh = rh * sy;
      is.left = `${(w - dw) / 2}px`; is.top = `${(h - dh) / 2}px`; is.width = `${dw}px`; is.height = `${dh}px`;
      bgSize = `${atlasSize[0] * sx}px ${atlasSize[1] * sy}px`; bgPos = `${-ox * sx}px ${-oy * sy}px`;
      if (scaleType === 'Crop') { el.style.overflow = 'hidden'; }
    }
    const tint = V(P(n, 'ImageColor3', null));
    const it = P(n, 'ImageTransparency', 0);
    is.backgroundImage = `url(${src})`; is.backgroundSize = bgSize; is.backgroundPosition = bgPos; is.backgroundRepeat = repeat;
    if (tint && !(tint[0] > 0.99 && tint[1] > 0.99 && tint[2] > 0.99)) {
      is.backgroundColor = rgb(tint); is.backgroundBlendMode = 'multiply';
      is.webkitMaskImage = `url(${src})`; is.webkitMaskSize = bgSize; is.webkitMaskPosition = bgPos; is.webkitMaskRepeat = repeat;
    }
    if (it) is.opacity = 1 - it;
    const radius = radiusOf(n, w, h);
    if (radius) { el.style.overflow = 'hidden'; }
    el.appendChild(inner);
  }

  window.RbxRender = {
    // root: ScreenGui JSON. host: element sized to the viewport.
    render(root, host, ctx) {
      host.innerHTML = '';
      const w = host.clientWidth; const h = host.clientHeight;
      const rects = layoutChildren(root, w, h);
      const order = rects.map((r, i) => ({ r, i })).sort((a, b) => (P(a.r.n, 'ZIndex', 1) - P(b.r.n, 'ZIndex', 1)) || (a.i - b.i));
      order.forEach(({ r }) => render(r.n, host, r, ctx));
    },
    find(root, pathStr) {
      let cur = root;
      for (const part of pathStr.split('.')) { cur = cur && cur.ch.find((c) => c.n === part); }
      return cur;
    },
    descendants(root, pred, out = []) { root.ch.forEach((c) => { if (pred(c)) out.push(c); window.RbxRender.descendants(c, pred, out); }); return out; },
  };
})();
