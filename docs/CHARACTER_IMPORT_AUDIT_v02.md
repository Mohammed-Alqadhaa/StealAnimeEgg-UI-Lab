# Character Import Audit — v02

**Source:** `checkpoints/StealAnAnimeEgg_v01_SAFE_TEST.rbxlx` (Git LFS, 111,715,271 B, SHA-256
`f260e511e48eeb23e3cd226fb63bab45cfaafbdb505c6c54e032e920f78c3c8a`). **Read-only; not modified.**

**Status:** **STRUCTURALLY VERIFIED** (parsed offline with Lune). **Not** visually verified. MeshParts,
textures and clothing reference Roblox asset ids that only render in Studio. Face swaps, scale and
looks must be checked in Studio.

## 1. What SAFE_TEST changes vs OwnerReview_v01

* **Only Workspace differs.** v01 has 11,340 Workspace descendants; SAFE_TEST has 43,315. All other
  services (ReplicatedStorage, ServerStorage, ServerScriptService, StarterGui, StarterPlayer,
  Lighting, …) are **identical in structure**, so the latest repo code can be merged without losing
  Owner work.
* **37 new top-level Workspace models**, i.e. the Owner's imports. They are laid out in rows by
  world (MHA z≈58, Dragon Ball z≈64, One Piece z≈70, Naruto z≈77, Bleach z≈84, JJK z≈92,
  Solo Leveling z≈96–107) inside the hub.
* The 108 humanoid models that also exist in v01 (DS rigs, stand-ins, preview rigs, vendors) are unchanged.

## 2. Per-import audit

Columns:
* **parts/mesh**: BaseParts / MeshParts.
* **face**: extra head-like parts (FakeHead / face-swap indicators).
* **exec**: Scripts, LocalScripts, ModuleScripts, remotes, bindables and tools inside the model.
* **cfg/attr/tag**: Configuration objects / attributes / CollectionService tags (all must be reviewed during sanitization).

