/* Browser preview controller. Mirrors src/client/UIController.lua (navigation,
 * hover/press, auto-scale) and src/client/PREVIEW_Controller.client.lua
 * (sample-data driven preview states). SAMPLE DATA ONLY. */
(function () {
  const R = window.RbxRender;
  const tree = window.UI_TREE;
  const D = JSON.parse(JSON.stringify(window.SAMPLE));
  const screen = document.getElementById('screen');
  const stage = document.getElementById('stage');
  const find = (p) => R.find(tree, p);
  const set = (p, k, v) => { const n = typeof p === 'string' ? find(p) : p; if (n) n.p[k] = v; return n; };
  const kids = (n) => (n ? n.ch : []);
  const desc = (n, pred) => R.descendants(n, pred);
  const MENUS = ['Shop', 'Index', 'Eggs', 'Characters', 'Upgrade'];

  const S = {
    w: 1280, h: 720, menu: null, carry: 'UNSAFE', hatch: 'HATCHING', timer: null,
    discovered: new Set(D.index.discovered), upgradeTab: 'Character', allMax: false,
  };

  // ------------------------------------------------------------ state → tree
  function applyState() {
    // auto-scale (same formula as UIController.lua)
    const scale = Math.max(0.45, Math.min(2, Math.min(S.w / 1280, S.h / 720)));
    desc(tree, (n) => n.c === 'UIScale' && n.n === 'AutoScale').forEach((n) => { n.p.Scale = scale; });
    // menus + nav selection
    MENUS.forEach((m) => {
      set(`${m}Menu`, 'Visible', S.menu === m);
      const b = find(`Nav.${m}Button`);
      if (b) set(R.find(b, 'SelectedGlow'), 'Visible', S.menu === m);
    });
    set('MenuBackdrop', 'Visible', !!S.menu);
    // carry
    set('EggCarry', 'Visible', S.carry !== 'HIDDEN');
    set('EggCarry.Unsafe', 'Visible', S.carry === 'UNSAFE');
    set('EggCarry.Secured', 'Visible', S.carry === 'SECURED');
    // hatch widget
    set('HatchTimer.StateHatching', 'Visible', S.hatch === 'HATCHING');
    set('HatchTimer.StateReady', 'Visible', S.hatch === 'READY');
    const title = find('HatchTimer.TitleRibbon.Title'); if (title) title.p.Text = S.hatch === 'READY' ? 'EGG READY' : 'HATCHING';
    if (window.PreviewStates) window.PreviewStates.apply(S, D, { find, set, desc, tree });
  }

  // ----------------------------------------------------------------- render
  function render() {
    stage.style.width = `${S.w}px`; stage.style.height = `${S.h}px`;
    const wrap = document.getElementById('wrap');
    const fit = Math.min(1, (wrap.clientWidth - 24) / S.w, (wrap.clientHeight - 24) / S.h);
    stage.style.transform = `scale(${fit})`;
    applyState();
    R.render(tree, screen, {
      manifest: window.ASSET_MANIFEST,
      assetUrl: (k) => window.ASSET_DATA[k],
      onElement: bindElement,
    });
  }

  // ------------------------------------------------ hover / press / clicks
  function bindElement(el, n) {
    if (!(n.c === 'TextButton' || n.c === 'ImageButton')) return;
    const face = [...el.children].find((c) => c.dataset && c.dataset.name === 'Face');
    const lip = (n.a && n.a.LipDepth) || 6;
    const base = el.style.transform || '';
    el.addEventListener('mouseenter', () => { el.style.transform = `${base} scale(1.05)`; el.style.transition = 'transform .12s'; el.style.filter = 'brightness(1.08)'; });
    el.addEventListener('mouseleave', () => { el.style.transform = base; el.style.filter = ''; if (face) face.style.top = '0px'; });
    el.addEventListener('mousedown', () => { if (face) face.style.top = `${lip - 2}px`; el.style.transform = `${base} scale(0.97)`; });
    el.addEventListener('mouseup', () => { if (face) face.style.top = '0px'; el.style.transform = `${base} scale(1.05)`; });
    el.addEventListener('click', (e) => { e.stopPropagation(); onClick(n); });
  }
  function onClick(n) {
    const a = n.a || {};
    if (a.NavTarget) { S.menu = S.menu === a.NavTarget ? null : a.NavTarget; return render(); }
    if (a.Action === 'CloseMenu') { S.menu = null; return render(); }
    if (a.PreviewAction) return act(a.PreviewAction);
    if (window.PreviewStates && window.PreviewStates.click(n, S, D, act)) return render();
  }

  // ---------------------------------------------------------------- actions
  function act(action) {
    const [k, v, w2] = action.split(':');
    if (k === 'menu') S.menu = v === 'none' ? null : v;
    else if (k === 'carry') S.carry = v.toUpperCase();
    else if (k === 'hatch' && v !== 'start') { S.hatch = v.toUpperCase(); }
    else if (window.PreviewStates) window.PreviewStates.action(k, v, w2, S, D, { render });
    render();
  }

  window.Lab = { S, D, act, render, setDevice(w, h) { S.w = w; S.h = h; render(); }, tree };

  document.querySelectorAll('#bar button[data-dev]').forEach((b) => b.addEventListener('click', () => {
    document.querySelectorAll('#bar button[data-dev]').forEach((x) => x.classList.remove('on'));
    b.classList.add('on');
    const [w, h] = b.dataset.dev.split('x').map(Number); window.Lab.setDevice(w, h);
  }));
  window.addEventListener('resize', render);
  const q = new URLSearchParams(location.search);
  if (q.get('w')) { S.w = +q.get('w'); S.h = +q.get('h'); }
  document.fonts.load("20px 'Luckiest Guy'").then(() => document.fonts.load("600 20px 'Fredoka'")).then(() => {
    (q.get('actions') || '').split(',').filter(Boolean).forEach((a) => act(a));
    render();
    document.body.dataset.ready = '1';
  });
})();
