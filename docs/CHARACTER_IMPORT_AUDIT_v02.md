# Character Import Audit — v02

**Source:** `checkpoints/StealAnAnimeEgg_v01_SAFE_TEST.rbxlx` (Git LFS, 111,715,271 B, SHA-256
`f260e511e48eeb23e3cd226fb63bab45cfaafbdb505c6c54e032e920f78c3c8a`). **Read-only; not modified.**

**Status:** **STRUCTURALLY VERIFIED** (offline parse). **Not visually verified.** Meshes, textures and
clothing reference Roblox asset ids that only render in Studio.

**Identification method (no Owner input needed):**
* model and accessory names;
* MeshPart names;
* clothing/decal ids;
* rig type and height;
* the Owner's **row layout** in SAFE_TEST: one row per world at z ≈ 58/64/70/77/84/92/102 with the
  boss last, matching roster order;
* Owner screenshots N04–N06.

**Result: every model is identified.** None needs OWNER IDENTIFICATION REQUIRED.

## 1. What SAFE_TEST changes vs OwnerReview_v01

* **Only Workspace differs:** 11,340 → 43,315 descendants. All other services are structurally
  identical to v01, so the repo code can be merged without losing Owner work.
* The Owner added **40 new top-level Workspace models**, all identified below.
* The Akaza world is unchanged (fingerprint check passes; see `AKAZA_PRESERVATION_AUDIT_v02.md`).
* The 5 Demon Slayer rigs (Tanjiro, Rengoku, Yoriichi, Muzan, Akaza) come from the Last CP and were
  sanitized in v01 (`docs/IMPORT_AUDIT.md`).

## 2. Per-model audit

