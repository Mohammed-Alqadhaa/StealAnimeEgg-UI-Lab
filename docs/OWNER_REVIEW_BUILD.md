# Owner Review Build — `StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx`

> **Verification status:** Roblox Studio, Studio MCP and a Roblox play-test were **not available** in the
> build environment. **Nothing in this build has been play-tested in Roblox Studio.** Everything
> below was verified with offline tools only (Lune static place inspection, Luau compile, selene,
> StyLua, Rojo build, unit tests, browser layout approximations). Please treat the first Studio
> session as the first real play test (checklist in §4).

## 1. Build record

| Field | Value |
|---|---|
| File | `checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx` |
| Size | 38,898,739 bytes (37.1 MiB) |
| SHA-256 | `01abd251437107aeae200c2c500a9d1317675310175ab22ae08c39d346b19b3b` |
| Built (UTC) | 2026-09-28 05:23:16 (file mtime) |
| Branch | `claude/loving-pasteur-oayq18` |
| Commit that contains this file + the exact sources that built it | `3e7e2382e0fbc0394826282deb9f5c4b7f639b5f` |
| Built from (read-only baseline) | `checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx`, SHA-256 `dc8d2af1…` (unchanged) |
| Instances | 20,095 (8,940 parts created by the world builders) |
| Assembler | `lune run game/assembler/build.luau` (Lune 0.10.5) |

Rebuilding from the same commit produces an equivalent place. Only the random per-instance
`UniqueId` values differ, so the SHA-256 identifies **this** committed file.

## 2. How to open

1. Open the `.rbxlx` in Roblox Studio (File → Open from File). It is a normal place file; nothing
   needs to be installed.
2. **Game Settings → Security:** enable *Studio Access to API Services* if you want DataStore saving
   in Studio. Without it the server falls back to in-memory profiles and logs a warning.
3. Press **Play** (or **Start → Players: 2** to test PvP/bosses with two clients).
4. The Studio-only **DEV panel** (top-right) gives +$1M, +1K Speed, GIVE EGG, HATCH NOW,
   SKIP PHASE and RESET DATA. It is destroyed outside Studio, and the server refuses dev commands
   from non-whitelisted players.

Alternative workflow: `game/default.project.json` is a Rojo project (shared/server/client code +
the SAE_UI model), so the code can be live-synced into the place with Rojo.

## 3. What was verified offline (and how)

| Check | Tool | Result |
|---|---|---|
| Pure game logic (economy, profile ops, hatch, sell, trails, layout, boss targeting) | `lune run game/tests/unit.luau` | 289 passed, 0 failed |
| Assembled place structure + contracts (farms, worlds, spawns, bosses, rigs, UI paths, sanitization, no Rebirth/BoxingBag/forbidden remotes, every script compiles) | `lune run game/tests/place.luau` | 558 passed, 0 failed |
| Negative control: the same test on the untouched baseline | `place.luau <baseline>` | fails, as expected |
| Luau lint | `selene` (offline Roblox std) | 0 errors, 0 warnings |
| Formatting | `stylua --check` | clean |
| Rojo project builds | `rojo build game/default.project.json` | OK |
| UI layout (desktop + phone) | `tools/prod/review` (browser approximation) | `docs/screenshots/production/` |
| World composition | `tools/partview` (three.js approximation) | `docs/screenshots/worlds/` |

**Not verified (requires Studio):** physics, humanoid movement, boss chases, treadmill training
feel, ViewportFrame framing, lighting look, particle/trail look, DataStore persistence, receipts,
mobile performance, and the in-engine rendering of every UI screen.

## 4. First play-test checklist (Owner)

1. Spawn in the **Farm Safe Zone**. Confirm you are assigned a farm (owner plate shows your name)
   and that the HUD shows Speed/Cash and the round timer.
