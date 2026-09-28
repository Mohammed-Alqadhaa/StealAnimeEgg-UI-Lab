--!strict
--[[
	Net — the complete client→server intent surface (Master Prompt §124).

	Clients send INTENT only (ids/uids). The server decides every value: costs, payouts,
	levels, ownership, safe-zone state. There is deliberately NO RequestSecure / SecureEgg
	remote — securing is detected by the server when a carrier enters the Farm Safe Zone
	(§59, §60, §123). Egg pickup, treadmill/farm upgrades at physical signs and PvP bat
	hits use server-side ProximityPrompt / Tool events, not remotes.

	Server → client traffic is event-driven (snapshots on change), never per-second
	countdown ticks: clients render countdowns from absolute timestamps (hatchAt,
	PhaseEndsAt) using workspace:GetServerTimeNow() (§63, §125).
]]

local Net = {}

Net.FOLDER = "SAE_Net"

-- client → server (RemoteEvent unless listed in FUNCTIONS)
Net.EVENTS = {
	"RequestDropEgg", -- ()                       drop the carried egg (unsafe only)
	"RequestEquipCharacter", -- (uid)
	"RequestUnequipCharacter", -- (uid)
	"RequestEquipBest", -- ()                      by actual $/sec only (§76)
	"RequestEquipTrail", -- (trailId | nil)       nil = unequip
	"RequestUpgradeTreadmill", -- ()               own farm, server-priced
	"RequestUpgradeFarm", -- ()                    own farm, server-priced
	"RequestRobuxPurchase", -- (productKey)        server looks up the id and prompts
	-- server → client
	"StateSnapshot", -- (privateState)            inventory, eggs, index, trails …
	"Notify", -- (kind, text, extra)              toasts / feedback
	"EggFx", -- (kind, data)                      SECURED / DROPPED / RETURNED feedback
}

Net.FUNCTIONS = {
	"RequestOpenEgg", -- (eggUid) -> ok, result   hatch reveal payload
	"RequestUpgradeCharacter", -- (uid) -> ok, unit
	"RequestBuyTrailCash", -- (trailId) -> ok, reason
	"RequestSellCharacters", -- ({uids}) -> ok, payout, soldCount
	"RequestInitialState", -- () -> privateState
	"RequestDevCommand", -- (cmd, arg) -> ok  (Studio / whitelisted developers only)
}

-- Explicitly forbidden names — asserted absent by tests (tools/tests).
Net.FORBIDDEN = { "RequestSecure", "SecureEgg", "GiveCash", "SetSpeed", "SetCash" }

return Net
