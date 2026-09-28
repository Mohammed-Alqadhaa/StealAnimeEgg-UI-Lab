--!nocheck
--[[
	Hub — the Farm Safe Zone (§58, §78–§82), farms, treadmills + signs (§85, §91, §92),
	Trail Shop (§93, §94), Sell Characters kiosk (§100, §101) and the Fog Gate (§118).

	Built FROM the Last CP's saved FarmHubVisualPrototype (ground, path, spawn, the seven
	plots and their grass tiles are kept), with these changes:
	  * each plot's individual fence (FencePost/FenceRail/CrossBrace) removed (§80)
	  * BoxingBag training objects removed (§83 — FarmService no longer references them)
	  * old static CharacterPads and FARM/ENTER/TRAIN billboards removed
	  * ONE shared perimeter fence around the whole safe zone with a single exit (§80)
	  * low plot markers + owner plate, treadmill, treadmill sign, farm upgrade sign
	  * no unrelated houses/city decoration (§81)
]]
local B = require("./B")
local Treadmill = require("./Treadmill")
local Rigs = require("./Rigs")
local R = B.R
local V3, CF, A = B.V3, B.CF, B.Angles

local Hub = {}

local REMOVE_IN_FARM = {
	FencePost = true, FenceRail = true, CrossBrace = true,
	BagBase = true, BagPost = true, BagArm = true, Chain = true, BoxingBag = true,
	LabelAnchor = true,
}

