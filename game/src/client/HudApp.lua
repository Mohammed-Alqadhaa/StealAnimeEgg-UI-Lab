--!strict
--[[
	HudApp — always-on HUD: Speed + Cash (+$/s), round/fog-gate timer, carry banner
	("Reach the Farm Safe Zone!"), hatch widget, nav badges, toasts.

	Sources (all server-authoritative):
	  * player attributes Cash / Speed / IncomePerSec / CarryState / CarryEggId
	  * workspace attributes RoundPhase / PhaseEndsAt / RoundNumber
	  * StateSnapshot eggs[].hatchAt (absolute server time)
	  * Notify / EggFx events
]]
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Shared = ReplicatedStorage:WaitForChild("SAE_Shared")
local Worlds = require(Shared:WaitForChild("Worlds"))
local Economy = require(Shared:WaitForChild("Economy"))

local U = require(script.Parent:WaitForChild("UIUtil"))
local VS = require(script.Parent:WaitForChild("ViewportService"))

local player = Players.LocalPlayer

local Hud = {}

local TOAST_COLORS = {
	ok = { "#46D95F", "#0E5E24" },
	warn = { "#FFC21F", "#A85200" },
	danger = { "#FF4D4D", "#7A0A18" },
	info = { "#6E76A0", "#262A45" },
}

