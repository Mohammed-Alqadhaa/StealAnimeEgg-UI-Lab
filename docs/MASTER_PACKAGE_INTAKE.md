# Master Package Intake: catalog & inspection (pre-implementation)

Status: **inspection complete. Implementation not started.**
The master prompt referenced as "below" was **not included** in the message, so the
requirement mapping in §4 is *provisional* (inferred from the images alone) and must be
confirmed against the real master prompt.

## 1. Inputs received

| File | Size | Status |
|---|---|---|
| `guide_steal_an_anime_egg.rar` (RAR5, 15 files) | 28.2 MB | Extracted fully with `unar`. The first try with 7-Zip decoded only the 7 stored (uncompressed) entries; `unar` extracted all 15 cleanly. |
| `StealAnAnimeEgg_last_CP.rbxlx` | 20.6 MB | Parsed: 4,725 instances, 17 scripts |
| `StealAnimeEgg_UI_Lab_COMPLETE.zip` | 13.2 MB | **Byte-identical** (SHA-256 `ce6fad4e…`) to the package built in this session |

## 2. RAR contents (IDs used below)

| ID | File | What it shows |
|---|---|---|
| R01 | ChatGPT Image 06_35_21 | Concept art: purple/void **boss arena** (Shigaraki-style hands, throne, chains, cracked neon floor, 5 eggs on black-crystal pedestals, bar/lanterns) |
| R02 | ChatGPT Image 06_44_23 | Concept board: **7 anime zones** (Dragon Ball/Namek, One Piece/Dressrosa, Naruto/Konoha, Berserk/Eclipse, Bleach/Yhwach Palace, JJK/Shibuya, Solo Leveling/Shadow Corridor), each with boss + **5 themed eggs on named plinths** |
| R03 | Screenshot 033304 | **Current production UI** in Studio: plain Index "Demon Slayer / Character Index 1/5", R15 silhouettes, flat nav, "SPEED —/CASH —", Unsafe/Secured/Clear preview buttons, "UI PREVIEW • sample data" banner (the "too basic" baseline) |
| R04 | Screenshot 051922 | Reference game: **Upgrade Pen** world sign (Level 10 > 11, $500T button, red "!" marker), HUD, right icon rail |
| R05 | Screenshot 052043 | Reference game: **TRAILS SHOP** world stall (awning, chest, "FREE" claim board) |
| R06 | Screenshot 052051 | Reference game: **Trail Shop menu**: 3 rarity cards (Eternal/Divine), trail on a posed figure, `x10/x14/x20 Speed`, Equip / Unequip / cash + premium price |
| R07 | Screenshot 052451 | Reference game: **Sell Pets menu**: sort by Weight/Value, Select All, grid with kg + $/s + value, Total Value + Sell; Eggs/Pets side tabs |
| R08 | Screenshot 052510 | Reference game world: **SELL stand**, **Fuse Machine 0/3**, global announcement "ALL EGG RESET! / A Eternal Mosasaurus Egg spawned in Prehistoric!" |
| R09 | Screenshot 053929 | Reference game: **treadmill** (lava/chains) with `+1,000/step` floater and Upgrade sign (Level 9 > 10, $1Qa / premium 1.2K) |
| R10 | Screenshot 062408 | Bleach / **Yhwach Palace** zone: BOSS Yhwach + 5 **dark egg silhouettes** on plinths (Ichigo, Aizen, Kenpachi, Yamamoto, Yhwach) |
| R11 | Screenshot 063032 | Tiny crop: **Griffith** bust/egg on a nameplate plinth (Berserk) |
| R12 | Screenshot 065125 | Last CP in Studio: **Zone 1 (Demon Slayer)**: torii arena, Akaza boss, magic circle, eggs on pads, old UI overlay |
| R13 | Screenshot 065137 | Last CP: purple **route bridge** to Zone 1, placeholder egg spheres on pads |
| R14 | Screenshot 065156 | Last CP: **farm hub**: FARM 3/6 plots with TRAIN/ENTER labels, "6 ANIME ZONES" gate with 6 colour markers |
| V01 | `كيفية حركة ال trail و الاورا عند ركض الشخصية.mp4` ("how the trail and aura move when the character runs") | See §3 |

## 3. Trail / Aura video (12.8 s, 1280×720 @60 fps, H.264), watched frame by frame

* The player runs through themed biome corridors (Desert, Jungle, Snow, Volcano, Abyss
  Ocean, Prehistoric, Cosmic), with zone name banners at the top.
* **Trail:** one continuous ribbon emitted from the character's **lower body/feet**,
  **flat and ground-hugging**, very long (reaches the camera, ~several seconds of
  lifetime). It is **narrow at the emitter and widens with age**. The colour runs
  **dark orange/brown at the source → bright yellow** further back, and the palette
  cycles over time (yellow → lime/rainbow → pink/cyan → violet/green → magenta/cyan).
  It **curves smoothly** when the player turns, so it follows the path (Roblox `Trail`
  between two attachments, or a Beam chain). Full opacity near the player, soft fade at
  the tail. It disappears when the player stops (last frames).
