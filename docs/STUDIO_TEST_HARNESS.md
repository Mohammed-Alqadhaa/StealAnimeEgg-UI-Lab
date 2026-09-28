# Studio Play-mode Test Harness (`ServerScriptService.SAE_StudioTests.Runner`)

> **Status:** written and statically checked (Luau compile, selene, StyLua, Rojo build, and every
> service call resolved). It has **not been run in Roblox Studio yet**. Its first run belongs to the
> local Studio-MCP stage. Expect the first run to surface harness bugs as well as game bugs, so
> triage each FAIL.

## 1. Safety

| Guard | Effect |
|---|---|
| `RunService:IsStudio()` | On live Roblox servers the Runner exits silently at line 1 of its logic. |
| `ServerStorage.SAE_EnableStudioTests == true` | Must be set explicitly in Studio before Play. It is not set in any committed build. |
| `SAE_Server.TestGate` | Every service test hook (`Remotes.TestCall`, `EggService.TestPickUp`, `PvPService.TestSwing`, …) errors unless both conditions above hold, so the hooks are inert in production. |
| Hooks reuse the real paths | `Remotes.TestCall` runs the exact wrapper a RemoteEvent/RemoteFunction runs (rate limit + mutation lock). `TestPickUp` runs the same checks as the ProximityPrompt (round, carry, distance, state). |
| Data safety guard | If DataStore API access is ON, the run aborts with a FAIL unless `SAE_StudioTestsAllowPersistent = true`. Every player's profile is backed up before the run and restored afterwards. |

## 2. How to run

**Status:** not yet in `OwnerReview_v01`, which predates the harness.

**Add it to the place, either way:**
- Sync `game/default.project.json` with Rojo.
- Or rebuild with `lune run game/assembler/build.luau`. This only happens for the next checkpoint;
  v01 is never overwritten.

**Single player:**
1. Game Settings → Security: turn **off** *Enable Studio Access to API Services* (recommended).
2. Command Bar:
   ```lua
   game:GetService("ServerStorage"):SetAttribute("SAE_EnableStudioTests", true)
   ```
3. Press **Play**. Results stream into **Output**; the run takes about 1–2 minutes.

**Multiplayer (PvP, target switching, simultaneous carriers, disconnect):**
1. Command Bar:
   ```lua
   local SS = game:GetService("ServerStorage")
   SS:SetAttribute("SAE_EnableStudioTests", true)
   SS:SetAttribute("SAE_TestPlayers", 2)
   SS:SetAttribute("SAE_TestDisconnect", true) -- optional: you will be asked to close Player2
   ```
2. Test tab → Clients and Servers → **Local Server**, 2 players → **Start**.

**Optional flags** (all ServerStorage attributes):

| Attribute | Effect |
|---|---|
| `SAE_TestRealHatch = true` | Wait the real 60 s hatch instead of fast-forwarding `hatchAt`. |
| `SAE_TestInteractive = true` | If the server cannot drive the character on the treadmill, the harness asks you to run on it. |
| `SAE_TestDisconnect = true` | Run the disconnect-cleanup test (2+ players). |
| `SAE_TestPlayers = n` | Wait for n players before starting. |
| `SAE_StudioTestsAllowPersistent = true` | Allow runs with DataStore access on (profiles are restored). |

## 3. Output format

```
[SAE_TESTS] ===== RUN START  players=1  persistentData=false  round=OPEN =====
[SAE_TESTS] PASS   [Eggs] Egg pickup
[SAE_TESTS] FAIL   [Eggs] one-Egg carry limit  ::  CarryEggId after second pickup attempt: expected "egg_tanjiro", got "egg_rengoku"
[SAE_TESTS] SKIP   [PvP] bat knocks the Egg loose (server-validated)  ::  needs 2 players
[SAE_TESTS] MANUAL [Treadmill] owner running on own treadmill trains  ::  <instructions>
==============================================================================
[SAE_TESTS] SUMMARY  PASS 44   FAIL 1   SKIP 7   MANUAL 0   (players 1)
[SAE_TESTS]   FAILED [Eggs] one-Egg carry limit :: …
[SAE_TESTS] RESULT: FAILURES PRESENT
```

* FAIL lines are printed with `warn` (yellow). Each names the subsystem, the test and the
  **exact failed assertion** (`what: expected X, got Y`).
* Unexpected Lua errors are reported as FAIL with `ERROR …` and a traceback.
* The machine-readable report goes to `ServerStorage.SAE_TestReport` (StringValue, JSON), plus the
  attributes `SAE_TestsPassed`, `SAE_TestsFailed` and `SAE_TestsDone`. An MCP session can read these.

## 4. Coverage (52 tests)

| Subsystem | Tests |
|---|---|
| Farms (4) | exactly 7 Farms (+ MaxPlayers 7) · Farm assignment (index, attributes, owner plate data) · one Farm per player (idempotent Assign, unique owners) · whole Farm area inside the Safe Zone, kiosks inside, Fog Gate outside |
| Eggs (11) | setup · pickup refused out of range · pickup (attributes, record state, carried model) · one-Egg carry limit · manual Drop outside the Safe Zone (+30 s expiry stamp) · dropped egg re-grab · Drop refused inside the Safe Zone · auto-secure on entry (≤ 0.5 s, no secure remote, 60 s hatch stamp) · Drop unavailable after secure · secured world egg not takeable again · same egg instance never secures twice |
| Hatch (7) | HATCHING + OPEN refused before 60 s · 60 s → READY transition (real wait with `SAE_TestRealHatch`) · READY → OPEN grant + discovery · double-Open (rapid, sequential, concurrent) · unique GUID unit uids · duplicate Character ownership · Index de-duplication |
| Characters (6) | Farm slot overflow safety (auto-equip cap, equip into a full farm, open while full) · Equip/Unequip validation (invalid, duplicate, wrong types) · Equip Best by actual $/sec only · income only while equipped · no offline income assumptions · Character upgrade validation (cost−1, exact cost, unknown uid, bad type, max level) |
| Treadmill (5) | upgrade validation + physical transformation L1 → L10 (each level changes the visible machine; L10 > L1) · owner validation (other machines untouched) · standing still does not train · owner running trains (state + Speed) · foreign treadmill does not train |
| Farm (1) | Farm upgrade validation (cost, slots, max level) |
| Trails (3) | ownership/equip validation · server-priced purchase + VFX applied · only one Trail equipped, multipliers never stack, WalkSpeed ordering |
| Sell (3) | atomic validation (empty, unknown, mixed, duplicate, wrong types) · safe unequip before Sell + exact payout · double-Sell (rapid, sequential, concurrent) |
| Economy (1) | Cash duplication ledger over mixed success and failure operations |
| Boss (4) | targeting rule + catch outcomes · live ~1 s reaction → CHASE → RETURN, never inside the Safe Zone · seated bosses start seated · target switching (2 players) |
| PvP (3) | bat knock-loose · cooldown + range · Safe Zone protection |
| Multiplayer (1) | simultaneous independent carriers |
| Round (2) | Fog Gate closed during GATE, pickups refused, opens after 7 s · round reset (carriers, eggs, players home, profile eggs kept, bosses idle) |
| Disconnect (1) | carried egg returns, farm released (2 players + `SAE_TestDisconnect`) |

**Known limits:**
* Training requires `Humanoid.MoveDirection` from the client. If `Humanoid:MoveTo` from the server
  does not drive the player's character in your Studio version, the two training tests report
  MANUAL. Re-run them with `SAE_TestInteractive`.
* Visual quality (trail look, boss animation feel, UI rendering) is not assertable here. It
  belongs to the visual Studio pass.