-- a physical sign board with named TextLabels (server updates the text)
local function signBoard(parent, name, cf, width, height, theme, lines)
	local m = B.model(parent, name)
	local post = B.part(m, "Post", V3(0.6, height * 0.6, 0.6), cf * CF(0, height * 0.3, 0.3), "#3A3F63", "Metal", { collide = true })
	local board = B.part(m, "Board", V3(width, height, 0.5), cf * CF(0, height * 0.6 + height / 2 - 0.5, 0), theme.face, "SmoothPlastic", { collide = true })
	B.part(m, "Frame", V3(width + 0.5, height + 0.5, 0.35), board.CFrame * CF(0, 0, 0.12), "#1B1036", "SmoothPlastic")
	B.part(m, "TopGlow", V3(width + 0.5, 0.25, 0.55), board.CFrame * CF(0, height / 2 + 0.3, 0), theme.glow, "Neon")
	local gui = R.Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = R.Enum.NormalId.Front
	gui.SizingMode = R.Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 50
	gui.LightInfluence = 0
	gui.Brightness = 1.6
	gui.Parent = board
	local bg = R.Instance.new("Frame")
	bg.Size = R.UDim2.fromScale(1, 1)
	bg.BackgroundColor3 = B.color(theme.face)
	bg.BorderSizePixel = 0
	bg.Parent = gui
	local grad = R.Instance.new("UIGradient")
	grad.Color = B.cseq({ theme.hi, theme.face })
	grad.Rotation = 90
	grad.Parent = bg
	local y = 0.04
	for _, line in lines do
		local l = R.Instance.new("TextLabel")
		l.Name = line.name
		l.BackgroundTransparency = 1
		l.Position = R.UDim2.fromScale(0.05, y)
		l.Size = R.UDim2.fromScale(0.9, line.h)
		l.Text = line.text
		l.TextScaled = true
		l.Font = R.Enum.Font[line.font or "LuckiestGuy"]
		l.TextColor3 = B.color(line.color or "#FFFFFF")
		l.TextStrokeTransparency = 0
		l.TextStrokeColor3 = B.color("#1B1036")
		l.Parent = bg
		y += line.h + 0.02
	end
	local anchor = B.part(m, "PromptAnchor", V3(1, 1, 1), cf * CF(0, 2.5, -1.2), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	anchor.CanQuery = false
	return m
end

local function farmVectors(face)
	local f = face == "N" and V3(0, 0, -1) or face == "S" and V3(0, 0, 1) or face == "E" and V3(1, 0, 0) or V3(-1, 0, 0)
	return f, V3(-f.Z, 0, f.X)
end

local function facingCF(pos, dir)
	return R.CFrame.lookAt(pos, pos + dir)
end

local function upgradeFarm(farm, index, face, center)
	-- 1) strip legacy fence / bag / pads / labels
	local del = {}
	for _, d in farm:GetChildren() do
		if REMOVE_IN_FARM[d.Name] or string.match(d.Name, "^CharacterPad") then
			table.insert(del, d)
		end
	end
	for _, d in del do
		d:Destroy()
	end
	local f, s = farmVectors(face)
	local plotHalf = V3(46, 0, 39)
	local y0 = 0.9
	-- 2) low ownership markers: kerb border with a gap at the entrance + corner posts
	local ownerColor = ({ "#FF4F7E", "#35A2FF", "#FFC21F", "#9A5CFF", "#46D95F", "#FF7A1A", "#3FE0FF" })[index]
	local corners = { V3(-1, 0, -1), V3(1, 0, -1), V3(1, 0, 1), V3(-1, 0, 1) }
	for i = 1, 4 do
		local a = center + corners[i] * plotHalf
		local b = center + corners[i % 4 + 1] * plotHalf
		local mid = (a + b) / 2
		local dir = (b - a)
		local isFront = (mid - center).Unit:Dot(f) > 0.9
		local len = dir.Magnitude
		if isFront then
			-- two kerb pieces leaving a 20-stud entrance
			for _, side in { -1, 1 } do
				local segLen = (len - 20) / 2
				local segMid = mid + dir.Unit * side * (10 + segLen / 2)
				B.part(farm, "PlotKerb", V3(0.9, 0.7, segLen), facingCF(segMid + V3(0, y0 + 0.2, 0), dir.Unit), "#EDE6D6", "Concrete", { collide = true })
				B.part(farm, "PlotKerbGlow", V3(0.3, 0.12, segLen), facingCF(segMid + V3(0, y0 + 0.62, 0), dir.Unit), ownerColor, "Neon")
			end
		else
			B.part(farm, "PlotKerb", V3(0.9, 0.7, len), facingCF(mid + V3(0, y0 + 0.2, 0), dir.Unit), "#EDE6D6", "Concrete", { collide = true })
			B.part(farm, "PlotKerbGlow", V3(0.3, 0.12, len), facingCF(mid + V3(0, y0 + 0.62, 0), dir.Unit), ownerColor, "Neon")
		end
		local post = B.part(farm, "CornerPost", V3(1.6, 3, 1.6), CF(a + V3(0, y0 + 1.5, 0)), "#3A3F63", "Metal", { collide = true })
		B.part(farm, "CornerCap", V3(1.9, 0.6, 1.9), CF(a + V3(0, y0 + 3.2, 0)), ownerColor, "Neon")
		post:SetAttribute("OwnerAccent", true)
	end
	-- 3) owner plate at the entrance
	local platePos = center + f * (plotHalf.X * math.abs(f.X) + plotHalf.Z * math.abs(f.Z) + 1.5) + s * 16
	local plate = B.model(farm, "OwnerPlate")
	local board = B.part(plate, "Board", V3(12, 2.6, 0.5), facingCF(platePos + V3(0, y0 + 3.2, 0), f), "#1B1036", "SmoothPlastic", { collide = true })
	B.part(plate, "PostL", V3(0.5, 3, 0.5), CF(platePos + s * 5.5 + V3(0, y0 + 1.5, 0)), "#3A3F63", "Metal")
	B.part(plate, "PostR", V3(0.5, 3, 0.5), CF(platePos - s * 5.5 + V3(0, y0 + 1.5, 0)), "#3A3F63", "Metal")
	B.surfaceText(board, "FARM " .. index .. " • FREE", { face = "Front", labelName = "Owner", color = ownerColor, name = "PlateGui" })
	-- 4) treadmill (back-left quadrant) + its upgrade sign (§85, §91)
	local tPos = center - f * 20 - s * 24 + V3(0, y0, 0)
	local tm = Treadmill.build(farm, facingCF(tPos, -f)) -- runner faces the plot's back fence line
	tm:SetAttribute("FarmIndex", index)
	local tSignPos = tPos + s * 9 + f * 2
	signBoard(farm, "TreadmillSign", facingCF(tSignPos, f), 7, 5.2, { face = "#1E3A8F", hi = "#35A2FF", glow = "#3FE0FF" }, {
		{ name = "Title", text = "TREADMILL", h = 0.2 },
		{ name = "Level", text = "LEVEL 1", h = 0.18, color = "#FFD23F" },
		{ name = "Gain", text = "+1 Speed/s", h = 0.16, font = "FredokaOne" },
		{ name = "Next", text = "NEXT +2 Speed/s", h = 0.14, font = "FredokaOne", color = "#9FF0FF" },
		{ name = "Cost", text = "$500", h = 0.2, color = "#7CFF5A" },
	})
	-- 5) farm upgrade sign at the front plot marker (§92)
	local fSignPos = center + f * (plotHalf.X * math.abs(f.X) + plotHalf.Z * math.abs(f.Z) - 2) - s * 16 + V3(0, y0, 0)
	signBoard(farm, "FarmSign", facingCF(fSignPos, f), 7, 5.2, { face = "#1F7A3A", hi = "#46D95F", glow = "#7CFF5A" }, {
		{ name = "Title", text = "FARM UPGRADE", h = 0.2 },
		{ name = "Level", text = "FARM LEVEL 1", h = 0.18, color = "#FFD23F" },
		{ name = "Slots", text = "5 CHARACTER SLOTS", h = 0.16, font = "FredokaOne" },
		{ name = "Next", text = "NEXT: 6 SLOTS", h = 0.14, font = "FredokaOne", color = "#C2FFA3" },
		{ name = "Cost", text = "$2.5K", h = 0.2, color = "#FFFFFF" },
	})
	local chars = B.folder(farm, "Characters")
	chars:SetAttribute("Note", "Equipped units are spawned here at runtime")
