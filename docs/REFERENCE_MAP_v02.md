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

## 3. Authoritative per-world composition (World Production Correction Directive)

The Owner's references are the visual authority. The legacy v01 world slot is a gameplay constraint only; it is the
lowest-priority visual constraint (directive §15).

| # | World | Authoritative map image | Special override | Composition requirements (what must stay recognisable) | Egg-reference source | Obsolete |
|---|---|---|---|---|---|---|
| 1 | Demon Slayer (Akaza) | **existing preserved SAFE_TEST environment** (baseline), R12 / N08 | Not rebuilt. Additive and reversible only, fingerprint-guarded | Widened torii arena (150-stud walls, 122 walk), compass inlay, river + waterfalls, bamboo, lanterns | approved DS eggs (N08–N11, protected). Tanjiro: Owner approval pending | the original un-widened Last CP Zone1 as the target (kept only as backup A) |
| 2 | MHA (Shigaraki) | R01 | — | Purple villain hideout / bar (left) + lounge (right); cracked purple-glow floor; Shigaraki throne of slabs + decay hands + red cloak; torn hand banners; lantern posts + chains; **purple city + elevated highway behind the throne** | new motif eggs (MHA eggs not in R02) | — |
| 3 | Dragon Ball (Frieza) | R02 "Planet Namek" panel | — | Green sky + **large planet upper-left**; stone causeway with lanterns; turquoise sea; Ajisa trees + Namekian domes; tan mesas + waterfalls; Frieza on a dark stage with purple arch | R02 | — |
| 4 | One Piece (Doflamingo) | R02 "Dressrosa" panel | — | Corrida Colosseum: tiered stands full of spectators **on both sides and behind the boss**, arcade crown, Jolly Roger banners, lamp posts, pale path; Doflamingo in front of the pink feather coat | R02 (Nami/Kaido as shown) | — |
| 5 | Naruto (Madara) | R02 "Konoha" panel | — | Village street with red-roof timber houses, Leaf banners, lanterns; **Hokage Rock faces rising behind Madara**, above the red round Hokage building | R02 | — |
| 6 | Bleach (Yhwach) | **R10** (separate Yhwach Palace reference) | R10 overrides R02's Bleach panel for the map | Monumental grey/black corridor, polished floor, white banners with the black Wandenreich cross, braziers, **gothic palace façade behind the throne**, Yhwach enthroned at the top of stairs | R02 Bleach eggs (Ichigo, Aizen, Kenpachi, Yhwach); **Yachiru: custom new** | R02 Bleach **map** panel; any older rejected Bleach environment |
| 7 | JJK (Sukuna) | R02 "Shibuya" panel | 6 characters / 6 eggs | Shibuya street under a red sky, neon signs, dark blocks, giant red torii, Sukuna's shrine | R02 (Yuji, Gojo, Toji, Mahoraga, Sukuna). **Maki: custom new** | old 5-egg layout |
| 8 | Solo Leveling (Sung Jin-Woo) | R02 "Shadow Corridor" panel | — | Long symmetric corridor, shadow soldiers along both walls, blue flames, **closed corridor end with the Monarch's throne + gate** | R02 (Igris, Beru, Cha Hae-In A). **Cha Hae-In B: custom new** | Thomas Andre egg |
| — | **Berserk** | — | **Obsolete as an active world** (R02 Berserk panel, R11 Griffith egg) | — | Guts = Extra with a custom egg | everything Berserk |

**Next-world rule (directive §7):** current world, then boss focal composition, then a designed opening, then the
next world seen through it. The openings used are:
* MHA: two corridors beside the throne.
* One Piece: the arena gate through the far stands.
* Naruto: two passes through the Hokage mountain.
* Bleach: two openings beside the throne in the palace façade.
* JJK: the torii and street.
* Solo Leveling: the Monarch's gate.
* Dragon Ball: open causeway beside the Frieza stage.