| characterId | World | Role | Model path in SAFE_TEST | Rig | parts/mesh | acc | clothing | face | exec | cfg/attr/tag | identification confidence |
|---|---|---|---|---|---|---|---|---|---|---|---|
| `igris` | SoloLeveling | main | `Workspace.Igris` | R6 | 28/21 | 0 | —, SA×9 | MeshPart:HeadMainIGAW | **2**: Script:Script, Script:Script | 0/6/1 | HIGH |
| `sungjinwoo` | SoloLeveling | BOSS | `Workspace.Sung Jin-woo` | R6 | 9/0 | 2 | Shirt+Pants | — | 0 | 2/0/0 | HIGH |
| `chahaein` | SoloLeveling | main (A/B, two models) | `Workspace.Saber_Cha Hae In_Verified` | R6 | 11/2 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH; Owner says which is A vs B |
| `chahaein` | SoloLeveling | main (A/B, two models) | `Workspace.Saber_Cha Hae In_Verified` | R6 | 12/5 | 0 | Shirt+Pants | Part:Head | 0 | 0/0/0 | HIGH; Owner says which is A vs B |
| `sukuna` | JJK | BOSS | `Workspace.SUKUNA6167` | R6 | 8/0 | 1 | Shirt+Pants | — | 0 | 0/1/0 | HIGH |
| `sukuna_megumi` | EXTRA | extra/shop | `Workspace.StarterCharacter` | R6 | 18/10 | 1 | Shirt+Pants | — | 0 | 1/0/1 | LOW-MEDIUM (JJK row at x=53,z=92; wheel-bearing candidate, cf. N05; could instead be Mahoraga) |
| `mahoraga` | JJK | main | `Workspace.Character` | R15 | 19/15 | 3 | Shirt+Pants | — | 0 | 3/0/0 | LOW-MEDIUM (R15, has "Mahoraga Wheel" accessory; could instead be Megumi-body Sukuna) |
| `toji` | JJK | main | `Workspace.Toji Fushiguro` | R6 | 10/0 | 3 | Shirt+Pants | — | 0 | 3/0/0 | HIGH |
| `gojo` | JJK | main | `Workspace.Gojo satoru` | R6 | 9/0 | 2 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `gojo_shinjuku` | EXTRA | extra/shop | `Workspace.Gojo(Sukuna Fight)` | R6 | 13/0 | 6 | Shirt+Pants | — | **2**: LocalScript:Animate | 6/0/0 | HIGH (N04) |
| `yuji` | JJK | main | `Workspace.Yuji` | R6 | 10/0 | 3 | Shirt+Pants | — | **2**: LocalScript:Animate | 3/0/0 | HIGH |
| `yhwach` | Bleach | BOSS | `Workspace.Yhwach_Gold_Mode` | R6 | 18/8 | 0 | Shirt+Pants | Part:FakeHead | 0 | 0/106/4 | HIGH |
| `aizen` | Bleach | main | `Workspace.aizen (tybw)` | R6 | 10/3 | 0 | Shirt+Pants | Part:hhead | 0 | 0/0/0 | MEDIUM (named "tybw"; confirm it is the Muken version) |
| `ichigo` | Bleach | main | `Workspace.Ichigo model` | R6 | 11/0 | 3 | Shirt+Pants | — | 0 | 3/0/0 | HIGH |
| `kenpachi` | Bleach | main | `Workspace.Kenpachi_FaceSwap_Verified` | R6 | 13/3 | 0 | Shirt+Pants | Part:Head, Part:FakeHead | 0 | 0/0/0 | HIGH |
| `yachiru` | Bleach | main | `Workspace.Yachiru_FaceSwap_Verified` | R6 | 12/2 | 0 | Shirt+Pants | Part:Head, Part:FakeHead | 0 | 0/0/0 | HIGH |
| `guts` | EXTRA | extra/shop | `Workspace.Guts (Berserk Armor)` | R6 | 14/7 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `muzan_secret` | DemonSlayer | SECRET (Muzan egg) | `Workspace.StarterCharacter` | R6 | 30/22 | 0 | — | Part:Fakehead | 0 | 0/0/1 | MEDIUM (matches N06 screenshot; lone model at z=44) |
| `madara` | Naruto | BOSS | `Workspace.Madara` | R6 | 7/1 | 0 | Shirt+Pants | MeshPart:Meshes/MADARAHAIR+HEADBAND | 0 | 0/0/0 | HIGH |
| `itachi` | Naruto | main | `Workspace.Itachi Uchiha for the gfx` | R6 | 15/7 | 0 | Shirt+Pants | Part:Head | 0 | 0/0/0 | HIGH |
| `sasuke` | Naruto | main | `Workspace.Sasuke` | R6 | 9/0 | 2 | Shirt+Pants | — | 0 | 2/0/0 | HIGH |
| `naruto` | Naruto | main | `Workspace.Naruto` | R15 | 17/15 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `doflamingo` | OnePiece | BOSS | `Workspace.Donquixote Doflamingo` | R15 | 19/17 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `nami` | OnePiece | main | `Workspace.Nami Onigashima` | R6 | 19/3 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `zoro` | OnePiece | main | `Workspace.Zoro` | R6 | 9/1 | 0 | Shirt+Pants | Part:FakeHead | 0 | 0/0/0 | HIGH |
| `luffy` | OnePiece | main | `Workspace.Luffy - Gear 5` | R15 | 18/15 | 1 | Shirt+Pants | — | 0 | 1/1/0 | HIGH |
| `broly` | DragonBall | main | `Workspace.Broly` | R6 | 8/0 | 1 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `gohan` | DragonBall | main | `Workspace.BeastGohan` | R6 | 8/1 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `vegeta` | DragonBall | main | `Workspace.<empty name>` | R6 | 7/1 | 0 | Shirt+Pants | — | 0 | 0/0/0 | MEDIUM (unnamed model in DB row, between Goku and Gohan) |
| `goku` | DragonBall | main | `Workspace.Goku` | R6 | 11/2 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `todoroki` | MHA | main (DUPLICATE B, R6) | `Workspace.Shoto` | R6 | 10/0 | 3 | Shirt+Pants | — | 0 | 3/0/0 | HIGH; Owner picks A or B |
| `allmight` | MHA | main | `Workspace.All Might` | R6 | 9/0 | 2 | Shirt+Pants | — | 0 | 2/0/0 | HIGH |
| `todoroki` | MHA | main (DUPLICATE A, R15) | `Workspace.Shoto Todoroki` | R15 | 17/15 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH; Owner picks A or B |
| `deku` | MHA | main | `Workspace.StarterCharacter` | R6 | 14/7 | 0 | Shirt+Pants, SA×3 | — | 0 | 0/0/0 | HIGH (Vigilante Deku scarf/mask meshes, MHA row x=25,z=58) |
| `maki` | JJK | main | `Workspace.Toji_Maki.Toji_Maki_Verified` | R6 | 14/4 | 0 | Shirt+Pants | Part:FakeHead | 0 | 0/0/0 | MEDIUM (name "Toji_Maki"; assumed Maki) |
| `kakashi` | Naruto | main | `Workspace.Kakashi.Kakashi` | R15 | 18/15 | 0 | Shirt+Pants | — | 0 | 0/0/0 | HIGH |
| `kaido` | OnePiece | main | `Workspace.Kaidos.Hybrid Kaido` | R15 | 23/16 | 3 | Shirt+Pants | — | 0 | 2/0/0 | HIGH |
| `bakugo` | MHA | main | `Workspace.Model.Bakugo` | R6 | 12/0 | 5 | Shirt+Pants | — | 0 | 5/0/0 | HIGH |
| `beru` | SoloLeveling | main | `Workspace.Beru` | **no Humanoid** (AnimationController creature: wings, eyes, limbs) | — | — | — | — | **1**: Script (plays idle animation) | — | HIGH |