2. Wait for the fog gate (7 s), walk into **World 1 – Demon Slayer** and pick up an egg. Check the
   carry banner ("Reach the Farm Safe Zone!"), Akaza reacting after ~1 s, and the chase.
3. Run back. The egg must **auto-secure** the moment you cross the safe-zone fence (there is no
   button), and the hatch widget must start 60 s.
4. Use HATCH NOW (dev) → **OPEN** → the reveal should show the real 3D character model; the Index
   entry must unlock (silhouette → model).
5. Characters menu → Equip / Unequip / **Equip Best**. Farm characters should wander inside your plot.
6. Run on the **treadmill** (Speed rises only while actively running on the belt). Use the physical
   sign to upgrade and check the 10 visual levels.
7. Makima kiosk → buy/equip a trail. Check the flat ground ribbon that widens with age, the aura
   while moving, and colour cycling on Divine/Monarch/Infinity.
8. Rem kiosk → multi-select, sort, **SELL** (value is computed by the server).
9. Two players: bat-hit a carrier (egg drops, expires in 30 s). Let a boss catch you inside its
   world (egg returns plus knockback) and after leaving the world (egg drops).
10. Wait for the 300 s round end: players outside are returned to the farm and eggs/bosses reset.

## 5. OWNER ACTION REQUIRED

| # | Action | Why / where |
|---|---|---|
| 1 | **Set Max Players = 7** in *Game Settings → Places* (or the Creator Dashboard) | Set in the file (`Players.MaxPlayers = 7`), but the published server size is a game setting |
| 2 | **Enable API Services** (Studio) and publish so DataStores work | Session-locked profiles and receipt dedup need DataStore access |
| 3 | **Create Developer Products / Game Passes** and paste ids into `SAE_Shared.MarketplaceConfig` | All ids are `nil` by design; Shop shows "COMING SOON" and purchases are disabled until then |
| 4 | **Upload the UI art** (3 atlases + 6 tiling images from `assets/png`) and paste ids into `SAE_Client.AssetIds` | Roblox images must be uploaded by the account owner. Until then the UI shows gradients/text only (see `docs/IMPORT_GUIDE.md`) |
| 5 | **Import the real character models for the 40 stand-ins** (list in `docs/IMPORT_AUDIT.md`) | 5 Demon Slayer rigs come from the Last CP. The other 40 characters and 8 bosses are original stand-in rigs (`StandIn=true`). Known ids still to import: Shigaraki `17832884677` |
| 6 | **Makima and Rem vendor models** | Currently original stand-ins (Rem was chosen as the Sell vendor: popular, female, not one of the 45) |
| 7 | **Tanjiro egg decision** | No approved Tanjiro egg existed, so a provisional pipeline egg is used. Approve it or supply one |
| 8 | **Premium animations** (optional) | Default R6 animation ids are used. Override tables are in `SAE_Shared.Animations` |
| 9 | **Developer whitelist** | `SAE_Server.DevService.DEVELOPER_USER_IDS` (empty). Dev commands work in Studio only until you add ids |
| 10 | **Balance approval** | All non-OWNER_LOCKED numbers are PROVISIONAL (`docs/generated/BALANCE_TABLES.md`); see the WalkSpeed cap note in the change report §47 |

## 6. OWNER TOOL REQUEST

```
OWNER TOOL REQUEST
Tool:        Roblox Studio MCP (or any Studio automation bridge) connected to this session
Purpose:     run real play tests of the Owner Review build (movement, bosses, treadmill,
             ViewportFrames, trails, DataStore) and capture in-engine screenshots
Why needed:  the build environment has no Roblox Studio; all verification so far is offline
Scope:       read/run the place in Studio; no publishing, no asset uploads, no account access
Alternative: the Owner runs the §4 checklist manually and shares screenshots/output logs
```

No other software was installed silently. The tools used (Rojo, selene, StyLua, Lune, unar,
ffmpeg, three.js) are local build/verification tools and are not part of the game.
