-- ============================================================================
--  PREVIEW_Controller  -  SAMPLE DATA ONLY. NOT PRODUCTION GAMEPLAY.
--
--  Drives the PREVIEW_Panel buttons and simulates UI states (index locks, egg
--  states, 60s dev hatch timer, carry unsafe/secured, equip / equip best,
--  upgrade max level) using PREVIEW_SampleData. Nothing here talks to a server
--  or changes real player data. Delete this module, PREVIEW_SampleData and the
--  PREVIEW_Panel frame to strip the preview system.
-- ============================================================================

local SampleData = require(script.Parent:WaitForChild("PREVIEW_SampleData"))

local Preview = {}

local EGG_STATES = { "OWNED", "HATCHING", "READY", "OPENED" }

-- When auditing (tests), every path that fails to resolve is recorded here.
Preview.missing = {} :: { string }
local auditing = false

local function at(root: Instance, path: string): Instance?
	local cur: Instance? = root
	for part in string.gmatch(path, "[^%.]+") do
		if not cur then
			break
		end
		cur = cur:FindFirstChild(part)
	end
	if not cur and auditing then
		table.insert(Preview.missing, root.Name .. "." .. path)
	end
	return cur
end

local function setVisible(root: Instance?, path: string?, v: boolean)
	local obj = root and (path and at(root, path) or root)
	if obj and obj:IsA("GuiObject") then
		obj.Visible = v
	end
end

local function setText(root: Instance?, path: string, text: string)
	local obj = root and at(root, path)
	if obj and (obj:IsA("TextLabel") or obj:IsA("TextButton")) then
		obj.Text = text
	end
end