**Already present from the Last CP (v01):** Tanjiro Kamado, Rengoku, Yoriichi, Muzan, Akaza (the
real DS rigs used in v01, already sanitized: `docs/IMPORT_AUDIT.md` §1).

## 3. Roster coverage against the v02 Master Prompt

| World | Required | Imported model found |
|---|---|---|
| Demon Slayer | Tanjiro, Rengoku, Yoriichi, Muzan, Akaza (boss) + **secret Muzan alternate** | all 5 (Last CP) + `StarterCharacter` at z=44 (probable secret) |
| MHA | Deku, Bakugo, Todoroki, All Might, Shigaraki (boss) | Deku, Bakugo, **Todoroki ×2 (duplicate)**, All Might. **Shigaraki: NOT FOUND among the new imports** (only the v01 stand-in) |
| Dragon Ball | Goku, Vegeta, Gohan, Broly, Frieza (boss) | all (Vegeta = unnamed model, medium confidence) |
| One Piece | Luffy, Zoro, Nami, Kaido, Doflamingo (boss) | all |
| Naruto | Naruto, Sasuke, Kakashi, Itachi, Madara (boss) | all |
| Bleach | Ichigo, Aizen (Muken), Kenpachi, Yachiru, Yhwach (boss) | all (Aizen named "tybw"; confirm the Muken version) |
| JJK | Yuji, Gojo, Toji, Mahoraga, Maki, Sukuna (boss) | all; Mahoraga identity is low-medium (see §4) |
| Solo Leveling | Igris, Beru, Cha Hae-In A, Cha Hae-In B, Sung Jin-Woo (boss) | all |
| Extras | Guts, Gojo (Shinjuku/Sukuna fight), Sukuna (Megumi body) | Guts, Gojo(Sukuna Fight); Megumi-Sukuna low-medium |

## 4. Questions for the Owner (cannot be resolved offline)

1. **Shigaraki** has no new import. Is the v01 stand-in to be replaced by a model you will import, or did I miss it under another name?
2. **Todoroki**: keep `Shoto Todoroki` (R15) or `Shoto` (R6)?
3. **JJK wheel models:** is `Workspace.Character` (R15, has a "Mahoraga Wheel" accessory) Mahoraga, and `Workspace.StarterCharacter` at (53, 92) Megumi-body Sukuna, or the reverse?
4. **Cha Hae-In A vs B:** there are two `Saber_Cha Hae In_Verified` models (11 parts/2 meshes vs 12 parts/5 meshes). Which is A?
5. Is the unnamed model in the Dragon Ball row Vegeta?
6. Is `aizen (tybw)` the Muken version you approved?
7. Is `StarterCharacter` at z=44 the secret Muzan alternate (it matches your N06 screenshot)?

## 5. Sanitization plan (not executed yet; runs on the v02 WORKING copy, never on SAFE_TEST)

* **Remove:**
  * 2 × `Animate` LocalScript + BindableFunction `PlayEmote` (Yuji, Gojo(Sukuna Fight)). These are
    Roblox's default emote Animate; SAE drives animation from the server/rig instead.
  * Beru `Script` (idle) and Igris 2 × `Script` (hair/cape animation loops). Their animations are
    preserved as data and replayed by SAE's own controller.
  * Every Configuration object (36 across imports) after reviewing its values.
  * Unexpected attributes/tags: Yhwach has 106 attributes and 4 tags; Igris 6 attributes and 1 tag;
    Luffy, Sukuna and Beru small counts. Review, then strip.
* **Keep:** MeshParts, SurfaceAppearance (Igris ×9, Deku ×3), Shirt/Pants, BodyColors, CharacterMesh,
  Accessories (+ attachments/welds), Motor6D/Bones, Decals (faces).
* **Face swaps** (FakeHead / external head meshes): Yhwach, Kenpachi, Yachiru, Zoro, Maki, Muzan-secret,
  Aizen (`hhead`), Itachi, Cha Hae-In (variant with `Head` part), Igris (Head transparency 1 +
  `HeadMainIGAW` mesh). Keep the real internal Head for the Humanoid, make it transparent where
  the fake head replaces it, and check welds/orientation **in Studio**.
* **Rig types:** 31 R6, 7 R15 (38 humanoid models) + 1 AnimationController creature (Beru). SAE's farm wander, boss and preview code
  assume a Humanoid; Beru needs a creature path (AnimationController + scripted movement), and R15
  rigs need R15 animation ids.
* No overhead BillboardGui junk was found on the imports themselves. The name labels seen in the
  screenshots are Studio's selection labels.
