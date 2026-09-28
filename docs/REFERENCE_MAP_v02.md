# Reference Map — v02

All paths are repository-relative (`$REPO_ROOT/…`). The Owner's uploaded package was copied into the
repo so future sessions do not depend on per-session upload paths.

**Sources:**

| Upload | Content |
|---|---|
| `guide_steal_an_anime_egg.rar` | **identical** (byte-for-byte) to the earlier intake upload; items R01–R14, V01 |
| `guide_steal_an_anime_egg_2.rar` | 12 new screenshots, items N01–N12 |
| `StealAnimeEgg_UI_Lab_COMPLETE.zip` | **identical** to the earlier upload; the UI Lab is already in this repo (`src/`, `tools/`, `dist/`) |
| `Claude_Videos_Set_01…10_of_10.zip` | 6 videos, audited in `docs/VIDEO_REFERENCE_AUDIT_v02.md`. The videos are not committed (≈290 MB); contact sheets are in `art/reference/v02/video_contact_sheets/`. Original SHA-256s are listed in `Final_Verification.csv` (Set 09) |
| `checkpoints/StealAnAnimeEgg_v01_SAFE_TEST.rbxlx` | Git LFS, 111,715,271 B, SHA-256 `f260e511…78c3c8a`. Owner-imported characters (`docs/CHARACTER_IMPORT_AUDIT_v02.md`) |

## 1. Logical reference names → file → what it controls

| Logical name | File (`art/reference/v02/…`) | Controls | Not authoritative for |
|---|---|---|---|
| MAIN_MULTI_WORLD_REFERENCE | `guide1/R02_master_multi_world_maps_and_eggs.png` | World **maps**: Dragon Ball (Namek), One Piece (Dressrosa/colosseum), Naruto (Konoha), JJK (Shibuya), Solo Leveling (Shadow corridor). **Eggs** for every character shown in it | Bleach map (see below). Berserk panel (obsolete). Yamamoto / Thomas Andre eggs (roster changed) |
| MHA_SHIGARAKI_PURPLE_REFERENCE | `guide1/R01_MHA_Shigaraki_world.png` | MHA world: villain bar/lounge side structures, purple/grey palette, purple-emissive cracks (no pits), Shigaraki throne | MHA eggs (not shown; design new ones by motif) |
| BLEACH_YHWACH_PALACE_MAP_REFERENCE | `guide1/R10_Bleach_Yhwach_palace_map.png` | **Bleach map**: grey/black monumental corridor, white banners with insignia, braziers, throne with Yhwach | Bleach eggs (use R02 where shown; Yachiru is new) |
| DS_CURRENT_AKAZA_WORLD | `guide1/R12_Akaza_world_current.png` + `guide2/N08…N11` | Demon Slayer world **benchmark** (torii arena, compass needle, bamboo, river) and the **approved DS eggs**: Rengoku, Muzan, Akaza, Yoriichi (N08–N11) | — |
| TANJIRO_EGG_CANDIDATE | `guide2/N12_Egg_Tanjiro_Water_other_local_file.png` | Shows a model named `Egg_Tanjiro_Water` (blue water-wave egg) in the Owner's **other** local file `Desktop\StealAnAnimeEgggyugyu….rbxlx`. **It is not in SAFE_TEST.** OWNER DECISION: is this the approved Tanjiro egg (a re-purposed Giyu water egg)? | — |
| TREADMILL_REFERENCE | `guide2/N01_treadmill_upgrade_progression.png` + `guide1/R09_treadmill_inspiration.png` + V3 video | Low tier: dark/lava machine. Max tier: white marble pillars, gold, angel wings, flames. Physical evolution per level; `+Speed` floaters; upgrade sign | Robux/price values; literal copying |
| FARM_WALL_REFERENCE | V3/V4/V5 video backgrounds (sheets `V3_Desktop_1504_*`, `V5_Desktop_1514_01`) | One substantial **tan/orange/brown checker-block** outer wall around the whole farm area | Per-pen fences (SAE farms stay open) |
| UPGRADE_SIGN_REFERENCE | `guide1/R04_upgrade_sign_pattern.png` + V5 | Physical upgrade signs; upgrades visibly transform the object | — |
| TRAIL_SHOP_REFERENCE | `guide1/R05…`, `R06…` | Trail Shop kiosk + menu (rebuilt in UI Lab style) | Robux prices |
| SELL_REFERENCE | `guide1/R07…`, `R08…` | Sell menu + booth ("Characters", never "Pets") | Fuse machine |
| INDEX_CURRENT_SCREENSHOT | `guide2/N02…`, `N03…` (REJECTED) + V2 4:08 | **What to fix**: naked blocky previews, `???` panel overlapping the sidebar, cramped layout, 45-count | — |
| INDEX_TARGET_REFERENCE | V6 video (Pet Index) | Layout ideas: large grid, world progress bar, claim reward, detail panel | "Pet" wording, offline earnings |
| TRAIL_AURA_REFERENCE_VIDEO | `guide1/V01_trail_aura_motion.mp4` + V4 video | Flat ground ribbon from the feet that widens with age, colour cycling, per-tier identity | — |
| STEAL_AN_EGG_GAMEPLAY_REFERENCE | V3, V4, V5, V6 | Route, carry, drop, boss "RUN!!", PvP bat, **manual egg placement** (V4 2:38), Growing Eggs, hatch emerge | Their themes, offline income, hatch minutes |
| SAFE_TEST_REVIEW_VIDEO | V1, V2 | **Current rejected state** of v01 | — (not a target) |
| CHARACTER_IMPORT_SCREENSHOTS | `guide2/N04` (Gojo Sukuna-Fight, extra), `N05` (JJK wheel character), `N06` (`StarterCharacter`, Muzan secret) | Identify imported models | — |
| LEGACY_UI_BASELINE | `guide1/R03_legacy_ui_baseline.png` | Retired | — |
| ROUTE/HUB CURRENT | `guide1/R13…`, `R14…` | Current state only | — |
| BERSERK / GRIFFITH | `guide1/R11_Griffith_egg_OBSOLETE.png`, R02 Berserk panel | **Obsolete**: Berserk World removed. Guts is an Extra with a custom egg | Everything |

## 2. Authoritative reference per active World

| # | World | Map authority | Egg authority |
|---|---|---|---|
| 1 | Demon Slayer (Akaza) | existing SAFE_TEST Akaza world (R12, N08) | approved DS eggs (N08–N11, protected). Tanjiro: OWNER DECISION (N12 candidate vs provisional) |
| 2 | MHA (Shigaraki) | R01 | new motif designs (MHA eggs not in R02) |
| 3 | Dragon Ball (Frieza) | R02 Namek panel | R02 |
| 4 | One Piece (Doflamingo) | R02 Dressrosa panel | R02 (Nami/Kaido as shown) |
| 5 | Naruto (Madara) | R02 Konoha panel | R02 |
| 6 | Bleach (Yhwach) | **R10** (not R02's Bleach panel) | R02 Bleach eggs (Ichigo, Aizen = galaxy, Kenpachi, Yhwach). **Yachiru: custom new** |
| 7 | JJK (Sukuna) | R02 Shibuya panel | R02 (Yuji, Gojo, Toji, Mahoraga, Sukuna). **Maki: custom new** |
| 8 | Solo Leveling (Sung Jin-Woo) | R02 Shadow corridor panel | R02 (Igris, Beru, Cha Hae-In A). **Cha Hae-In B: custom new** |
| — | Extras | — | custom new: Guts, Shinjuku Gojo, Megumi-body Sukuna |