local function fmt(sec: number): string
	sec = math.max(0, math.floor(sec))
	return string.format("%d:%02d", sec // 60, sec % 60)
end

local function cap(s: string): string
	return string.upper(string.sub(s, 1, 1)) .. string.lower(string.sub(s, 2))
end

-- opts.bindInput (default true): connect button events. opts.audit: record unresolved paths.
-- Returns a handle { act = function(action), apply = function(), state = S, data = D }
-- e.g. from the Command Bar while playing: handle.act("menu:Shop")
function Preview.start(gui: ScreenGui, ui, opts: { bindInput: boolean?, audit: boolean? }?)
	opts = opts or {}
	auditing = opts.audit == true
	warn("[StealAnimeEggUI] PREVIEW MODE active - using SAMPLE data (not gameplay)")

	-- deep-copy sample data so the module table stays pristine
	local D = table.clone(SampleData)
	D.units = {}
	for i, u in SampleData.units do
		D.units[i] = table.clone(u)
	end

	local S = {
		discovered = {},
		eggStates = {},
		remaining = 42,
		hatch = "HATCHING",
		carry = "UNSAFE",
		maxed = {},
		treadMax = false,
		farmMax = false,
		panelOpen = true,
		timerToken = 0,
	}
	for _, id in D.index.discovered do
		S.discovered[id] = true
	end
	for _, e in D.eggs do
		S.eggStates[e.id] = e.state
		if e.state == "HATCHING" and e.remaining then
			S.remaining = e.remaining
		end
	end
	for _, r in D.upgrade.characters do
		if r.level >= D.upgrade.maxLevel then
			S.maxed[r.unit] = true
		end
	end

	local content = function(menu: string): Instance?
		return at(gui, menu .. "Menu.Rim.Body.Content")
	end

	------------------------------------------------------------------ apply
	local function apply()
		-- panel collapse
		local panel = gui:FindFirstChild("PREVIEW_Panel") :: Frame?
		if panel then
			setVisible(panel, "Frame.Body", S.panelOpen)
			panel.Size = UDim2.fromOffset(234, S.panelOpen and 428 or 44)
			setText(panel, "Frame.Header.Plate.Collapse.Label", S.panelOpen and "-" or "+")
		end

		-- INDEX: locked = silhouette + ??? (Locked frame), unlocked = colour + name
		local index = content("Index")
		local count = 0
		for _, id in D.index.order do
			local on = S.discovered[id] == true
			if on then
				count += 1
			end
			local card = index and at(index, "Grid.Card_" .. id)
			setVisible(card, "Unlocked", on)
			setVisible(card, "Locked", not on)
		end
		local total = #D.index.order
		if index then
			setText(index, "CollectionHeader.Discovered", string.format("%d / %d Discovered", count, total))
			setText(index, "CollectionHeader.Progress.Text", string.format("%d%%", math.round(count / total * 100)))
			local fill = at(index, "CollectionHeader.Progress.Fill") :: Frame?
			if fill then
				fill.Size = UDim2.fromScale(count / total, 1)
				fill.Visible = count > 0
			end
		end

		-- EGG CARDS
		local eggs = content("Eggs")
		for _, e in D.eggs do
			local card = eggs and at(eggs, "Grid.EggCard_" .. e.id)
			for _, st in EGG_STATES do
				setVisible(card, "State" .. cap(st), S.eggStates[e.id] == st)
			end
			if card and e.id == "egg_2" then
				local f = 1 - S.remaining / D.hatchSeconds
				setText(card, "StateHatching.Info.Action.TimerRow.Timer", fmt(S.remaining))
				setText(card, "StateHatching.Info.Action.Bar.Text", string.format("%d%%", math.round(f * 100)))
				local fill = at(card, "StateHatching.Info.Action.Bar.Fill") :: Frame?
				if fill then
					fill.Size = UDim2.fromScale(math.max(0.04, f), 1)
				end
			end
		end

		-- HATCH TIMER widget
		setVisible(gui, "HatchTimer.StateHatching", S.hatch == "HATCHING")
		setVisible(gui, "HatchTimer.StateReady", S.hatch == "READY")
		setText(gui, "HatchTimer.TitleRibbon.Title", S.hatch == "READY" and "EGG READY" or "HATCHING")
		setText(gui, "HatchTimer.StateHatching.TimerRow.Timer", fmt(S.remaining))
		local hfill = at(gui, "HatchTimer.StateHatching.Bar.Fill") :: Frame?
		if hfill then
			hfill.Size = UDim2.fromScale(math.max(0.04, 1 - S.remaining / D.hatchSeconds), 1)
		end

		-- EGG CARRY: UNSAFE shows DROP, SECURED has no DROP
		setVisible(gui, "EggCarry", S.carry ~= "HIDDEN")
		setVisible(gui, "EggCarry.Unsafe", S.carry == "UNSAFE")
		setVisible(gui, "EggCarry.Secured", S.carry == "SECURED")

		-- CHARACTERS
		local chars = content("Characters")
		local equipped, income = 0, 0
		for _, u in D.units do
			local card = chars and at(chars, "Grid.Unit_" .. u.id)
			setVisible(card, "EquippedRing", u.equipped)
			setVisible(card, "UnequipButton", u.equipped)
			setVisible(card, "EquippedBadge", u.equipped)
			setVisible(card, "EquipButton", not u.equipped)
			if u.equipped then
				equipped += 1
				income += u.income
			end
		end
		if chars then
			setText(chars, "TopBar.Equipped.Value", string.format("%d / %d", equipped, D.equipSlots))
			setText(chars, "TopBar.Income.Value", string.format("$%d/s", income))
			for i = 1, D.equipSlots do
				local slot = at(chars, "TopBar.Equipped.Slots.Slot" .. i) :: Frame?
				if slot then
					slot.BackgroundColor3 = i <= equipped and Color3.fromHex("#9A5CFF") or Color3.fromHex("#D9D2F0")
				end
			end
		end
		setText(gui, "Nav.CharactersButton.Badge.Text", tostring(#D.units))

		-- UPGRADE
		local up = content("Upgrade")
		for _, r in D.upgrade.characters do
			local row = up and at(up, "Pages.CharacterPage.Row_" .. r.unit)
			local m = S.maxed[r.unit] == true
			setVisible(row, "UpgradeButton", not m)
			setVisible(row, "MaxLevelButton", m)
			setVisible(row, "Income.Arrow", not m)
			setVisible(row, "Income.Next", not m)
			setText(row, "Level", "Lv." .. (m and D.upgrade.maxLevel or r.level))
			if row and m then
				local first = at(row, "Pips.Pip1") :: Frame?
				for i = 1, D.upgrade.maxLevel do
					local pip = at(row, "Pips.Pip" .. i) :: Frame?
					if pip and first then
						pip.BackgroundColor3 = first.BackgroundColor3
					end
				end
			end
		end
		if up then
			setVisible(up, "Pages.TreadmillPage.Info.UpgradeButton", not S.treadMax)
			setVisible(up, "Pages.TreadmillPage.Info.MaxLevelButton", S.treadMax)
			setVisible(up, "Pages.FarmPage.Info.UpgradeButton", not S.farmMax)
			setVisible(up, "Pages.FarmPage.Info.MaxLevelButton", S.farmMax)
		end
	end

	----------------------------------------------------------------- timer
	local function startTimer()
		S.timerToken += 1
		local token = S.timerToken
		S.remaining = D.hatchSeconds
		S.hatch = "HATCHING"
		S.eggStates.egg_2 = "HATCHING"
		apply()
		task.spawn(function()
			while S.remaining > 0 and token == S.timerToken do
				task.wait(1)
				if token ~= S.timerToken then
					return
				end
				S.remaining -= 1
				if S.remaining <= 0 then
					S.hatch = "READY"
					S.eggStates.egg_2 = "READY"
				end
				apply()
			end
		end)
	end

	--------------------------------------------------------------- actions
	local bindButtons -- forward declaration (clones need binding too)

	local function equipBest()
		-- Equip Best is based ONLY on $/sec
		local sorted = table.clone(D.units)
		table.sort(sorted, function(a, b)
			return a.income > b.income
		end)
		local best = {}
		for i = 1, math.min(D.equipSlots, #sorted) do
			best[sorted[i].id] = true
		end
		for _, u in D.units do
			u.equipped = best[u.id] == true
		end
	end

	local function addDuplicate()
		local srcUnit = D.units[1]
		local n = 0
		for _, u in D.units do
			if u.char == srcUnit.char then
				n += 1
			end
		end
		if n >= 6 then
			return
		end
		local chars = content("Characters")
		local template = chars and at(chars, "Grid.Unit_" .. srcUnit.id)
		if not template then
			return
		end
		local id = srcUnit.char .. "_" .. (n + 1)
		local unit = { id = id, char = srcUnit.char, unit = n + 1, level = 1, income = 48, equipped = false }
		table.insert(D.units, unit)
		local card = template:Clone()
		card.Name = "Unit_" .. id
		card:SetAttribute("UnitId", id)
		card:SetAttribute("Income", unit.income)
		;(card :: GuiObject).LayoutOrder = #D.units
		for _, d in card:GetDescendants() do
			if d:GetAttribute("UnitId") then
				d:SetAttribute("UnitId", id)
			end
		end
		setText(card, "UnitChip.Text", "#" .. unit.unit)
		setText(card, "LevelPill.Text", "Lv.1")
		setText(card, "IncomeRow.Stat.Text", "$48/s")
		card.Parent = template.Parent
		if opts.bindInput ~= false then
			bindButtons(card)
		end
	end

	local function act(action: string)
		local k, v, w = string.match(action, "^([^:]+):?([^:]*):?(.*)$")
		if k == "menu" then
			if v == "none" then
				ui:CloseMenu()
			else
				ui:OpenMenu(v)
			end
		elseif k == "panel" then
			S.panelOpen = not S.panelOpen
		elseif k == "index" then
			if v == "unlockNext" then
				for _, id in D.index.order do
					if not S.discovered[id] then
						S.discovered[id] = true
						break
					end
				end
			elseif v == "lockAll" then
				S.discovered = {}
			elseif v == "unlockAll" then
				for _, id in D.index.order do
					S.discovered[id] = true
				end
			end
		elseif k == "eggs" then
			for _, e in D.eggs do
				if v == "cycle" then
					local i = table.find(EGG_STATES, S.eggStates[e.id]) or 1
					S.eggStates[e.id] = EGG_STATES[i % #EGG_STATES + 1]
				elseif v == "allReady" then
					S.eggStates[e.id] = "READY"
				elseif v == "reset" then
					S.eggStates[e.id] = e.state
				end
			end
		elseif k == "hatch" then
			if v == "start" then
				startTimer()
			else
				S.timerToken += 1
				S.hatch = string.upper(v)
			end
		elseif k == "carry" then
			S.carry = string.upper(v)
		elseif k == "chars" then
			if v == "equipBest" then
				equipBest()
			elseif v == "unequipAll" then
				for _, u in D.units do
					u.equipped = false
				end
			elseif v == "addDupe" then
				addDuplicate()
			end
		elseif k == "upgrade" then
			if v == "tab" then
				local btn = at(gui, "UpgradeMenu.Rim.Body.Content.Tabs.Tab_" .. w)
				if btn then
					ui:SetTab(btn, w)
				end
			elseif v == "toggleMax" then
				local all = S.treadMax
				for _, r in D.upgrade.characters do
					if all then
						if r.level < D.upgrade.maxLevel then
							S.maxed[r.unit] = nil
						end
					else
						S.maxed[r.unit] = true
					end
				end
				S.treadMax = not all
				S.farmMax = not all
			end
		end
		apply()
	end

	-- in-UI buttons simulate feedback only (UI lab - no gameplay)
	local function onButton(btn: GuiButton)
		local pa = btn:GetAttribute("PreviewAction")
		if typeof(pa) == "string" then
			act(pa)
			return
		end
		local unitAction, unitId = btn:GetAttribute("UnitAction"), btn:GetAttribute("UnitId")
		if unitAction == "EquipBest" then
			equipBest()
		elseif unitAction == "Equip" or unitAction == "Unequip" then
			local n = 0
			for _, u in D.units do
				if u.equipped then
					n += 1
				end
			end
			for _, u in D.units do
				if u.id == unitId and (unitAction == "Unequip" or n < D.equipSlots) then
					u.equipped = unitAction == "Equip"
				end
			end
		end
		local eggAction, eggId = btn:GetAttribute("EggAction"), btn:GetAttribute("EggId")
		if eggAction == "Hatch" then
			S.eggStates[eggId] = "HATCHING"
		elseif eggAction == "Skip" then
			S.eggStates[eggId] = "READY"
		elseif eggAction == "Open" then
			S.eggStates[eggId] = "OPENED"
		elseif eggAction == "Collect" then
			S.eggStates[eggId] = "OWNED"
		elseif eggAction == "HatchAll" then
			for id, st in S.eggStates do
				if st == "OWNED" then
					S.eggStates[id] = "HATCHING"
				end
			end
		end
		local action = btn:GetAttribute("Action")
		if action == "OpenEgg" then
			startTimer()
		elseif action == "DropEgg" then
			S.carry = "HIDDEN"
		end
		if btn:GetAttribute("UpgradeAction") == "Character" then
			S.maxed[btn:GetAttribute("UnitId")] = true
		end
		apply()
	end

	bindButtons = function(root: Instance)
		for _, d in root:GetDescendants() do
			if d:IsA("GuiButton") then
				if root ~= gui then
					ui:_bindButton(d) -- hover/press for cloned cards
				end
				d.Activated:Connect(function()
					onButton(d)
				end)
			end
		end
	end

	if opts.bindInput ~= false then
		bindButtons(gui)
	end
	apply()
	return { act = act, apply = apply, state = S, data = D }
end

return Preview