* **Aura:** no distinct aura (particles or glow around the body) is visible at 1280×720.
  Frame crops around the character show only the trail. **Needs confirmation** of
  what "aura" should look like.

## 4. Last CP inspection (`StealAnAnimeEgg_last_CP.rbxlx`)

**Server** (`ServerScriptService`): `Phase1Init` boots `FarmService` (7 farms,
server-authoritative ownership + safe-zone bounds, `IsPlayerInsideOwnFarm`),
`PlayerStatsService` (**Muscle** → Speed/Strength/WalkSpeed, server-enforced WalkSpeed,
`CanCarryEggSize`), `TrainingService` (ProximityPrompt on each farm **BoxingBag**, cooldown,
distance, own-farm rule). Also `InspectionWorld` (rebuilds `FarmHubVisualPrototype` at
runtime, sets `RuntimeAssemblyReady`), `AkazaBossController` (Zone 1 chase boss),
`GiyuWaterEggAnimation`. `ReplicatedStorage.GameConfig` holds all tunables
(still references boxing-bag recoil).

**Client** (`StarterPlayerScripts`): `AnimeEggUiDesign` (910 lines, builds the
current UI in code **including a Rebirth window**), `MuscleHud`, `FarmOwnershipClient`
(Lemonade UI-scale converter embedded), `AkazaLocalAtmosphere`, `AkazaZoneVFX`.
`StarterGui` has `AnimeEggUI` (Root/MuscleHud/NavStack) + an empty `ScreenGui`.

**World:** `FarmHubVisualPrototype` (7 farms × 338 parts, `SharedWorldExit`,
`SixZoneRoute` Zone1–6: Zone1 = Demon Slayer arena from `BlenderEnvironment` + Akaza;
Zone2 labelled "SHIGARAKI"; Zones 3–6 "FUTURE THEME"; each placeholder zone has 3
EggPads/Eggs + boss placeholder). `OfficialEggInspection/RawAssets` has 8 Demon Slayer
egg models (Yoriichi, Muzan, Akaza, Rengoku, Shinobu, Gyomei, Giyu, Mitsuri). Character
R6 models (Rengoku, Tanjiro, Akaza, Muzan, Yoriichi) in Workspace; premium egg MeshPart
templates + Blender environment in `ServerStorage`. Lighting has ColorCorrection +
Bloom. 13 ParticleEmitters, 8 Beams, **no Trail instances** yet.

**Gaps vs the UI Lab:** the Last CP UI still has Rebirth and a "Muscle" HUD. Farms still use
BoxingBag training (the lab brief says no boxing bag; the references show a
**treadmill** with `+N/step`). The lab is not integrated into the place yet.

## 5. UI Lab (as built this session)

ScreenGui model + Rojo source, 53 original SVG/PNG assets, browser preview, docs; covers
Nav, Speed/Cash HUD, Shop, Index, Eggs, Characters, Upgrade (Character/Treadmill/Farm),
Egg Carry, Hatch timer, Preview panel. Verified: Rojo build/round-trip, selene 0/0, Lune 91/91.
Studio visual verification not performed.

## 6. Provisional reference → requirement map (confirm against the master prompt)

| Likely requirement | References |
|---|---|
| Zone 2 Shigaraki / boss-arena art direction | R01 (+ R14 zone gate) |
| Future zone themes, per-zone boss + 5 named eggs, egg-plinth styling | R02, R10, R11 |
| Baseline to replace (current UI quality) | R03, R12–R14 overlays |
| World upgrade signs (farm/pen, treadmill upgrade) | R04, R09 |
| Treadmill replacing boxing bag, `+N/step` floater | R09 (+ R14 TRAIN labels) |
| Trail shop (world stall + menu, speed multipliers, equip/unequip, dual price) | R05, R06 |
| Trail/aura running VFX | V01 |
| Sell menu (sort, select all, total value) / Sell stand / Fuse machine | R07, R08 |
| Global egg spawn / reset announcements | R08 |
| Integration target (farms, zone route, Zone 1 arena, eggs) | R12, R13, R14, Last CP |

## 7. Blocking questions before implementation

1. **Master prompt missing:** please paste the master prompt text. §6 is only a guess.
2. **Aura:** no aura is visible in V01. Describe it or send a clearer clip/frame.
3. **Target:** implement inside the Last CP place, or keep the lab separate and
   ship an integration package?
4. **Repo access:** pushes to `Mohammed-Alqadhaa/StealAnimeEgg-UI-Lab` are rejected (403).
   Work is committed locally only.
