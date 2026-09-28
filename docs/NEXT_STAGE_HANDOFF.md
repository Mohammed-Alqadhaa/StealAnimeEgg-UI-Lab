# Handoff — cloud stage stopped; next stage runs locally with Roblox Studio MCP

The cloud-side production pass is **stopped at this checkpoint**. It is **not** final production.

## Current checkpoint

| Item | Value |
|---|---|
| Latest Owner Review place | `checkpoints/StealAnAnimeEgg_FullProduction_OwnerReview_v01.rbxlx` |
| v01 SHA-256 (verify before touching) | `01abd251437107aeae200c2c500a9d1317675310175ab22ae08c39d346b19b3b` |
| Baseline (read-only) | `checkpoints/StealAnAnimeEgg_PreClaudeTakeover_20260928.rbxlx`, SHA-256 `dc8d2af1…` |
| Branch | `claude/loving-pasteur-oayq18` |
| v02 | **not created.** Create it only after real Studio testing and fixes, never overwriting v01 |

## Added in this stage

* **Studio Play-mode test harness:** `game/src/studio_tests/Runner.server.lua`, 52 tests. See
  `docs/STUDIO_TEST_HARNESS.md`. It has not been run yet.
* **`SAE_Server.TestGate` and gated hooks:**
  * `Remotes.TestCall` and `Remotes.TestClearRate`
  * `EggService.TestPickUp` and `EggService.TestEggInfo`
  * `PvPService.TestSwing` and `PvPService.TestResetCooldown`
  * `TreadmillService.TestRefresh` and `TreadmillService.TestMachine`

  All hooks are inert unless Studio **and** `ServerStorage.SAE_EnableStudioTests = true`.
* **Rojo and assembler:** `game/default.project.json` and `game/assembler/build.luau` now include
  `ServerScriptService.SAE_StudioTests` for future builds. v01 was **not** rebuilt, so it does not
  contain the harness or the hooks. Sync with Rojo, or build a new checkpoint.

## Next stage (local Claude Code session + Roblox Studio MCP), in order

1. Open v01 in Studio and confirm its SHA-256.
2. Sync the current branch (Rojo), or build a new Studio-validation checkpoint. Never overwrite v01.
3. Run the harness in single-player, then with 2 players. Fix the failures, then re-run.
4. Do visual production work in Studio:
   * inspect all 9 worlds, the hub and the farms;
   * replace the placeholder characters and bosses (bosses first) with sanitized, audited assets;
   * boss animation and presentation;
   * UI image upload/binding at multiple resolutions;
   * show the Tanjiro egg to the Owner;
   * trail feel;
   * all 10 treadmill levels.
5. Tune the WalkSpeed cap **only after** real trail tests, so that x7, x10, x14 and x20 stay
   distinct.
6. Set Max Players = 7 (or list the exact OWNER ACTION steps).
7. Produce `StealAnAnimeEgg_FullProduction_OwnerReview_v02.rbxlx` with its SHA-256, commit, real
   Studio screenshots, the Studio test report, the multiplayer report, and the remaining
   placeholders and Owner actions.

## Unchanged open items (from `docs/OWNER_REVIEW_BUILD.md` §5)

* 40 characters, 8 bosses and 2 vendors are still **placeholder stand-ins**.
* UI images are not uploaded, and Robux product ids are nil.
* The Tanjiro egg awaits Owner approval, and the balance is provisional.