| Raw model name | Proposed CharacterId | World / class | Rig | Height (studs) | Confidence | Evidence | Face / head issues | Executable content | Sanitation status |
|---|---|---|---|---|---|---|---|---|---|
| `StarterCharacter` | `deku` | MHA main | R6 | 6.4 | HIGH | MeshParts "Vigilante Deku Scarf/Mask/Eyes/Hood and Hair/Cape"; MHA row slot 1 | — | — | NOT YET SANITIZED (plan §4) |
| `Model` | `bakugo` | MHA main | R6 | 5.5 | HIGH | wrapper Model→"Bakugo"; accessories "Katsuki Bakugo grenade belt", "Bakugo Hat" | "ROBLOX HEAD FACE MESH" accessory (face mesh on real Head) | — | NOT YET SANITIZED (plan §4) |
| `Shoto Todoroki` | `todoroki` | MHA main | R15 | 5.6 | HIGH | name "Shoto Todoroki"; R15; MHA row slot 3 | — | — | NOT YET SANITIZED (plan §4) |
| `All Might` | `allmight` | MHA main | R6 | 5.7 | HIGH | name; accessory "Migh"; MHA row slot 4 | — | — | NOT YET SANITIZED (plan §4) |
| `Shoto` | `shigaraki` | MHA BOSS | R6 | 5 | HIGH | 3 accessories named "Shigaraki" (model is mis-named "Shoto"); MHA row boss slot (last) | — | — | NOT YET SANITIZED (plan §4) |
| `Goku` | `goku` | DragonBall main | R6 | 6.4 | HIGH | name; "Base Hair" + "SSJ Hair", "Base Face"/"SSJ Face" decals | second face part (Face, T=1): form switch | — | NOT YET SANITIZED (plan §4) |
| `(empty name)` | `vegeta` | DragonBall main | R6 | 6.4 | MEDIUM-HIGH | unnamed model in the Vegeta slot of the DB row (between Goku and Gohan); hair mesh + DBZ-style outfit | — | — | NOT YET SANITIZED (plan §4) |
| `BeastGohan` | `gohan` | DragonBall main | R6 | 8 | HIGH | name "BeastGohan"; 8.0 studs tall | — | — | NOT YET SANITIZED (plan §4) |
| `Broly` | `broly` | DragonBall main | R6 | 6.6 | HIGH | name; accessory "Broly" | — | — | NOT YET SANITIZED (plan §4) |
| `R6 Frieza` | `frieza` | DragonBall BOSS | **no Humanoid** (18 MeshParts, R6-shaped) | 4.6 | HIGH | name "R6 Frieza"; 18 body MeshParts; DB boss slot | real Head hidden (T=1); body is mesh-built | — | NOT YET SANITIZED (plan §4) |
| `Luffy - Gear 5` | `luffy` | OnePiece main | R15 | 5.8 | HIGH | name "Luffy - Gear 5"; "White Rubber Hair", "Smoke" mesh | — | — | NOT YET SANITIZED (plan §4) |
| `Zoro` | `zoro` | OnePiece main | R6 | 5.3 | HIGH | name; hair mesh | **FakeHead** (T=0, visible) + real Head (T=0): double head risk | — | NOT YET SANITIZED (plan §4) |
| `Nami Onigashima` | `nami` | OnePiece main | R6 | 5.3 | HIGH | name "Nami Onigashima"; "Meshes/nammi" | — | — | NOT YET SANITIZED (plan §4) |
| `Donquixote Doflamingo` | `doflamingo` | OnePiece BOSS | R15 | 6.6 | HIGH | name; "Cloak", "Glasses", "Hair" meshes | — | — | NOT YET SANITIZED (plan §4) |
| `Kaidos` | `kaido` | OnePiece main | R15 (nested) | 6.4 | HIGH | wrapper "Kaidos"→"Hybrid Kaido"; "Blue Scalie Dragon Tail", "Beast Mask" | — | — | NOT YET SANITIZED (plan §4) |
| `Naruto` | `naruto` | Naruto main | R15 | 6 | HIGH | name; R15 | — | — | NOT YET SANITIZED (plan §4) |
| `Sasuke` | `sasuke` | Naruto main | R6 | 5.2 | HIGH | name; "sasukehair" accessory | "Baki_head" accessory (head mesh overlay) | — | NOT YET SANITIZED (plan §4) |
| `Kakashi` | `kakashi` | Naruto main | R15 (nested) | 6.4 | HIGH | wrapper "Kakashi"→"Kakashi"; decal "KAKASHI" | — | — | NOT YET SANITIZED (plan §4) |
| `Itachi Uchiha for the gfx` | `itachi` | Naruto main | R6 | 5.8 | HIGH | name "Itachi Uchiha for the gfx"; "Meshes/ITACHI" | **two Head parts** (both T=0) | — | NOT YET SANITIZED (plan §4) |
| `Madara` | `madara` | Naruto BOSS | R6 | 5.8 | HIGH | name; "MADARAHAIR+HEADBAND" | hair mesh named like a head part (not a swap) | — | NOT YET SANITIZED (plan §4) |
| `StarterCharacter` | `muzan_secret` | DemonSlayer SECRET (Muzan egg) | R6 | 8.9 | HIGH | matches Owner screenshot N06; 8.9 studs; flesh segments B1/T1–T4, 4× "Raptor_Claw" meshes (Muzan final form); lone model outside the world rows | **Fakehead** (T=1) + real Head | — | NOT YET SANITIZED (plan §4) |
| `Guts (Berserk Armor)` | `guts` | EXTRA | R6 | 5.3 | HIGH | name "Guts (Berserk Armor)"; "MainHelmet", "Blade", "WeaponHandle" | — | — | NOT YET SANITIZED (plan §4) |
| `Yachiru_FaceSwap_Verified` | `yachiru` | Bleach main | R6 | 4.3 | HIGH | name "Yachiru_FaceSwap_Verified"; 4.3 studs (child-sized) | **FakeHead** (T=1) + real Head: Owner-labelled face swap | — | NOT YET SANITIZED (plan §4) |
| `Kenpachi_FaceSwap_Verified` | `kenpachi` | Bleach main | R6 | 6.4 | HIGH | name "Kenpachi_FaceSwap_Verified" | **FakeHead** (T=1) + real Head: Owner-labelled face swap | — | NOT YET SANITIZED (plan §4) |
| `Ichigo model` | `ichigo` | Bleach main | R6 | 5.1 | HIGH | name "Ichigo model" | — | — | NOT YET SANITIZED (plan §4) |
| `aizen (tybw)` | `aizen` | Bleach main (Muken) | R6 | 5.6 | HIGH | meshes "kyoka suigetsu (tybwaizen)", "AIZEN BW MESHES Jacket" = Thousand-Year Blood War / Muken look | real Head replaced by part "hhead" | — | NOT YET SANITIZED (plan §4) |
| `Yhwach_Gold_Mode` | `yhwach` | Bleach BOSS | R6 | 5.6 | HIGH | name "Yhwach_Gold_Mode"; "sword", "coat", "mustache" | **FakeHead** + "facepart" (both T=1); 106 attributes / 4 tags to review | — | NOT YET SANITIZED (plan §4) |
| `Yuji` | `yuji` | JJK main | R6 | 5.4 | HIGH | name; "Yuji Mere Head", "yuji hoodie" accessories | — | **Animate LocalScript + PlayEmote BindableFunction** | NOT YET SANITIZED (plan §4) |
| `Gojo(Sukuna Fight)` | `gojo_shinjuku` | EXTRA | R6 | 5.4 | HIGH | name "Gojo(Sukuna Fight)"; Owner screenshot N04 | — | **Animate LocalScript + PlayEmote BindableFunction** | NOT YET SANITIZED (plan §4) |
| `Gojo satoru` | `gojo` | JJK main | R6 | 5.3 | HIGH | name "Gojo satoru"; "Crazed Infinity Sorcerer Face" | face accessory | — | NOT YET SANITIZED (plan §4) |
| `Toji Fushiguro` | `toji` | JJK main | R6 | 5.2 | HIGH | name; "Toji Hair", "Toji Fushiguro Face", worm accessory | face accessory | — | NOT YET SANITIZED (plan §4) |
| `Character` | `mahoraga` | JJK main | R15 | 11.6 | HIGH | R15, **11.6 studs tall** (giant); accessory "Mahoraga Wheel"; JJK row | — | — | NOT YET SANITIZED (plan §4) |
| `StarterCharacter` | `sukuna_megumi` | EXTRA | R6 | 5.4 | MEDIUM-HIGH | JJK row; robe/scarf/sleeves/socks/sandals meshes + wheel-style accessory, matching Owner screenshot N05 (Sukuna markings, white robe, wheel above head); normal height 5.4 | — | — | NOT YET SANITIZED (plan §4) |
| `SUKUNA6167` | `sukuna` | JJK BOSS | R6 | 5.7 | HIGH | name "SUKUNA6167"; JJK row | — | — | NOT YET SANITIZED (plan §4) |
| `Toji_Maki` | `maki` | JJK main | R6 | 5.6 | MEDIUM-HIGH | name "Toji_Maki_Verified" (awakened Maki Zenin resembles Toji); JJK row; Owner "Verified" suffix | **FakeHead** (T=1) + real Head | — | NOT YET SANITIZED (plan §4) |
| `Beru` | `beru` | SoloLeveling main | AnimationController | 9.7 | HIGH | name; wings, eyes, little arms; 9.7 studs | **no Humanoid** (AnimationController creature) | **Script** (plays idle animation) | NOT YET SANITIZED (plan §4) |
| `Saber_Cha Hae In_Verified` | `chahaein_a` | SoloLeveling main (Variant A) | R6 | 5.9 | MEDIUM-HIGH | name "Saber_Cha Hae In_Verified"; contains a MeshPart literally named **"A"**; first in pair | — | — | NOT YET SANITIZED (plan §4) |
| `Saber_Cha Hae In_Verified` | `chahaein_b` | SoloLeveling main (Variant B) | R6 | 5.5 | MEDIUM-HIGH | same name; second in pair (no "A" marker); different clothing ids | — | — | NOT YET SANITIZED (plan §4) |
| `Sung Jin-woo` | `sungjinwoo` | SoloLeveling BOSS | R6 | 5.4 | HIGH | name "Sung Jin-woo" | — | — | NOT YET SANITIZED (plan §4) |
| `Igris` | `igris` | SoloLeveling main | R6 | 12.7 | HIGH | name; mesh parts "*MAINIGAW"; 12.7 studs (armoured knight) | real Head hidden (T=1); head = "HeadMainIGAW" mesh | **2 Scripts** (hair/cape animation loops); 9 SurfaceAppearance | NOT YET SANITIZED (plan §4) |