function Hud.start(ctx)
	local gui: ScreenGui = ctx.gui
	local net, state, ui = ctx.net, ctx.state, ctx.ui

	---------------------------------------------------------------- currency
	local speedValue = U.find(gui, "HUD.Speed.Pill.Value")
	local cashValue = U.find(gui, "HUD.Cash.Pill.Value")
	local rateValue = U.find(gui, "HUD.Cash.Pill.Rate")
	local function refreshCurrency()
		U.text(speedValue :: Instance, nil, Economy.format(player:GetAttribute("Speed") or 0))
		U.text(cashValue :: Instance, nil, U.money(player:GetAttribute("Cash") or 0))
		U.text(rateValue :: Instance, nil, "+" .. U.money(player:GetAttribute("IncomePerSec") or 0) .. "/s")
	end
	for _, a in { "Cash", "Speed", "IncomePerSec" } do
		player:GetAttributeChangedSignal(a):Connect(refreshCurrency)
	end
	refreshCurrency()

	------------------------------------------------------------ round timer
	local phaseLabel = U.find(gui, "RoundTimer.Pill.Phase")
	local timeLabel = U.find(gui, "RoundTimer.Pill.Time")
	local PHASE_TEXT = { GATE = "FOG GATE OPENS IN", OPEN = "ROUND ENDS IN", RESET = "RESETTING..." }

	-------------------------------------------------------------- carry
	local carry = gui:WaitForChild("EggCarry") :: Frame
	local unsafe = carry:WaitForChild("Unsafe") :: Frame
	local secured = carry:WaitForChild("Secured") :: Frame
	local hideToken = 0
	local function refreshCarry()
		local cs = player:GetAttribute("CarryState")
		local eggId = player:GetAttribute("CarryEggId")
		hideToken += 1
		if cs == "UNSAFE" and typeof(eggId) == "string" then
			carry.Visible = true
			unsafe.Visible = true
			secured.Visible = false
			local egg = Worlds.EGGS[eggId]
			U.text(unsafe, "Banner.Title", string.upper(U.shortName(egg and egg.character or "")) .. " EGG")
			U.text(unsafe, "Banner.WarnRow.Sub", "Reach the Farm Safe Zone!")
			local vp = U.find(unsafe, "EggSlot.Egg3D")
			if vp and vp:IsA("ViewportFrame") then
				VS.egg(vp, eggId, { spin = 1.2 })
			end
		elseif cs == "SECURED" then
			carry.Visible = true
			unsafe.Visible = false
			secured.Visible = true
			local my = hideToken
			task.delay(2.5, function()
				if my == hideToken then
					carry.Visible = false
				end
			end)
		else
			carry.Visible = false
		end
	end
	player:GetAttributeChangedSignal("CarryState"):Connect(refreshCarry)
	player:GetAttributeChangedSignal("CarryEggId"):Connect(refreshCarry)
	refreshCarry()

	-------------------------------------------------------------- hatch widget
	local hatch = gui:WaitForChild("HatchTimer") :: Frame
	local hatching = U.find(hatch, "StateHatching") :: Frame
	local ready = U.find(hatch, "StateReady") :: Frame
	local title = U.find(hatch, "TitleRibbon.Title")
	local more = hatch:FindFirstChild("More")
	local eggVp = U.find(hatch, "EggSlot.Egg3D") :: ViewportFrame?
	local focus: any = nil

	local function pickFocus(snap)
		local now = state.now()
		local best, readyCount = nil, 0
		for _, e in snap.eggs or {} do
			if e.hatchAt <= now then
				readyCount += 1
			end
			if not best or e.hatchAt < best.hatchAt then
				best = e
			end
		end
		return best, readyCount, #(snap.eggs or {})
	end

	local navEggsBadge = U.find(gui, "Nav.EggsButton.Badge")
	local function refreshHatch(snap)
		local best, readyCount, total = pickFocus(snap)
		focus = best
		hatch.Visible = best ~= nil
		if navEggsBadge then
			U.show(navEggsBadge, nil, readyCount > 0)
			U.text(navEggsBadge, "Text", tostring(readyCount))
		end
		if not best then
			return
		end
		U.text(hatching, "EggName", U.shortName(best.characterId) .. " Egg")
		if more then
			U.text(more, nil, total > 1 and ("+" .. (total - 1)) or "")
		end
		if eggVp then
			VS.egg(eggVp, best.eggId)
		end
	end
	state.observe(refreshHatch)

	------------------------------------------------------------- per-frame text
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 0.1 then
			return
		end
		acc = 0
		local now = state.now()
		-- round
		local phase = workspace:GetAttribute("RoundPhase")
		local ends = workspace:GetAttribute("PhaseEndsAt") or now
		U.text(phaseLabel :: Instance, nil, string.format("ROUND %d • %s", workspace:GetAttribute("RoundNumber") or 1, PHASE_TEXT[phase] or "ROUND"))
		U.text(timeLabel :: Instance, nil, phase == "RESET" and "--" or U.clock(ends - now))
		-- hatch
		if focus then
			local left = focus.hatchAt - now
			local isReady = left <= 0
			hatching.Visible = not isReady
			ready.Visible = isReady
			U.text(title :: Instance, nil, isReady and "EGG READY" or "HATCHING")
			if not isReady then
				U.text(hatching, "TimerRow.Timer", U.clock(left))
				local span = math.max(1, focus.hatchAt - (focus.securedAt or focus.hatchAt - 60))
				U.fill(hatching:FindFirstChild("Bar"), 1 - left / span)
			end
		end
	end)

	-------------------------------------------------------------- toasts
	local toasts = gui:WaitForChild("Toasts")
	local toastTpl = U.find(toasts, "Templates.Toast") :: Frame
	local function toast(kind: string, text: string)
		local t = toastTpl:Clone()
		U.text(t, "Text", text)
		local c = TOAST_COLORS[kind] or TOAST_COLORS.info
		local g = t:FindFirstChildOfClass("UIGradient")
		if g then
			g.Color = ColorSequence.new(Color3.fromHex(c[1]), Color3.fromHex(c[2]))
		end
		t.LayoutOrder = os.clock() * 1000 // 1
		t.Parent = toasts
		local kids = 0
		for _, k in toasts:GetChildren() do
			if k:IsA("GuiObject") then
				kids += 1
			end
		end
		if kids > 4 then
			for _, k in toasts:GetChildren() do
				if k:IsA("GuiObject") then
					k:Destroy()
					break
				end
			end
		end
		task.delay(3.2, function()
			if t.Parent then
				TweenService:Create(t, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
				task.wait(0.3)
				t:Destroy()
			end
		end)
	end
	Hud.toast = toast
	net.on("Notify", function(kind, text)
		if typeof(text) == "string" then
			toast(typeof(kind) == "string" and kind or "info", text)
		end
	end)
	net.on("EggFx", function(kind, data)
		local egg = type(data) == "table" and Worlds.EGGS[data.eggId]
		local name = egg and U.shortName(egg.character) or "Egg"
		if kind == "PICKED_UP" then
			toast("warn", name .. " Egg grabbed - Reach the Farm Safe Zone!")
		elseif kind == "SECURED" then
			toast("ok", name .. " Egg secured! Hatching in 60s")
		elseif kind == "DROPPED" then
			toast("danger", name .. " Egg dropped!")
		elseif kind == "RETURNED" then
			toast("danger", name .. " Egg returned to its world")
		end
	end)

	-------------------------------------------------------------- actions
	ui.Action:Connect(function(btn: Instance, action: string)
		if action == "DropEgg" then
			net.fire("RequestDropEgg")
		elseif action == "OpenEgg" and btn:IsDescendantOf(hatch) then
			if focus and focus.hatchAt <= state.now() then
				ctx.openEgg(focus.uid)
			end
		elseif action == "OpenShop" then
			ui:OpenMenu("Shop")
		end
	end)
end

return Hud
