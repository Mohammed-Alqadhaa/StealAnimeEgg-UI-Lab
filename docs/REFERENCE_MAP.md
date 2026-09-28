# Reference Map: Steal an Anime Egg Master Package

Every supplied reference, mapped to the **one system/world it is authoritative for**
(Master Prompt §17–23). Files are not a generic moodboard.

## Package inventory

| Item | Where it actually came from | Verified |
|---|---|---|
| `StealAnAnimeEgg_last_CP.rbxlx` (production baseline) | **uploaded separately**, not inside the RAR (the prompt lists it at `guide steal an anime egg/roblox last CP/…`; that folder is not in the archive) | 20,636,289 bytes · SHA-256 `dc8d2af1cc2f42674350c788daef3317bdfd23e1441944cd160ee50c88919d0b` |
| `StealAnimeEgg_UI_Lab_COMPLETE.zip` | **uploaded separately**, not inside the RAR | byte-identical to `dist/StealAnimeEgg_UI_Lab_COMPLETE.zip` in this repo |
| `guide steal an anime egg.rar` | RAR5, 15 entries, extracted with `unar` (7-Zip here lacked the RAR5 codec) | all 15 extracted |

## Image / video → system mapping

| ID | File | Authoritative for | NOT to be used for |
|---|---|---|---|
| R02 | `ChatGPT Image Sep 28, 2026, 06_44_23 AM.png` | **Master multi-world image.** MAPS: Dragon Ball (Planet Namek), One Piece (Dressrosa/Colosseum), Naruto (Konoha), Berserk (The Eclipse), JJK (Shibuya), Solo Leveling (Shadow Corridor). EGGS: Goku, Vegeta, Gohan, Broly, Frieza · Luffy, Zoro, (Nami), Kaido, Doflamingo · Naruto, Sasuke, Kakashi, Itachi, Madara · Guts, Casca, Skull Knight, Zodd · **Bleach eggs** Ichigo, Aizen, Kenpachi, Yamamoto, Yhwach · Yuji, Gojo, Toji, Mahoraga, Sukuna · Igris, Beru, Cha Hae-In, Thomas Andre, Sung Jin-Woo | Bleach map (its Bleach panel is superseded by R10); Griffith egg (superseded by R11) |
| R10 | `Screenshot 2026-09-28 062408.png` | **Bleach world ENVIRONMENT only** (Yhwach Palace: monumental grey/black corridor, white banners with dark insignia, braziers, throne at far end, BOSS YHWACH seated) | Bleach eggs (the dark silhouettes here are placeholders) |
| R11 | `Screenshot 2026-09-28 063032.png` | **Griffith / Femto egg only** (pale sculpted bust/egg, crown-like hair, white-violet glow, nameplate plinth) | any other Berserk element |
| R01 | `ChatGPT Image Sep 28, 2026, 06_35_21 AM.png` | **MHA / Shigaraki world.** League-of-Villains bar/lounge on one-level side structures, violet/purple/grey, cracked slabs with purple emission (no pits), rubble, chains, hand motifs, red hand banners, Shigaraki seated on rubble throne | egg designs (MHA eggs follow §36 motifs) |
| R09 | `Screenshot 2026-09-28 053929.png` | **Treadmill quality/progression inspiration** (heavy stylised machine, `+1,000/step` floater, adjacent Upgrade sign `Level 9 > Level 10` with cash + premium price) | literal copy (Owner: do not copy exactly) |
| R04 | `Screenshot 2026-09-28 051922.png` | Physical **upgrade sign** pattern (Upgrade Pen: level → level, price button, red "!" affordance); HUD/rail layout context | — |
| R05 | `Screenshot 2026-09-28 052043.png` | **Trail Shop kiosk** in the hub (stall + awning + big floating title) | — |
| R06 | `Screenshot 2026-09-28 052051.png` | **Trail Shop menu** (tier cards, figure with trail, `xN Speed`, Equip/Unequip, cash + Robux price) → rebuilt in UI Lab style | — |
| R07 | `Screenshot 2026-09-28 052451.png` | **Sell menu** (sort, Select All, grid with value + $/s, Total Value, Sell) → "Sell **Characters**" in UI Lab style | the word "Pets" |
| R08 | `Screenshot 2026-09-28 052510.png` | **Sell booth** (red/white striped stand + big SELL title) placement cue; global announcement banner style | Fuse machine (not in scope) |
| R03 | `Screenshot 2026-09-28 033304.png` | **Baseline to retire**: legacy basic UI (Index 1/5 with R15 silhouettes, flat nav, `SPEED —`, Unsafe/Secured/Clear preview buttons) | — |
| R12 | `Screenshot 2026-09-28 065125.png` | Current **Akaza / Demon Slayer world** state (torii arena, compass needle, **approved central Demon Slayer eggs**, Akaza boss) | — |
| R13 | `Screenshot 2026-09-28 065137.png` | Current route bridge from hub to Zone 1 (placeholder spheres to replace) | — |
| R14 | `Screenshot 2026-09-28 065156.png` | Current **farm hub** (per-farm fences → to be replaced by one shared perimeter fence; "6 ANIME ZONES" gate → 9 worlds + Fog Gate) | — |
| V01 | `كيفية حركة ال trail و الاورا عند ركض الشخصية.mp4` | **Trail/aura motion** (see below) | — |

### V01 findings (12.8 s, 1280×720 @ 60 fps, viewed frame-by-frame)
* One long ribbon emitted **low on the character (feet/hips)**, lying flat along the
  ground, **narrow at the emitter and widening with age**, several seconds long, and it
  **curves smoothly** with the player's path.
* Colour gradient along its length (dark orange at the source → bright yellow), with the
  palette **cycling over time** (yellow → lime/rainbow → pink/cyan → violet → magenta).
* Solid near the player, soft fade at the tail; **stops when the player stops**.
* No separate aura is readable at this resolution. The "aura" is therefore implemented
  as a velocity-driven particle layer (§96 tier progression), intensity scaling with speed.

## Demon Slayer eggs (approved, preserved)

Located in the **centre of the Akaza arena** (z ≈ 353–370, around the compass needle):

| Egg model (Workspace) | Character | Status |
|---|---|---|
| `OfficialEggInspection/RawAssets/Yoriichi - Flaming Egg of Burning` | Yoriichi | active |
| `OfficialEggInspection/RawAssets/Muzan - McVisibility Demons Heart Egg` | Muzan | active |
| `OfficialEggInspection/RawAssets/Akaza - Crimson Catsegg V2.0` | Akaza (boss egg) | active |
| `OfficialEggInspection/RawAssets/Rengoku - flame egg` | Rengoku | active |
| `Egg_Giyu_Water` (+ `GiyuWaterEggAnimation`) | Giyu | **preserved/archived, not active** |
| **Tanjiro** | Tanjiro | **NO existing egg in the place → gap** (see Owner Actions) |

Other DS egg sets (`Shinobu`, `Gyomei`, `Mitsuri` raw eggs, the six gated
`*PremiumEggTemplate` theme eggs, `Muzan_Corrupted_Egg_…_v03`) are **archived, not deleted**.

## World order (Master Prompt §24)
1 Demon Slayer (R12) · 2 MHA (R01) · 3 Dragon Ball (R02) · 4 One Piece (R02) · 5 Naruto (R02) ·
6 Berserk (R02 map; R11 Griffith egg) · 7 Bleach (R10 map; R02 eggs) · 8 JJK (R02) · 9 Solo Leveling (R02)