end

local function perimeterFence(hub, L)
	local fence = B.model(hub, "SafeZoneFence")
	local minX, maxX, minZ, maxZ = L.SAFE_MIN.x, L.SAFE_MAX.x, L.SAFE_MIN.z, L.SAFE_MAX.z
	local y0 = 0.3
	local function run(a, b, gapHalf)
		local dir = b - a
		local len = dir.Magnitude
		local u = dir.Unit
		local step = 12
		local n = math.floor(len / step)
		for i = 0, n - 1 do
			local p0 = a + u * (i * step)
			local p1 = a + u * math.min(len, (i + 1) * step)
			local mid = (p0 + p1) / 2
			local inGap = gapHalf and math.abs(mid.X) < gapHalf and math.abs(mid.Z - maxZ) < 1
			if not inGap then
				B.part(fence, "FencePost", V3(1.4, 7, 1.4), CF(p0 + V3(0, y0 + 3.5, 0)), "#F4F0E6", "Wood", { collide = true })
				B.part(fence, "FenceCap", V3(1.8, 0.6, 1.8), CF(p0 + V3(0, y0 + 7.2, 0)), "#46D95F", "Neon")
				for _, h in { 2.4, 5.2 } do
					B.part(fence, "FenceRail", V3(0.5, 0.7, (p1 - p0).Magnitude), facingCF(mid + V3(0, y0 + h, 0), u), "#F4F0E6", "Wood", { collide = true })
				end
				-- invisible full-height collider keeps the safe zone a clean one-exit boundary
				B.part(fence, "FenceCollider", V3(1, 16, (p1 - p0).Magnitude), facingCF(mid + V3(0, y0 + 8, 0), u), "#FFFFFF", "SmoothPlastic", { collide = true, transparency = 1 })
			end
		end
	end
	run(V3(minX, 0, minZ), V3(maxX, 0, minZ))
	run(V3(maxX, 0, minZ), V3(maxX, 0, maxZ))
	run(V3(maxX, 0, maxZ), V3(minX, 0, maxZ), L.HUB_EXIT_HALF_WIDTH)
	run(V3(minX, 0, maxZ), V3(minX, 0, minZ))
	-- safe-zone boundary line on the ground (readability of "where securing happens")
	B.part(fence, "SafeLine", V3(L.HUB_EXIT_HALF_WIDTH * 2, 0.08, 1.2), CF(0, 1.02, maxZ - 1), "#46D95F", "Neon")
	-- exit arch "FARM SAFE ZONE"
	for _, sx in { -1, 1 } do
		B.part(fence, "ArchPillar", V3(4, 20, 4), CF(sx * (L.HUB_EXIT_HALF_WIDTH + 2), 10, maxZ), "#3A3F63", "Slate", { collide = true })
		B.part(fence, "ArchPillarGlow", V3(4.3, 0.6, 4.3), CF(sx * (L.HUB_EXIT_HALF_WIDTH + 2), 19, maxZ), "#46D95F", "Neon")
	end
	local beam = B.part(fence, "ArchBeam", V3(L.HUB_EXIT_HALF_WIDTH * 2 + 8, 4, 3), CF(0, 21, maxZ), "#1F7A3A", "SmoothPlastic", { collide = true })
	B.surfaceText(beam, "FARM SAFE ZONE", { face = "Back", color = "#7CFF5A" })
	B.surfaceText(beam, "▲ ANIME WORLDS ▲", { face = "Front", color = "#FFD23F", name = "SignOut" })
	return fence