**Rig summary:**
* 32 R6-shaped models, of which **R6 Frieza has no Humanoid**.
* 7 R15, 2 of them nested in wrapper Models (Kaido, Kakashi).
* 1 AnimationController creature (Beru).

## 3. Roster coverage (v02 Master Prompt)

| World | Required | Found | Notes |
|---|---|---|---|
| Demon Slayer | Tanjiro, Rengoku, Yoriichi, Muzan, **Akaza (boss)** + secret | all + `muzan_secret` | DS rigs from the Last CP |
| MHA | Deku, Bakugo, Todoroki, All Might, **Shigaraki** | **all** | Shigaraki is the model mis-named `Shoto` |
| Dragon Ball | Goku, Vegeta, Gohan, Broly, **Frieza** | all | Frieza needs a Humanoid rig for boss logic |
| One Piece | Luffy, Zoro, Nami, Kaido, **Doflamingo** | all | |
| Naruto | Naruto, Sasuke, Kakashi, Itachi, **Madara** | all | |
| Bleach | Ichigo, Aizen (Muken), Kenpachi, Yachiru, **Yhwach** | all | |
| JJK (6) | Yuji, Gojo, Toji, Mahoraga, Maki, **Sukuna** | all | |
| Solo Leveling | Igris, Beru, Cha Hae-In A, Cha Hae-In B, **Sung Jin-Woo** | all | Beru is a creature rig |
| Extras | Guts, Gojo (Shinjuku), Sukuna (Megumi body) | all | |

