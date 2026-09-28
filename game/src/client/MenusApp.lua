--!strict
--[[
	MenusApp — binds every production menu to the server StateSnapshot.
	All values shown (costs, incomes, sell values) come from the server snapshot;
	all buttons send INTENT (uids / ids) only.

	Index (9 worlds, real models, locked silhouettes) · Eggs · Characters (Equip Best)
	Upgrade (characters server-priced, farm, treadmill) · Trail Shop (Makima kiosk)
	Sell (Rem kiosk: multi-select, sorting) · Shop (Robux; nil ids → Coming soon)
	Hatch reveal (real character model, NEW discovery tag).
]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))
local Trails = require(Shared:WaitForChild("Trails"))
local Economy = require(Shared:WaitForChild("Economy"))
local Balance = require(Shared:WaitForChild("Balance"))
local MarketplaceConfig = require(Shared:WaitForChild("MarketplaceConfig"))

local U = require(script.Parent:WaitForChild("UIUtil"))
local VS = require(script.Parent:WaitForChild("ViewportService"))

local Menus = {}

local function content(gui: Instance, menu: string): Instance
	return U.find(gui, menu .. "Menu.Rim.Body.Content") :: Instance
end
local function template(c: Instance, name: string): Instance
	return U.find(c, "Templates." .. name) :: Instance
end