end

-- a market stall kiosk (Trail Shop / Sell Characters), facing `dir`
local function kiosk(hub, name, pos, dir, theme, title, promptText, vendor)
	local m = B.model(hub, name)
	local right = V3(-dir.Z, 0, dir.X)
	local base = facingCF(pos, dir)
	B.part(m, "Floor", V3(18, 0.6, 12), base * CF(0, 0.6, 0), "#EDE6D6", "WoodPlanks", { collide = true })
	B.part(m, "Counter", V3(14, 3.2, 2.4), base * CF(0, 2.2, -3.4), theme.counter, "Wood", { collide = true })
	B.part(m, "CounterTop", V3(14.6, 0.4, 3), base * CF(0, 3.9, -3.4), "#F4F0E6", "Marble", { collide = true })
	B.part(m, "CounterGlow", V3(14.2, 0.2, 0.2), base * CF(0, 3.6, -4.65), theme.glow, "Neon")
	for _, sx in { -1, 1 } do
		for _, sz in { -1, 1 } do
			B.part(m, "Pole", V3(0.6, 10, 0.6), base * CF(sx * 8, 5.6, sz * 5), "#6B4A2A", "Wood", { collide = true })
		end
	end
	-- striped awning (R05 / R08)
	for i = 0, 8 do
		local col = i % 2 == 0 and theme.stripeA or theme.stripeB
		B.part(m, "Awning", V3(2, 0.4, 12.5), base * CF(-8 + i * 2, 10.8, 0) * A(math.rad(8), 0, 0), col, "Fabric")
		B.part(m, "AwningScallop", V3(2, 1.2, 0.3), base * CF(-8 + i * 2, 10.1, -6.3), col, "Fabric")
	end
	local sign = B.part(m, "TitleBoard", V3(16, 3.4, 0.6), base * CF(0, 13.6, -5), theme.counter, "SmoothPlastic")
	B.surfaceText(sign, title, { face = "Front", color = theme.title, name = "TitleGui" })
	local titleAnchor = B.part(m, "TitleAnchor", V3(1, 1, 1), base * CF(0, 18, -5), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	B.billboard(titleAnchor, title, { w = 420, h = 90, maxDistance = 220, color = theme.title, offset = V3(0, 0, 0) })
	local anchor = B.part(m, "PromptAnchor", V3(2, 2, 2), base * CF(0, 3, -6.5), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
	anchor:SetAttribute("OpensMenu", name == "TrailShop" and "TrailShop" or "Sell")
	anchor:SetAttribute("PromptText", promptText)
	-- vendor NPC behind the counter (sanitized stand-in; see OWNER ACTION for the real model)
	if vendor then
		vendor.Parent = m
		local target = base * CF(0, 3.1, -1.2) * A(0, math.rad(180), 0)
		local hrp = vendor:FindFirstChild("HumanoidRootPart")
		B.transform(vendor, hrp.CFrame, target)
		for _, d in vendor:GetDescendants() do
			if d:IsA("BasePart") then
				d.Anchored = true
			end
		end
	end
	-- showcase props
	for i = -1, 1 do
		local pillar = B.part(m, "Showcase", V3(1.6, 5, 1.6), base * CF(i * 5, 2.8, 3.8), "#1B1036", "Metal")
		if name == "TrailShop" then
			local cols = { "#3FE0FF", "#FF6FB5", "#FFD23F" }
			for k = 0, 3 do
				B.part(m, "TrailRibbon", V3(0.9, 0.12, 2.5), pillar.CFrame * CF(0, 1 + k * 0.5, -1.4 - k * 0.6) * A(math.rad(-15), 0, 0), cols[i + 2], "Neon", { transparency = k * 0.2 })
			end
		else
			B.ball(m, "SellCoin", 1.6, 0, 0, 0, "#FFD23F", "Metal").CFrame = pillar.CFrame * CF(0, 3.4, 0)
		end
	end
	B.light(sign, theme.glow, 24, 1.4)
	return m
end

function Hub.build(ws, proto, L, audit, vendors)
	local world = ws:FindFirstChild("SAE_World") or B.model(ws, "SAE_World")
	local hub = B.model(world, "Hub")
	-- keep: ground (resized to the full safe zone), path, bands, spawn, world exit
	local ground = proto:FindFirstChild("HubGround")
	ground.Size = V3(L.SAFE_MAX.x - L.SAFE_MIN.x + 20, 2, L.SAFE_MAX.z - L.SAFE_MIN.z + 20)
	ground.CFrame = CF(0, -1, (L.SAFE_MAX.z + L.SAFE_MIN.z) / 2)
	ground.Parent = hub
	for _, child in proto:GetChildren() do
		if child.Name == "MainPath" or child.Name == "PathBand" or child.Name == "FarmHubSpawn" then
			child.Parent = hub
		end
	end
	local exit = proto:FindFirstChild("SharedWorldExit")
	exit.Parent = hub
	for _, d in exit:GetChildren() do
		if string.match(d.Name, "^ZoneMarker") or d.Name == "LabelAnchor" then
			d:Destroy()
		end
	end
	local worldColors = { "#44B9DC", "#9B4DFF", "#7CFFB0", "#FF6FB5", "#FF7A1A", "#D8261E", "#E8E8EE", "#FF2E4D", "#3A7BFF" }
	for i, c in worldColors do
		B.box(exit, "WorldMarker" .. i, 7.4, 0.5, 7.4, -35.2 + (i - 1) * 8.8, 0.7, 184, c, "Neon")
	end
	local hdr = exit:FindFirstChild("Header")
	if hdr then
		B.surfaceText(hdr, "9 ANIME WORLDS", { face = "Back", color = "#FFD23F" })
	end
	-- farms
	local farmsFolder = B.folder(hub, "Farms")
	for i = 1, 7 do
		local farm = proto:FindFirstChild("Farm" .. i)
		farm.Parent = farmsFolder
		local c = L.FARM_CENTERS[i]
		upgradeFarm(farm, i, L.FARM_FACING[i], V3(c.x, 0, c.z))
	end
	perimeterFence(hub, L)
	-- kiosks near the exit, either side of the main path (clean hub, §81)
	kiosk(hub, "TrailShop", V3(-58, 0.3, 158), V3(1, 0, 0), { counter = "#6A2FE0", stripeA = "#9A5CFF", stripeB = "#F4F4F4", glow = "#C77DFF", title = "#FFFFFF" }, "TRAIL SHOP", "Browse Trails", vendors.makima)
	kiosk(hub, "SellKiosk", V3(58, 0.3, 158), V3(-1, 0, 0), { counter = "#B71C1C", stripeA = "#E8321E", stripeB = "#F4F4F4", glow = "#FFD23F", title = "#FFD23F" }, "SELL CHARACTERS", "Sell Characters", vendors.seller)
	-- Fog Gate (§118): closed at round start, opens after the countdown
	local gate = B.model(hub, "FogGate")
	local z = L.FOG_GATE_Z
	local blocker = B.part(gate, "Blocker", V3(L.FOG_GATE_HALF_WIDTH * 2 + 6, 28, 2), CF(0, 14, z), "#D8E4F4", "ForceField", { collide = true, transparency = 0.35 })
	blocker:SetAttribute("BaseTransparency", 0.35)
	for i = -4, 4 do
		local a = B.part(gate, "FogEmitter", V3(1, 1, 1), CF(i * 10, 2, z), "#FFFFFF", "SmoothPlastic", { transparency = 1 })
		B.emitter(a, "Fog", { tex = "smoke", colors = { "#E8F0FF", "#9FB3D6" }, rate = 6, life = { 3, 5 }, speed = { 0.5, 1.5 }, spread = 60, size = { { 0, 6 }, { 1, 12 } }, transp = { { 0, 0.55 }, { 1, 1 } }, light = 0.1 })
	end
	for _, sx in { -1, 1 } do
		local post = B.part(gate, "GatePost", V3(3, 30, 3), CF(sx * (L.FOG_GATE_HALF_WIDTH + 4), 15, z), "#2A2F48", "Slate", { collide = true })
		local glow = B.part(gate, "GateGlow", V3(0.5, 28, 3.2), CF(sx * (L.FOG_GATE_HALF_WIDTH + 2.6), 15, z), "#9FE3FF", "Neon")
		glow:SetAttribute("BaseTransparency", 0)
		post:SetAttribute("Keep", true)
	end
	local board = B.part(gate, "CountdownBoard", V3(30, 6, 1), CF(0, 34, z), "#1B1036", "SmoothPlastic")
	local _, label = B.surfaceText(board, "WORLDS OPEN IN 7", { face = "Back", color = "#FFFFFF", labelName = "Countdown", name = "CountdownGui" })
	label.Name = "Countdown"
	gate:SetAttribute("Closed", true)
	-- leftover prototype children (old zone placeholders) are archived by the caller
	return hub
end

return Hub