**Missing character models: none.** Missing art is limited to eggs (see `V02_BASELINE_AUDIT.md`)
and the Makima/Rem vendor models.

## 4. Sanitization plan (runs on the v02 WORKING copy, never on SAFE_TEST)

* **Remove:**
  * Animate LocalScript + PlayEmote BindableFunction (Yuji, Gojo Shinjuku).
  * Beru idle Script and Igris hair/cape Scripts. Their Animation objects are kept as data and
    replayed by SAE's own animation controller.
  * All 36 Configuration objects, after logging their values.
  * Unexplained attributes/tags (Yhwach 106/4, Igris 6/1, small counts on Luffy, Sukuna, Beru).
* **Keep:** MeshParts, SurfaceAppearance, Shirt/Pants, BodyColors, CharacterMesh, Accessories
  (+ attachments/welds), Motor6D/Bones, face Decals.
* **Face/head fixes** (verify in Studio):
  * **Zoro:** visible FakeHead + visible real Head → hide the real Head (keep it for the Humanoid).
  * **Itachi:** two visible Head parts → keep the correct one visible.
  * **Aizen:** `hhead` replaces Head → add or rename a proper Head for the Humanoid and keep `hhead` visual.
  * **Yhwach, Kenpachi, Yachiru, Maki, Muzan-secret:** FakeHead is already hidden (T=1). Check which
    head carries the face mesh and weld/orientation.
  * **Frieza, Igris:** real Head hidden by design (mesh heads).
* **Rig fixes:**
  * **Frieza:** add a Humanoid + R6 Motor6D joints (boss chase needs a Humanoid) without changing
    visual meshes.
  * **Beru:** creature path (AnimationController + scripted movement) for the farm, preview and hatch.
* **Wrappers:** unwrap Kaidos/Kakashi/Model(Bakugo)/Toji_Maki into production rigs named by characterId.
* **Destination:** `ServerStorage.SAE_CharacterImports` with `Incoming` (originals, untouched) →
  `Sanitized` → `Production`, plus `ReplicatedStorage.SAE_Preview.Rigs`.