function Menus.start(ctx)
	local gui: ScreenGui = ctx.gui
	local net, state, ui = ctx.net, ctx.state, ctx.ui
	local toast = ctx.toast
	local function bindNew(inst: Instance)
		ui:Bind(inst)
	end
	local function onClick(btn: Instance?, fn: () -> ())
		if btn and btn:IsA("GuiButton") then
			btn.Activated:Connect(fn)
		end
	end

	---------------------------------------------------------------- INDEX
	local idx = content(gui, "Index")
	local tabs = U.find(idx, "Sidebar.Tabs") :: Instance
	local grid = U.find(idx, "Grid") :: Instance
	local selectedWorld = Worlds.ORDER[1]
	local renderIndex: (any) -> ()

	local function discoveredCount(snap, worldId: string): number
		local n = 0
		for _, id in Worlds.WORLDS[worldId].roster do
			if snap.index and snap.index[id] then
				n += 1
			end
		end
		return n
	end

	renderIndex = function(snap)
		if not snap then
			return
		end
		local total = 0
		for _ in snap.index or {} do
			total += 1
		end
		U.reconcile(tabs, template(idx, "WorldTab"), Worlds.ORDER, function(w)
			return w
		end, function(w, _, tab, isNew)
			local name = string.upper(Worlds.WORLDS[w].name)
			local count = string.format("%d/5", discoveredCount(snap, w))
			for _, v in { "Active", "Inactive" } do
				U.text(tab, v .. ".Face.Content.Label", name)
				U.text(tab, v .. ".Face.Content.Count", count)
			end
			U.show(tab, "Active", w == selectedWorld)
			U.show(tab, "Inactive", w ~= selectedWorld)
			if isNew then
				onClick(tab, function()
					selectedWorld = w
					renderIndex(state.data)
				end)
			end
		end, bindNew)
		local world = Worlds.WORLDS[selectedWorld]
		U.text(idx, "Header.World", string.upper(world.name))
		U.text(idx, "Header.Discovered", string.format("%d / 5 Discovered", discoveredCount(snap, selectedWorld)))
		local totalBar = U.find(idx, "Header.Total")
		U.text(totalBar :: Instance, "Text", string.format("%d / %d", total, #Worlds.characterList()))
		U.fill(totalBar, total / #Worlds.characterList())
		U.reconcile(grid, template(idx, "IndexCard"), world.roster, function(id)
			return id
		end, function(id, _, card)
			local found = snap.index and snap.index[id] ~= nil
			if found then
				U.tint(card, selectedWorld)
			end
			U.text(card, "NamePlate.Name", found and string.upper(U.shortName(id)) or "???")
			U.show(card, "LockBadge", not found)
			U.show(card, "BossTag", found and Worlds.CHARACTERS[id].isBoss == true)
			local vp = VS.first(card)
			if vp then
				VS.character(vp, id, { silhouette = not found })
			end
		end, bindNew)
		-- nav badge: new discoveries since the Index was last opened
		local badge = U.find(gui, "Nav.IndexButton.Badge")
		if badge then
			local seen = gui:GetAttribute("IndexSeen") or 0
			U.show(badge, nil, total > seen and ui.CurrentMenu ~= "Index")
		end
	end
	state.observe(renderIndex)

	---------------------------------------------------------------- EGGS
	local eggsC = content(gui, "Eggs")
	local eggGrid = U.find(eggsC, "Grid") :: Instance
	local eggCards: { [string]: Instance } = {}
	local function renderEggs(snap)
		local eggs = table.clone(snap.eggs or {})
		table.sort(eggs, function(a, b)
			return a.hatchAt < b.hatchAt
		end)
		U.show(eggsC, "Empty", #eggs == 0)
		eggCards = U.reconcile(eggGrid, template(eggsC, "EggCard"), eggs, function(e)
			return e.uid
		end, function(uid, e, card, isNew)
			local egg = Worlds.EGGS[e.eggId]
			U.tint(card, egg.world)
			U.text(card, "Name", U.shortName(e.characterId) .. " Egg")
			U.text(card, "World", Worlds.WORLDS[egg.world].name)
			card:SetAttribute("HatchAt", e.hatchAt)
			card:SetAttribute("SecuredAt", e.securedAt or (e.hatchAt - Balance.HatchSeconds))
			local vp = VS.first(card)
			if vp then
				VS.egg(vp, e.eggId)
			end
			if isNew then
				onClick(U.find(card, "OpenButton"), function()
					ctx.openEgg(uid)
				end)
			end
		end, bindNew)
	end
	state.observe(renderEggs)

	---------------------------------------------------------------- CHARACTERS
	local chC = content(gui, "Characters")
	local chGrid = U.find(chC, "Grid") :: Instance
	local function sortedUnits(snap, by: string?)
		local units = table.clone(snap.units or {})
		table.sort(units, function(a, b)
			if by == "Value" then
				if a.sellValue ~= b.sellValue then
					return a.sellValue > b.sellValue
				end
			elseif by == "World" then
				local wa, wb = Worlds.WORLDS[a.worldId].index, Worlds.WORLDS[b.worldId].index
				if wa ~= wb then
					return wa < wb
				end
			elseif by == "Name" then
				local na, nb = U.shortName(a.characterId), U.shortName(b.characterId)
				if na ~= nb then
					return na < nb
				end
			else
				if a.equipped ~= b.equipped then
					return a.equipped
				end
			end
			if a.income ~= b.income then
				return a.income > b.income
			end
			return a.uid < b.uid
		end)
		return units
	end
	local function renderCharacters(snap)
		local units = sortedUnits(snap)
		local equippedCount = 0
		for _, u in units do
			if u.equipped then
				equippedCount += 1
			end
		end
		U.text(chC, "TopBar.SlotsChip.Value", string.format("%d / %d", equippedCount, snap.slots or 5))
		U.text(chC, "TopBar.IncomeChip.Value", U.money(snap.income or 0) .. "/s")
		U.show(chC, "Empty", #units == 0)
		U.reconcile(chGrid, template(chC, "UnitCard"), units, function(u)
			return u.uid
		end, function(uid, u, card, isNew)
			U.tint(card, u.worldId)
			U.text(card, "Name", string.upper(U.shortName(u.characterId)))
			U.text(card, "Level", "LV " .. u.level)
			U.text(card, "Income.Text", U.money(u.income) .. "/s")
			U.show(card, "EquippedTag", u.equipped)
			local btn = U.find(card, "EquipButton")
			if btn then
				U.button(btn, u.equipped and "UNEQUIP" or "EQUIP")
				btn:SetAttribute("Equipped", u.equipped)
			end
			local vp = VS.first(card)
			if vp then
				VS.character(vp, u.characterId)
			end
			if isNew then
				onClick(btn, function()
					if btn and btn:GetAttribute("Equipped") then
						net.fire("RequestUnequipCharacter", uid)
					else
						net.fire("RequestEquipCharacter", uid)
					end
				end)
			end
		end, bindNew)
	end
	state.observe(renderCharacters)

	---------------------------------------------------------------- UPGRADE
	local upC = content(gui, "Upgrade")
	local upList = U.find(upC, "List") :: Instance
	local function renderUpgrade(snap)
		-- farm
		local farm = U.find(upC, "Cards.FarmCard") :: Instance
		U.text(
			farm,
			"Stat",
			snap.farmUpgradeCost and string.format("Level %d • %d slots\nNext: %d slots", snap.farmLevel, snap.slots, snap.nextSlots or snap.slots)
				or string.format("Level %d • %d slots\nMAX LEVEL", snap.farmLevel, snap.slots)
		)
		U.button(
			U.find(farm, "UpgradeButton") :: Instance,
			snap.farmUpgradeCost and "UPGRADE" or "MAX",
			snap.farmUpgradeCost and U.money(snap.farmUpgradeCost) or ""
		)
		-- treadmill
		local tm = U.find(upC, "Cards.TreadmillCard") :: Instance
		U.text(
			tm,
			"Stat",
			snap.treadmillNextGain
					and string.format(
						"Level %d • +%s Speed/s\nNext: +%s Speed/s",
						snap.treadmillLevel,
						Economy.format(snap.treadmillGain),
						Economy.format(snap.treadmillNextGain)
					)
				or string.format("Level %d • +%s Speed/s\nMAX LEVEL", snap.treadmillLevel, Economy.format(snap.treadmillGain))
		)
		U.button(
			U.find(tm, "UpgradeButton") :: Instance,
			snap.treadmillUpgradeCost and "UPGRADE" or "MAX",
			snap.treadmillUpgradeCost and U.money(snap.treadmillUpgradeCost) or ""
		)
		-- characters (server-priced)
		local units = sortedUnits(snap)
		U.show(upC, "Empty", #units == 0)
		U.reconcile(upList, template(upC, "UpgradeRow"), units, function(u)
			return u.uid
		end, function(uid, u, row, isNew)
			local maxed = u.nextIncome == nil
			U.text(row, "Name", U.shortName(u.characterId))
			U.text(row, "Level", string.format("LV %d / %d", u.level, Balance.CharacterMaxLevel))
			U.text(
				row,
				"Income",
				maxed and (U.money(u.income) .. "/s  (MAX)")
					or string.format('%s/s  >  <font color="#15803D">%s/s</font>', U.money(u.income), U.money(u.nextIncome))
			)
			local pips = row:FindFirstChild("Pips")
			if pips then
				for _, p in pips:GetChildren() do
					local n = tonumber(string.match(p.Name, "^Pip(%d+)$"))
					if n and p:IsA("Frame") then
						p.BackgroundColor3 = n <= u.level and Color3.fromHex("#5CE63C") or Color3.fromHex("#D6D9EA")
					end
				end
			end
			local btn = U.find(row, "UpgradeButton") :: Instance
			U.button(btn, maxed and "MAX" or "UPGRADE", maxed and "" or U.money(u.upgradeCost))
			local vp = VS.first(row)
			if vp then
				VS.character(vp, u.characterId)
			end
			if isNew then
				onClick(btn, function()
					local ok, why = net.invoke("RequestUpgradeCharacter", uid)
					if not ok then
						toast("warn", why == "not enough cash" and "Not enough Cash" or tostring(why or "Can't upgrade"))
					end
				end)
			end
		end, bindNew)
	end
	state.observe(renderUpgrade)
	onClick(U.find(upC, "Cards.FarmCard.UpgradeButton"), function()
		net.fire("RequestUpgradeFarm")
	end)
	onClick(U.find(upC, "Cards.TreadmillCard.UpgradeButton"), function()
		net.fire("RequestUpgradeTreadmill")
	end)

	---------------------------------------------------------------- TRAIL SHOP
	local trC = content(gui, "TrailShop")
	local trGrid = U.find(trC, "Grid") :: Instance
	local function gradientOf(colors: { string }): ColorSequence
		local kps = {}
		for i, c in colors do
			table.insert(kps, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), Color3.fromHex(c)))
		end
		if #kps == 1 then
			table.insert(kps, ColorSequenceKeypoint.new(1, kps[1].Value))
		end
		return ColorSequence.new(kps)
	end
	local function renderTrails(snap)
		local owned = {}
		for _, id in snap.trails or {} do
			owned[id] = true
		end
		local eq = snap.equippedTrail and Trails.BY_ID[snap.equippedTrail]
		U.text(trC, "TopBar.Current.Text", eq and string.format("Equipped: %s (x%s Speed)", eq.name, tostring(eq.mult)) or "No trail equipped (x1)")
		U.show(trC, "TopBar.UnequipButton", eq ~= nil)
		U.reconcile(trGrid, template(trC, "TrailCard"), Trails.TIERS, function(t)
			return t.id
		end, function(id, t, card, isNew)
			local sw = card:FindFirstChild("Swatch")
			local g = sw and sw:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = gradientOf(t.colors)
			end
			U.text(card, "Swatch.Mult", "x" .. tostring(t.mult))
			U.text(card, "Name", string.upper(t.name))
			U.text(card, "Family", string.upper(t.family))
			local isEq = snap.equippedTrail == id
			U.show(card, "EquippedTag", isEq)
			local btn = U.find(card, "BuyButton") :: Instance
			if owned[id] then
				U.button(btn, isEq and "EQUIPPED" or "EQUIP", "")
			else
				U.button(btn, "BUY", U.money(t.cashPrice))
			end
			btn:SetAttribute("Owned", owned[id] == true)
			btn:SetAttribute("IsEquipped", isEq)
			if isNew then
				onClick(btn, function()
					if btn:GetAttribute("IsEquipped") then
						return
					end
					if btn:GetAttribute("Owned") then
						net.fire("RequestEquipTrail", id)
					else
						local ok, why = net.invoke("RequestBuyTrailCash", id)
						if not ok then
							toast("warn", why == "not enough cash" and "Not enough Cash" or tostring(why or "Can't buy"))
						end
					end
				end)
			end
		end, bindNew)
	end
	state.observe(renderTrails)
	-- TopBar.UnequipButton carries Action=UnequipTrail (handled in the ui.Action switch below)

	---------------------------------------------------------------- SELL
	local slC = content(gui, "Sell")
	local slGrid = U.find(slC, "Grid") :: Instance
	local selected: { [string]: boolean } = {}
	local sortBy = "Value"
	local renderSell: (any) -> ()
	local function refreshSellTotals(snap)
		local n, total = 0, 0
		for uid in selected do
			local u = snap.unitsByUid and snap.unitsByUid[uid]
			if u then
				n += 1
				total += u.sellValue -- server-provided estimate; the server recomputes on sell
			else
				selected[uid] = nil
			end
		end
		U.text(slC, "BottomBar.Count", n == 1 and "1 selected" or (n .. " selected"))
		U.text(slC, "BottomBar.Total", U.money(total))
	end
	renderSell = function(snap)
		if not snap then
			return
		end
		local units = sortedUnits(snap, sortBy)
		U.show(slC, "Empty", #units == 0)
		U.reconcile(slGrid, template(slC, "SellCard"), units, function(u)
			return u.uid
		end, function(uid, u, card, isNew)
			U.tint(card, u.worldId)
			U.text(card, "Name", string.upper(U.shortName(u.characterId)))
			U.text(card, "Level", "LV " .. u.level)
			U.text(card, "Value", U.money(u.sellValue))
			U.show(card, "EquippedTag", u.equipped)
			U.show(card, "Selected", selected[uid] == true)
			local vp = VS.first(card)
			if vp then
				VS.character(vp, u.characterId)
			end
			if isNew then
				onClick(card, function()
					selected[uid] = not selected[uid] or nil
					U.show(card, "Selected", selected[uid] == true)
					refreshSellTotals(state.data)
				end)
			end
		end, bindNew)
		-- sort buttons: active = gold
		for _, id in { "Value", "Income", "World", "Name" } do
			local b = U.find(slC, "TopBar.Sort_" .. id)
			local face = b and b:FindFirstChild("Face")
			local g = face and face:FindFirstChildOfClass("UIGradient")
			if g then
				g.Color = id == sortBy and ColorSequence.new(Color3.fromHex("#FFF7B0"), Color3.fromHex("#FFA000"))
					or ColorSequence.new(Color3.fromHex("#A7AFD6"), Color3.fromHex("#4A5078"))
			end
		end
		refreshSellTotals(snap)
	end
	state.observe(renderSell)
	for _, id in { "Value", "Income", "World", "Name" } do
		onClick(U.find(slC, "TopBar.Sort_" .. id), function()
			sortBy = id
			renderSell(state.data)
		end)
	end
	local selling = false
	ui.Action:Connect(function(_btn, action)
		local snap = state.data
		if not snap then
			return
		end
		if action == "SellSelectAll" then
			for _, u in snap.units or {} do
				selected[u.uid] = true
			end
			renderSell(snap)
		elseif action == "SellSelectNone" then
			table.clear(selected)
			renderSell(snap)
		elseif action == "SellSelected" and not selling then
			local uids = {}
			for uid in selected do
				table.insert(uids, uid)
			end
			if #uids == 0 then
				toast("info", "Select characters to sell first")
				return
			end
			selling = true
			local ok, payout, count = net.invoke("RequestSellCharacters", uids)
			selling = false
			if ok then
				table.clear(selected)
				toast("ok", string.format("Sold %d character%s for %s", count or #uids, (count or #uids) == 1 and "" or "s", U.money(payout or 0)))
			else
				toast("warn", tostring(payout or "Sell failed"))
			end
		elseif action == "EquipBest" then
			net.fire("RequestEquipBest")
		elseif action == "UnequipTrail" then
			net.fire("RequestEquipTrail", nil)
		end
	end)

	---------------------------------------------------------------- SHOP (Robux)
	local shC = content(gui, "Shop")
	local shGrid = U.find(shC, "Grid") :: Instance
	local SHOP_ICON = { cash = "icon_moneybag", speed = "icon_speed", boost = "icon_potion", pass = "icon_crown" }
	local shopItems = {}
	for key, p in MarketplaceConfig.DeveloperProducts do
		if p.kind ~= "trail" then -- trails are sold in the Makima Trail Shop
			table.insert(shopItems, { key = key, label = p.label or key, kind = p.kind, id = p.id, order = p.amount or 0 })
		end
	end
	for key, gp in MarketplaceConfig.GamePasses do
		table.insert(shopItems, { key = key, label = gp.label or key, kind = "pass", id = gp.id, order = 1e12 })
	end
	table.sort(shopItems, function(a, b)
		if a.kind ~= b.kind then
			return a.kind < b.kind
		end
		return a.order < b.order
	end)
	U.reconcile(shGrid, template(shC, "ShopCard"), shopItems, function(it)
		return it.key
	end, function(key, it, card, isNew)
		U.text(card, "Title", string.upper(it.label))
		U.text(card, "Desc", it.kind == "pass" and "Game Pass" or (it.kind == "boost" and "Boost" or "Pack"))
		local icon = card:FindFirstChild("Icon")
		if icon then
			icon:SetAttribute("AssetKey", SHOP_ICON[it.kind] or "icon_gift")
		end
		local btn = U.find(card, "BuyButton") :: Instance
		U.button(btn, it.id and "BUY" or "COMING SOON")
		if isNew then
			onClick(btn, function()
				if it.id then
					net.fire("RequestRobuxPurchase", key)
				else
					toast("info", "Coming soon")
				end
			end)
		end
	end, bindNew)

	---------------------------------------------------------------- per-frame (egg timers)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.2 or ui.CurrentMenu ~= "Eggs" then
			return
		end
		acc = 0
		local now = state.now()
		for _, card in eggCards do
			local hatchAt = card:GetAttribute("HatchAt") or now
			local securedAt = card:GetAttribute("SecuredAt") or (hatchAt - 60)
			local left = hatchAt - now
			U.show(card, "Hatching", left > 0)
			U.show(card, "OpenButton", left <= 0)
			if left > 0 then
				U.text(card, "Hatching.Timer", U.clock(left))
				U.fill(U.find(card, "Hatching.Bar"), 1 - left / math.max(1, hatchAt - securedAt))
			end
		end
	end)

	ui.MenuChanged:Connect(function(name)
		if name == "Index" then
			local total = 0
			for _ in (state.data and state.data.index) or {} do
				total += 1
			end
			gui:SetAttribute("IndexSeen", total)
			renderIndex(state.data)
		end
	end)

	---------------------------------------------------------------- HATCH REVEAL
	local reveal = gui:WaitForChild("HatchReveal") :: Frame
	local center = reveal:WaitForChild("Center")
	local revealVp = center:FindFirstChild("Model") :: ViewportFrame
	local opening = false
	function ctx.openEgg(uid: string)
		if opening then
			return
		end
		opening = true
		local ok, result = net.invoke("RequestOpenEgg", uid)
		opening = false
		if not ok or type(result) ~= "table" then
			toast("warn", tostring(result or "Can't open yet"))
			return
		end
		ui:CloseMenu()
		U.text(center, "Name", string.upper(result.name or U.shortName(result.characterId)))
		U.text(center, "World", string.format("World %d • %s", Worlds.WORLDS[result.worldId].index, result.worldName or ""))
		U.show(center, "NewTag", result.isNewDiscovery == true)
		U.show(center, "BossTag", result.isBoss == true)
		VS.character(revealVp, result.characterId, { spin = 0.9 })
		reveal.Visible = true
		local sc = center:FindFirstChild("AutoScale") :: UIScale?
		if sc then
			local base = sc:GetAttribute("BaseScale") or 1
			sc.Scale = base * 0.4
			TweenService:Create(sc, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = base }):Play()
		end
		if not result.equipped then
			toast("info", "Farm slots full - equip it from Characters")
		end
	end
	ui.Action:Connect(function(_btn, action)
		if action == "CloseReveal" then
			reveal.Visible = false
			VS.clear(revealVp)
		end
	end)
end

return Menus
