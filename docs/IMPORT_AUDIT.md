# Import Audit — Owner Review v01

Machine-readable source: `docs/generated/ASSEMBLY_REPORT.json` (`importAudit`, `moved`, `archived`, `standIns`).
Rule applied (asset safety rules of the master prompt): every model taken from an existing file is
**sanitized** before use. Scripts, LocalScripts, ModuleScripts, RemoteEvents/Functions,
Bindables, Tools, unknown `Configuration` objects and suspicious attributes/tags are removed. No
marketplace/Toolbox asset was inserted, because the environment has no Studio and no marketplace access.

## 1. Sanitized existing models (from the Last CP)

| Model | Source | Removed during sanitization | Used as |
|---|---|---|---|
| Tanjiro | Last CP `Workspace.Tanjiro Kamado` (asset 4167214076) | 47 attributes | farm NPC rig + Index/reveal model |
| Rengoku | Last CP `Workspace.Rengoku` (asset 17831748983) | 70 attributes, 2 Configuration | same |
| Yoriichi | Last CP `Workspace.Yoriichi` (asset 17834842386) | 4 Configuration | same |
| Muzan | Last CP `Workspace.Muzan` | 70 attributes, 3 Configuration | same |
| Akaza | Last CP `Workspace.Akaza` (asset 17831588851) | 77 attributes, 4 Configuration | same |
| Akaza (boss, 2.7× scale) | Last CP Zone1 boss | 68 attributes | Demon Slayer world boss |

The removed attributes were Blender/pipeline metadata. No script, remote or tool was found inside
these rigs. The place test re-checks that `Workspace`, `ServerStorage.SAE_Assets` and
`ReplicatedStorage.SAE_Preview` contain **no scripts, remotes, bindables or tools**.

## 2. Approved Demon Slayer eggs (moved unchanged, §31)

| Egg | From | To |
|---|---|---|
| Rengoku – flame egg | `OfficialEggInspection.RawAssets` | `Worlds.DemonSlayer.Eggs.RengokuSpawn.Visual` |
| Akaza – Crimson Catsegg V2.0 | same | `…AkazaSpawn.Visual` |
| Muzan – McVisibility Demons Heart Egg | same | `…MuzanSpawn.Visual` |
| Yoriichi – Flaming Egg of Burning | same | `…YoriichiSpawn.Visual` |

The place test asserts that each approved egg's descendant count equals the baseline's (no redesign).
The **Tanjiro** egg is a provisional pipeline egg (OWNER ACTION #7). **Giyu's** Water egg + VFX is
preserved in `ServerStorage.SAE_Archive.PreservedEggs`.

## 3. Original stand-ins (to be replaced by real models — OWNER ACTION #5, #6)

40 characters use original R6 stand-in rigs built by `game/assembler/lib/Rigs.luau` (attribute
`StandIn = true`: hair silhouette, palette and a signature prop per character). They are not
copies of any third-party asset.

| World | Stand-ins |
|---|---|
| My Hero Academia | Deku, Bakugo, Todoroki, All Might, **Shigaraki (boss, seated; known asset 17832884677)** |
| Dragon Ball | Goku, Vegeta, Gohan, Broly, **Frieza (boss)** |
| One Piece | Luffy, Zoro, Nami, Kaido, **Doflamingo (boss)** |
| Naruto | Naruto, Sasuke, Kakashi, Itachi, **Madara (boss)** |
| Berserk | Guts, Casca, Skull Knight, Zodd, **Griffith (boss)** |
| Bleach | Ichigo, Aizen (Muken), Kenpachi, Yamamoto, **Yhwach – The Almighty (boss, seated)** |
| Jujutsu Kaisen | Yuji, Gojo, Toji, Mahoraga, **Sukuna (boss)** |
| Solo Leveling | Igris, Beru, Cha Hae-In, Thomas Andre, **Sung Jin-Woo (boss, seated)** |

Vendors: **Makima** (Trail Shop) and **Rem** (Sell) are original stand-ins too.

**How to swap in a real model:** place the sanitized model in `ServerStorage.SAE_Assets.CharacterRigs`
under the character id (e.g. `gojo`), and put a copy in `ReplicatedStorage.SAE_Preview.Rigs`.
It must be R6 with `Humanoid`, `HumanoidRootPart`, `Head` and `Torso` with hip Motor6Ds. The
place test lists these contracts. For a boss, replace `Workspace.SAE_World.Worlds.<World>.Boss`
with the same structure.

## 4. Archived (preserved, not deleted) — `ServerStorage.SAE_Archive`

| Bucket | Content | Reason |
|---|---|---|
| LegacyServer | Phase1Init, FarmService (BoxingBag dependency), PlayerStatsService, TrainingService, InspectionWorld, AkazaBossController, GiyuWaterEggAnimation | replaced by SAE_Server; Muscle/BoxingBag/6-zone obsolete |
| LegacyClient | AnimeEggUiDesign, MuscleHud, FarmOwnershipClient, AkazaLocalAtmosphere, AkazaZoneVFX | replaced by SAE_Client (the Akaza atmosphere + zone VFX logic is carried over in WorldClient/FxClient) |
| LegacyUI | AnimeEggUI, ScreenGui | replaced by SAE_UI (UI Lab design system) |
| LegacyShared | GameConfig | Muscle/Strength config superseded by `SAE_Shared.Balance` |
| LegacyDisplayModels | Muzan, Rengoku, Tanjiro Kamado, Akaza, Yoriichi | sanitized copies live in `SAE_Assets.CharacterRigs` |
| LegacyWorld | FarmHubVisualPrototype (6-zone route + old hub) | obsolete 6-zone route. The Akaza environment was moved out first |
| PreservedEggs | Egg_Giyu_Water, OfficialEggInspection (remaining variants), Muzan_Corrupted egg | preserved per §31 |
