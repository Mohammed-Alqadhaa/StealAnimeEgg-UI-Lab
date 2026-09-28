/* PREVIEW-ONLY state logic for the browser preview (mirror of
 * src/client/PREVIEW_Controller.client.lua). Operates on SAMPLE data only. */
(function () {
  const EGG_STATES = ['OWNED', 'HATCHING', 'READY', 'OPENED'];
  const cap = (s) => s[0] + s.slice(1).toLowerCase();
  let panelOpen = true;
  let timerHandle = null;

  function fmt(sec) { return `${Math.floor(sec / 60)}:${String(Math.max(0, Math.floor(sec % 60))).padStart(2, '0')}`; }

  const PreviewStates = {
    init(S, D) {
      S.eggStates = Object.fromEntries(D.eggs.map((e) => [e.id, e.state]));
      S.remaining = D.eggs.find((e) => e.state === 'HATCHING')?.remaining ?? 42;
      S.maxed = new Set(D.upgrade.characters.filter((r) => r.level >= D.upgrade.maxLevel).map((r) => r.unit));
      S.treadMax = false; S.farmMax = false;
    },

    apply(S, D, T) {
      if (!S.eggStates) this.init(S, D);
      const { find, set, tree } = T;
      const R = window.RbxRender;
      // panel collapse
      set('PREVIEW_Panel.Frame.Body', 'Visible', panelOpen);
      const pnl = find('PREVIEW_Panel'); if (pnl) pnl.p.Size = { t: 'UDim2', v: [0, 234, 0, panelOpen ? 428 : 44] };
      const col = find('PREVIEW_Panel.Frame.Header.Plate.Collapse.Label'); if (col) col.p.Text = panelOpen ? '-' : '+';

      // ---------------- INDEX
      const order = D.index.order;
      order.forEach((id) => {
        const card = find(`IndexMenu.Rim.Body.Content.Grid.Card_${id}`);
        const on = S.discovered.has(id);
        set(R.find(card, 'Unlocked'), 'Visible', on);
        set(R.find(card, 'Locked'), 'Visible', !on);
      });
      const n = S.discovered.size; const total = order.length;
      const hdr = 'IndexMenu.Rim.Body.Content.CollectionHeader';
      set(`${hdr}.Discovered`, 'Text', `${n} / ${total} Discovered`);
      set(`${hdr}.Progress.Fill`, 'Size', { t: 'UDim2', v: [n / total, 0, 1, 0] });
      set(`${hdr}.Progress.Fill`, 'Visible', n > 0);
      set(`${hdr}.Progress.Text`, 'Text', `${Math.round((n / total) * 100)}%`);

      // ---------------- EGG CARDS
      D.eggs.forEach((e) => {
        const card = find(`EggsMenu.Rim.Body.Content.Grid.EggCard_${e.id}`);
        EGG_STATES.forEach((st) => set(R.find(card, `State${cap(st)}`), 'Visible', S.eggStates[e.id] === st));
        const hatch = R.find(card, 'StateHatching');
        if (hatch && e.id === 'egg_2') {
          const act = R.find(hatch, 'Info.Action');
          set(R.find(act, 'TimerRow.Timer'), 'Text', fmt(S.remaining));
          const f = 1 - S.remaining / D.hatchSeconds;
          set(R.find(act, 'Bar.Fill'), 'Size', { t: 'UDim2', v: [Math.max(0.04, f), 0, 1, 0] });
          set(R.find(act, 'Bar.Text'), 'Text', `${Math.round(f * 100)}%`);
        }
      });

      // ---------------- HATCH WIDGET timer
      set('HatchTimer.StateHatching.TimerRow.Timer', 'Text', fmt(S.remaining));
      set('HatchTimer.StateHatching.Bar.Fill', 'Size', { t: 'UDim2', v: [Math.max(0.04, 1 - S.remaining / D.hatchSeconds), 0, 1, 0] });

      // ---------------- CHARACTERS
      const eq = D.units.filter((u) => u.equipped);
      const grid = find('CharactersMenu.Rim.Body.Content.Grid');
      if (grid) {
        D.units.forEach((u) => {
          let card = R.find(grid, `Unit_${u.id}`);
          if (!card && u.cloneOf) { // duplicate added by preview: clone template card
            const src = R.find(grid, `Unit_${u.cloneOf}`);
            card = JSON.parse(JSON.stringify(src)); card.n = `Unit_${u.id}`; card.a.UnitId = u.id; card.p.LayoutOrder = D.units.indexOf(u) + 1;
            R.descendants(card, (x) => x.a && x.a.UnitId).forEach((x) => { x.a.UnitId = u.id; });
            R.find(card, 'UnitChip.Text').p.Text = `#${u.unit}`;
            R.find(card, 'LevelPill.Text').p.Text = `Lv.${u.level}`;
            R.find(card, 'IncomeRow.Stat.Text').p.Text = `$${u.income}/s`;
            grid.ch.push(card);
          }
          ['EquippedRing', 'UnequipButton', 'EquippedBadge'].forEach((k) => set(R.find(card, k), 'Visible', !!u.equipped));
          set(R.find(card, 'EquipButton'), 'Visible', !u.equipped);
        });
        const tb = 'CharactersMenu.Rim.Body.Content.TopBar';
        set(`${tb}.Equipped.Value`, 'Text', `${eq.length} / ${D.equipSlots}`);
        for (let i = 0; i < D.equipSlots; i++) set(`${tb}.Equipped.Slots.Slot${i + 1}`, 'BackgroundColor3', { t: 'Color3', v: i < eq.length ? [0.604, 0.361, 1] : [0.851, 0.824, 0.941] });
        set(`${tb}.Income.Value`, 'Text', `$${eq.reduce((s, u) => s + u.income, 0)}/s`);
      }
      const navBadge = find('Nav.CharactersButton.Badge.Text'); if (navBadge) navBadge.p.Text = String(D.units.length);

      // ---------------- UPGRADE
      ['Character', 'Treadmill', 'Farm'].forEach((t) => {
        set(`UpgradeMenu.Rim.Body.Content.Pages.${t}Page`, 'Visible', S.upgradeTab === t);
        set(`UpgradeMenu.Rim.Body.Content.Tabs.Tab_${t}.Active`, 'Visible', S.upgradeTab === t);
        set(`UpgradeMenu.Rim.Body.Content.Tabs.Tab_${t}.Inactive`, 'Visible', S.upgradeTab !== t);
      });
      D.upgrade.characters.forEach((r) => {
        const row = find(`UpgradeMenu.Rim.Body.Content.Pages.CharacterPage.Row_${r.unit}`);
        const m = S.maxed.has(r.unit);
        set(R.find(row, 'UpgradeButton'), 'Visible', !m);
        set(R.find(row, 'MaxLevelButton'), 'Visible', m);
        set(R.find(row, 'Income.Arrow'), 'Visible', !m);
        set(R.find(row, 'Income.Next'), 'Visible', !m);
        const lvl = m ? D.upgrade.maxLevel : r.level;
        set(R.find(row, 'Level'), 'Text', `Lv.${lvl}`);
        for (let i = 1; i <= D.upgrade.maxLevel; i++) {
          const pip = R.find(row, `Pips.Pip${i}`);
          if (pip && m) pip.p.BackgroundColor3 = R.find(row, 'Pips.Pip1').p.BackgroundColor3;
        }
      });
      [['Treadmill', S.treadMax], ['Farm', S.farmMax]].forEach(([p, m]) => {
        set(`UpgradeMenu.Rim.Body.Content.Pages.${p}Page.Info.UpgradeButton`, 'Visible', !m);
        set(`UpgradeMenu.Rim.Body.Content.Pages.${p}Page.Info.MaxLevelButton`, 'Visible', m);
      });
    },

    action(k, v, w2, S, D, api) {
      if (k === 'panel') panelOpen = !panelOpen;
      if (k === 'index') {
        if (v === 'unlockNext') { const nx = D.index.order.find((id) => !S.discovered.has(id)); if (nx) S.discovered.add(nx); }
        if (v === 'lockAll') S.discovered.clear();
        if (v === 'unlockAll') D.index.order.forEach((id) => S.discovered.add(id));
      }
      if (k === 'eggs') {
        if (v === 'cycle') D.eggs.forEach((e) => { S.eggStates[e.id] = EGG_STATES[(EGG_STATES.indexOf(S.eggStates[e.id]) + 1) % 4]; });
        if (v === 'allReady') D.eggs.forEach((e) => { S.eggStates[e.id] = 'READY'; });
        if (v === 'reset') D.eggs.forEach((e) => { S.eggStates[e.id] = e.state; });
      }
      if (k === 'hatch') {
        if (v === 'start') this.startTimer(S, D, api);
      }
      if (k === 'chars') {
        if (v === 'equipBest') {
          // Equip Best: based ONLY on $/sec
          const best = D.units.slice().sort((a, b) => b.income - a.income).slice(0, D.equipSlots).map((u) => u.id);
          D.units.forEach((u) => { u.equipped = best.includes(u.id); });
        }
        if (v === 'unequipAll') D.units.forEach((u) => { u.equipped = false; });
        if (v === 'addDupe') {
          const src = D.units.find((u) => u.char === 'rengoku' && !u.cloneOf) || D.units[0];
          const count = D.units.filter((u) => u.char === src.char).length;
          if (count < 6) D.units.push({ id: `${src.char}_${count + 1}`, char: src.char, unit: count + 1, level: 1, income: 48, equipped: false, cloneOf: src.id });
        }
      }
      if (k === 'upgrade') {
        if (v === 'tab') S.upgradeTab = w2;
        if (v === 'toggleMax') {
          const all = S.maxed.size === D.upgrade.characters.length && S.treadMax;
          D.upgrade.characters.forEach((r) => { if (all) { if (r.level < D.upgrade.maxLevel) S.maxed.delete(r.unit); } else S.maxed.add(r.unit); });
          S.treadMax = !all; S.farmMax = !all;
        }
      }
    },

    startTimer(S, D, api) {
      clearInterval(timerHandle);
      S.remaining = D.hatchSeconds; S.hatch = 'HATCHING'; S.eggStates.egg_2 = 'HATCHING';
      timerHandle = setInterval(() => {
        S.remaining -= 1;
        if (S.remaining <= 0) { clearInterval(timerHandle); S.remaining = 0; S.hatch = 'READY'; S.eggStates.egg_2 = 'READY'; }
        api.render();
      }, 1000);
    },

    // in-UI buttons that simulate gameplay feedback (UI only)
    click(n, S, D, act) {
      const a = n.a || {};
      if (a.Tab) { S.upgradeTab = a.Tab; return true; }
      if (a.UnitAction === 'EquipBest') { act('chars:equipBest'); return true; }
      if (a.UnitAction === 'Equip' || a.UnitAction === 'Unequip') {
        const u = D.units.find((x) => x.id === a.UnitId);
        if (u) {
          if (a.UnitAction === 'Equip' && D.units.filter((x) => x.equipped).length >= D.equipSlots) return true;
          u.equipped = a.UnitAction === 'Equip';
        }
        return true;
      }
      if (a.EggAction) {
        const id = a.EggId;
        if (a.EggAction === 'Hatch') S.eggStates[id] = 'HATCHING';
        if (a.EggAction === 'Skip') S.eggStates[id] = 'READY';
        if (a.EggAction === 'Open') S.eggStates[id] = 'OPENED';
        if (a.EggAction === 'Collect') S.eggStates[id] = 'OWNED';
        if (a.EggAction === 'HatchAll') D.eggs.forEach((e) => { if (S.eggStates[e.id] === 'OWNED') S.eggStates[e.id] = 'HATCHING'; });
        return true;
      }
      if (a.Action === 'OpenEgg') { S.hatch = 'HATCHING'; S.remaining = D.hatchSeconds; return true; }
      if (a.Action === 'DropEgg') { S.carry = 'HIDDEN'; return true; }
      if (a.UpgradeAction === 'Character') { S.maxed.add(a.UnitId); return true; }
      return false;
    },
  };
  window.PreviewStates = PreviewStates;
})();
