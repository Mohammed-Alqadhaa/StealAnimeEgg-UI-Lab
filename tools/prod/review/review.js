/* Production UI review harness — fills the production templates with MOCK values
 * (layout review only) the same way game/src/client/UI does at runtime, then renders
 * with the UI Lab browser renderer. Not game data; not Roblox Studio. */
(function () {
  const R = window.RbxRender;
  const G = window.GAME;
  const q = new URLSearchParams(location.search);
  const W = +(q.get('w') || 1280), H = +(q.get('h') || 720);
  const state = q.get('state') || 'hud';
  const tree = window.UI_TREE;
  const find = (n, p) => R.find(n, p);
  const clone = (n) => JSON.parse(JSON.stringify(n));
  const hex = (h) => { const x = h.replace('#', ''); return [0, 2, 4].map((i) => parseInt(x.slice(i, i + 2), 16) / 255); };
  const setText = (n, p, t) => { const x = p ? find(n, p) : n; if (x) x.p.Text = t; };
  const show = (n, p, v = true) => { const x = p ? find(n, p) : n; if (x) x.p.Visible = v; };
  const tpl = (menu, name) => clone(find(tree, `${menu}.Rim.Body.Content.Templates.${name}`));
  const content = (menu) => find(tree, `${menu}.Rim.Body.Content`);
  const fmt = (n) => { const u = ['', 'K', 'M', 'B', 'T']; let i = 0; while (n >= 1000 && i < u.length - 1) { n /= 1000; i++; } return (i ? n.toFixed(n < 10 ? 2 : 1).replace(/\.?0+$/, '') : Math.floor(n)) + u[i]; };
  const tint = (card, pal) => {
    const face = find(card, 'Face'); const g = face && face.ch.find((c) => c.c === 'UIGradient');
    if (g) g.p.Color = { t: 'ColorSequence', v: [[0, ...hex(pal.glow)], [0.5, ...hex(pal.accent)], [1, ...hex(pal.wall)]] };
  };
  // ViewportFrames can't render in a browser: draw a placeholder silhouette tag
  const vp = (n, text, dark) => {
    const v = R.descendants(n, (c) => c.c === 'ViewportFrame')[0]; if (!v) return;
    v.p.BackgroundTransparency = 1;
    v.ch.push({ c: 'TextLabel', n: 'ReviewPH', a: {}, ch: [], p: { Size: { t: 'UDim2', v: [1, 0, 1, 0] }, BackgroundTransparency: 1, Text: text, TextSize: 12, TextColor3: { t: 'Color3', v: dark ? [0.3, 0.3, 0.4] : [1, 1, 1] }, TextTransparency: 0.2 } });
  };
  const menu = (m) => { show(tree, `${m}Menu`); show(tree, 'MenuBackdrop'); const b = find(tree, `Nav.${m}Button.SelectedGlow`); if (b) b.p.Visible = true; };
  const chars = (w) => G.worlds[w].roster.map((id) => ({ id, ...G.characters[id] }));

  // HUD (always)
  setText(tree, 'HUD.Speed.Pill.Value', '1,240');
  setText(tree, 'HUD.Cash.Pill.Value', '$48.2K');
  setText(tree, 'HUD.Cash.Pill.Rate', '+$312/s');
  setText(tree, 'RoundTimer.Pill.Phase', 'ROUND 3 • FOG GATE OPEN');
  setText(tree, 'RoundTimer.Pill.Time', '3:42');

  const S = {
    hud() {
      show(tree, 'HatchTimer'); vp(find(tree, 'HatchTimer'), 'EGG 3D');
      setText(tree, 'HatchTimer.StateHatching.EggName', 'Gojo Egg'); setText(tree, 'HatchTimer.StateHatching.TimerRow.Timer', '0:42');
      setText(tree, 'HatchTimer.More', '+2');
      show(tree, 'EggCarry'); vp(find(tree, 'EggCarry.Unsafe'), 'EGG 3D');
      const nb = find(tree, 'Nav.EggsButton.Badge'); if (nb) nb.p.Visible = true;
      const t = find(tree, 'Toasts'); const tt = clone(find(t, 'Templates.Toast')); setText(tt, 'Text', 'Egg picked up - Reach the Farm Safe Zone!'); tt.n = 'T1'; t.ch.push(tt);
    },
    index() {
      menu('Index'); const c = content('IndexMenu');
      const tabs = find(c, 'Sidebar.Tabs');
      G.order.forEach((w, i) => { const t = tpl('IndexMenu', 'WorldTab'); t.p.LayoutOrder = i; setText(t, 'Active.Face.Content.Label', G.worlds[w].name.toUpperCase()); setText(t, 'Inactive.Face.Content.Label', G.worlds[w].name.toUpperCase());
        const n = i === 0 ? 3 : i === 1 ? 1 : 0; setText(t, 'Active.Face.Content.Count', `${n}/5`); setText(t, 'Inactive.Face.Content.Count', `${n}/5`);
        show(t, 'Active', i === 0); show(t, 'Inactive', i !== 0); t.n = 'Tab_' + w; tabs.ch.push(t); });
      const w = 'DemonSlayer'; const pal = G.worlds[w].palette;
      setText(c, 'Header.World', G.worlds[w].name.toUpperCase()); setText(c, 'Header.Discovered', '3 / 5 Discovered');
      const tot = find(c, 'Header.Total'); setText(tot, 'Text', '4 / 45'); find(tot, 'Fill').p.Size = { t: 'UDim2', v: [4 / 45, 0, 1, 0] };
      const grid = find(c, 'Grid');
      chars(w).forEach((ch, i) => { const card = tpl('IndexMenu', 'IndexCard'); card.p.LayoutOrder = i; card.n = 'Card_' + ch.id; const found = i < 3;
        if (found) { tint(card, pal); setText(card, 'NamePlate.Name', ch.name.toUpperCase()); show(card, 'LockBadge', false); }
        show(card, 'BossTag', ch.isBoss && found); vp(card, found ? 'MODEL' : 'SILHOUETTE', !found); grid.ch.push(card); });
    },
    eggs() {
      menu('Eggs'); const c = content('EggsMenu'); const grid = find(c, 'Grid');
      [['gojo', 'JJK', 42, 0.3], ['goku', 'DragonBall', 0, 1], ['luffy', 'OnePiece', 12, 0.8], ['tanjiro', 'DemonSlayer', 55, 0.08], ['naruto', 'Naruto', 0, 1]].forEach(([id, w, rem, prog], i) => {
        const card = tpl('EggsMenu', 'EggCard'); card.p.LayoutOrder = i; tint(card, G.worlds[w].palette);
        setText(card, 'Name', G.characters[id].name.split(' (')[0] + ' Egg'); setText(card, 'World', G.worlds[w].name);
        if (rem > 0) { setText(card, 'Hatching.Timer', `0:${String(rem).padStart(2, '0')}`); find(card, 'Hatching.Bar.Fill').p.Size = { t: 'UDim2', v: [prog, 0, 1, 0] }; }
        else { show(card, 'Hatching', false); show(card, 'OpenButton'); }
        vp(card, 'EGG 3D'); grid.ch.push(card); });
    },
    characters() {
      menu('Characters'); const c = content('CharactersMenu'); const grid = find(c, 'Grid');
      setText(c, 'TopBar.SlotsChip.Value', '5 / 6'); setText(c, 'TopBar.IncomeChip.Value', '$1.24K/s');
      [['rengoku', 4, 312, true], ['akaza', 6, 540, true], ['gojo', 1, 2100, true], ['luffy', 2, 180, true], ['goku', 3, 410, true], ['tanjiro', 1, 10, false], ['deku', 1, 24, false], ['nami', 2, 70, false]].forEach(([id, lv, inc, eq], i) => {
        const card = tpl('CharactersMenu', 'UnitCard'); card.p.LayoutOrder = i; tint(card, G.worlds[G.characters[id].world].palette);
        setText(card, 'Name', G.characters[id].name.split(' (')[0].toUpperCase()); setText(card, 'Level', `LV ${lv}`); setText(card, 'Income.Text', `$${fmt(inc)}/s`);
        show(card, 'EquippedTag', eq); setText(card, 'EquipButton.Face.Content.Label', eq ? 'UNEQUIP' : 'EQUIP');
        vp(card, 'MODEL'); grid.ch.push(card); });
    },
    upgrade() {
      menu('Upgrade'); const c = content('UpgradeMenu');
      setText(c, 'Cards.FarmCard.Stat', 'Level 2 • 6 slots\nNext: 7 slots'); setText(c, 'Cards.FarmCard.UpgradeButton.Face.Content.Sub', '$25K');
      setText(c, 'Cards.TreadmillCard.Stat', 'Level 3 • +4 Speed/s\nNext: +7 Speed/s'); setText(c, 'Cards.TreadmillCard.UpgradeButton.Face.Content.Sub', '$6K');
      const list = find(c, 'List');
      [['akaza', 6, 540, 680, 9800], ['gojo', 1, 2100, 2520, 42000], ['rengoku', 4, 312, 390, 5400], ['luffy', 10, 900, null, null]].forEach(([id, lv, a, b, cost], i) => {
        const row = tpl('UpgradeMenu', 'UpgradeRow'); row.p.LayoutOrder = i;
        setText(row, 'Name', G.characters[id].name.split(' (')[0]); setText(row, 'Level', `LV ${lv} / 10`);
        setText(row, 'Income', b ? `$${fmt(a)}/s  >  <font color="#15803D">$${fmt(b)}/s</font>` : `$${fmt(a)}/s  (MAX)`);
        const pips = find(row, 'Pips'); pips.ch.filter((p) => p.c === 'Frame').forEach((p, k) => { p.p.BackgroundColor3 = { t: 'Color3', v: k < lv ? hex('#5CE63C') : hex('#D6D9EA') }; });
        setText(row, 'UpgradeButton.Face.Content.Label', b ? 'UPGRADE' : 'MAX'); setText(row, 'UpgradeButton.Face.Content.Sub', b ? `$${fmt(cost)}` : '');
        vp(row, 'MODEL'); list.ch.push(row); });
    },
    trails() {
      menu('TrailShop'); const c = content('TrailShopMenu'); const grid = find(c, 'Grid');
      setText(c, 'TopBar.Current.Text', 'Equipped: Dash Trail (x2 Speed)');
      G.trails.forEach((t, i) => { const card = tpl('TrailShopMenu', 'TrailCard'); card.p.LayoutOrder = i;
        const sw = find(card, 'Swatch'); const g = sw.ch.find((x) => x.c === 'UIGradient'); g.p.Color = { t: 'ColorSequence', v: t.colors.map((col, k) => [k / (t.colors.length - 1), ...hex(col)]) };
        setText(card, 'Swatch.Mult', `x${t.mult}`); setText(card, 'Name', t.name.toUpperCase()); setText(card, 'Family', t.family.toUpperCase());
        const owned = i < 2; show(card, 'EquippedTag', i === 1);
        setText(card, 'BuyButton.Face.Content.Label', owned ? (i === 1 ? 'EQUIPPED' : 'EQUIP') : 'BUY'); setText(card, 'BuyButton.Face.Content.Sub', owned ? '' : `$${fmt(t.cashPrice)}`);
        grid.ch.push(card); });
    },
    sell() {
      menu('Sell'); const c = content('SellMenu'); const grid = find(c, 'Grid');
      const units = [['tanjiro', 1, 450], ['deku', 2, 1300], ['nami', 1, 2600], ['kakashi', 3, 4100], ['guts', 1, 9900], ['kenpachi', 1, 14800], ['rengoku', 4, 18000], ['toji', 2, 40000], ['igris', 1, 88000], ['akaza', 6, 120000]];
      units.forEach(([id, lv, v], i) => { const card = tpl('SellMenu', 'SellCard'); card.p.LayoutOrder = i; tint(card, G.worlds[G.characters[id].world].palette);
        setText(card, 'Name', G.characters[id].name.split(' (')[0].toUpperCase()); setText(card, 'Level', `LV ${lv}`); setText(card, 'Value', `$${fmt(v)}`);
        show(card, 'Selected', i < 3); show(card, 'EquippedTag', i >= 8); vp(card, 'MODEL'); grid.ch.push(card); });
      setText(c, 'BottomBar.Count', '3 selected'); setText(c, 'BottomBar.Total', '$4.35K');
      const s = find(c, 'TopBar.Sort_Value'); if (s) { const g = s.ch.find((x) => x.n === 'Face'); }
    },
    shop() {
      menu('Shop'); const c = content('ShopMenu'); const grid = find(c, 'Grid');
      [['$10K', 'Cash pack', 'icon_cash'], ['$150K', 'Cash pack', 'icon_moneybag'], ['$2.5M', 'Cash pack', 'icon_moneybag'], ['+500 SPEED', 'Speed pack', 'icon_speed'], ['x2 CASH', '15 minutes', 'icon_potion'], ['x2 SPEED', '15 minutes', 'icon_bolt'], ['VIP', 'x1.25 Cash forever', 'icon_crown'], ['STARTER', '$50K + 100 Speed', 'icon_gift']].forEach(([t, d, ic], i) => {
        const card = tpl('ShopMenu', 'ShopCard'); card.p.LayoutOrder = i; setText(card, 'Title', t); setText(card, 'Desc', d);
        const icon = find(card, 'Icon'); icon.a.AssetKey = ic; grid.ch.push(card); });
    },
    reveal() {
      show(tree, 'HatchReveal'); setText(tree, 'HatchReveal.Center.Name', 'SATORU GOJO'); setText(tree, 'HatchReveal.Center.World', 'World 8 • Jujutsu Kaisen');
      show(tree, 'HatchReveal.Center.NewTag'); vp(find(tree, 'HatchReveal'), 'REAL CHARACTER MODEL (ViewportFrame)');
    },
    carrysafe() { show(tree, 'EggCarry'); show(tree, 'EggCarry.Unsafe', false); show(tree, 'EggCarry.Secured'); vp(find(tree, 'EggCarry.Secured'), 'EGG 3D'); show(tree, 'HatchTimer'); show(tree, 'HatchTimer.StateHatching', false); show(tree, 'HatchTimer.StateReady'); },
  };
  (S[state] || S.hud)();
  // auto-scale (UIController formula)
  const scale = Math.max(0.45, Math.min(2, Math.min(W / 1280, H / 720)));
  R.descendants(tree, (n) => n.c === 'UIScale' && n.n === 'AutoScale').forEach((n) => { n.p.Scale = scale; });
  const stage = document.getElementById('stage'); stage.style.width = W + 'px'; stage.style.height = H + 'px';
  R.render(tree, document.getElementById('screen'), { manifest: window.ASSET_MANIFEST, assetUrl: (k) => window.ASSET_DATA[k], onElement: () => {} });
  document.body.dataset.ready = '1';
})();
