# Video Reference Audit — v02

Status: **INTAKE COMPLETE (cloud)**. All 10 ZIP sets were verified, extracted and reviewed. Findings
below are reference observations, not implementation claims.

## 1. Package verification

| Check | Result |
|---|---|
| ZIP sets present | 10 / 10 (`Claude_Videos_Set_01_of_10` … `Set_10_of_10`), each extracted without error |
| Files vs `READ_ME_FIRST.txt` manifest | **48 / 48 files match size + SHA-256** (44 video parts + 4 manifest/instruction files) |
| Original videos reconstructed | **6** (per `Video_Manifest.md`) |
| Part continuity | every sequence `Part_01…Part_N` complete; **no missing, no duplicate parts** |
| Duration check | every part within 0.05 s of the manifest; sums match the originals (≤ 0.052 s difference) |
| Decode check | every part decodes (ffprobe); 1280×720 |
| Audio | present, mean −33 to −36 dB (game/ambient sound; no narration detected) |

**Review method:**
1. Each original was re-joined from its parts in numeric order (ffmpeg concat, stream copy).
2. Each joined video was watched as frame sequences sampled every 2 s, each with a burned-in
   timestamp, covering the whole timeline from 0 s to the end.
3. The contact sheets are kept in `art/reference/v02/video_contact_sheets/` (37 sheets).

A 2 s sample can miss sub-second events such as the exact shake timing. Sub-second detail should be
re-checked frame-by-frame when a specific motion is implemented.

## 2. Per original video

### V1 — `Roblox Studio 2026.09.28 - 14.38.22.06.mp4`

**Parts:** 14, `…_Part_01.mp4` … `…_Part_14.mp4` (Sets 01, 09, 01, 09, 05, 01, 08, 03, 08, 03, 04, 02, 10, 06).
**Reviewed duration:** 271.34 s. **Source:** Owner play-through of **OwnerReview_v01** in Roblox Studio.

**Systems shown (timeline):**
* 0:00–0:22: One Piece coliseum.
* 0:22–0:46: Naruto (Konoha): egg pads, Itachi and Madara eggs.
* 0:48–1:12: Berserk (red eclipse).
* 1:12–1:30: Bleach (dark, white lane lines).
* 1:30–1:48: JJK (Shibuya night).
* 1:50–2:24: Solo Leveling (neon-blue corridor). Sung Jin-Woo egg carried; "RUN" banner.
* 2:24: Shop menu.
* 2:28–2:44: JJK again.
* 2:46: **round reset.** Timer 0:00 sends the player back to the hub.
* 2:48–3:10: hub (white fence, farm/treadmill signs, Trail Shop, Sell Characters).
* 3:12–3:34: Demon Slayer world. A DS egg is picked up (label unreadable at sample size; appears to be Yoriichi), and Akaza reacts.
* 3:36: EGG SECURED then HATCHING widget.
* 3:44: Characters / Eggs menus.
* 3:58–4:30: own farm treadmill (Level 1→2), Speed 2→31.

**Useful observations:**
* The linear route and round reset work.
* Carry → secure → hatch works end to end.
* The treadmill trains.

**Mismatch vs v02 prompt:**
* Worlds are procedural blockouts and look flat or very dark (night-tinted); rejected.
* Player avatars are default grey.
* The hub is a flat green field with a thin white fence.
* The treadmill is a static dark box, and the player has to hold W on it.
* The egg auto-deposits in the Safe Zone (the timer starts on entry).
* The Index uses naked placeholder rigs.
* The Berserk world still exists.

**Required correction (v02):**
* 8 Blender Worlds with environmental motion; no night lighting.
* Farm wall.
* Secure-in-hand plus manual placement.
* Auto-run treadmill with an animated machine.
* Real character imports; remove Berserk.

**Reference-only:** nothing here is a target look. This is the *current state* being rejected.

### V2 — `Roblox Studio 2026.09.28 - 14.43.07.07.mp4`

**Parts:** 14, `…_Part_01` … `…_Part_14` (Sets 04, 06, 04, 02, 05, 06, 03, 05, 07, 04, 03, 10, 10, 06).
**Reviewed duration:** 273.60 s. **Source:** Owner play-through of v01 (continued).

**Systems shown:**
* 0:00–0:04: hatch READY → OPEN → **Yoriichi reveal** (placeholder rig, "NEW DISCOVERY").
* 0:08–0:48: hub walk, Trail Shop / Sell kiosks, treadmill runs (Speed 17→25).
* 0:50–1:36: DS world (blue arena, approved eggs), then MHA (purple). **Bakugo egg** carried, bosses visible.
* 1:40: EGG SECURED at the hub, treadmill Level 2→3.
* 2:48–3:00: **Farm Upgrade sign** (Level 1→2, slots 6→7).
* 3:04–3:20: Characters menu (placeholder previews), Upgrade menu.
* 3:22–3:30: Sell stand + Sell menu.
* 3:32–3:40: Trail Shop + Trails menu.
* 3:42–3:58: DS **Tanjiro egg** (provisional pipeline egg) carried and secured.
* 4:08–4:24: **Index** (DS 3/45, per-world tabs, naked blocky previews, `???` overlap panel).
* 4:26: Shop.

**Mismatch:**
* Hatch reveal is instant with no Egg animation.
* Previews are naked and blocky.
* Index framing is broken: the `???` card overlaps the sidebar (also in N02/N03).
* Tanjiro egg is a pipeline blockout.
* Menus use placeholder art (image atlases not uploaded).

**Correction:**
* Staged hatch animation.
* Real sanitized previews with idle motion.
* Index rebuild with the 41 count, rewards and real silhouettes.
* Upload the atlas.

**Reference-only:** current state.

### V3 — `Desktop 2026.09.28 - 15.04.14.08.mp4`

**Parts:** 2 (Sets 10, 07). **Reviewed:** 29.01 s. **Source:** *Steal an Egg* reference game.

**Shown:**
* A farm pen with a premium **treadmill** (ornate frame, lava/fire belt, character running, `+Speed` floaters).
* The Upgrade sign beside the machine.
* An **outer wall of tan/orange checker blocks** around the base area.

**Useful:**
* The treadmill is a centrepiece prop with an animated belt.
* The wall material/colour language.

**Mismatch:** SAE treadmill and farm fence (see V1).

**Correction:** Blender treadmill with 10 evolving levels plus runtime belt/VFX; tan/orange checker perimeter wall.

**Reference-only:** do not copy their dinosaur/egg theming, UI text, prices or Robux values.

### V4 — `Desktop 2026.09.28 - 15.09.45.10.mp4`

**Parts:** 9 (Sets 09, 08, 01, 06, 07, 09, 07, 05, 02). **Reviewed:** 179.12 s. **Source:** *Steal an Egg* reference.

**Shown:**
* A linear **zone route** (Lake, Snow, Volcano, Abyss Ocean, Prehistoric, Cosmic, Jungle, Titan Temple, Angels…).
  Each zone is framed by high side walls, and the next zone is **always visible** through an open threshold.
* A zone title banner on entry.
* A flat **ground trail ribbon** behind the runner.
* "RUN!!" banner and a **boss chase** (Angel/Titan).
* Egg carried **above the head** with a **Drop** button.
* PvP **bat** swings; the victim's egg drops.
* Safe-zone message: *"Cannot use items in the safe zone!"*
* Boss Mastery panel.
* Zone floors with visible water, lava and cosmic sky.
* **2:38–2:46: the carrier walks into their own pen and PLACES the egg manually** on a nest. The
  egg then shows a countdown (`7m 52s`) and appears in the **Growing Eggs** panel.

**Useful:**
* Confirms **secure-in-hand then manual placement**.
* Growing Eggs UI.
* Visible next zone and a clear central lane.
* Motion in every zone (water, particles).
* Carried-egg presentation.
* Boss-chase feedback.

**Mismatch:**
* SAE auto-deposits at the Safe Zone.
* SAE thresholds are opaque portals.
* SAE worlds are static.

**Correction:** §41–45 lifecycle, open thresholds, per-world motion.

**Reference-only:**
* Their zone themes and block art style.
* Their minutes-long hatch time (SAE uses 60 s).
* Boss Mastery, which is not requested.

### V5 — `Desktop 2026.09.28 - 15.14.40.11.mp4`

**Parts:** 1 (Set 08). **Reviewed:** 10.21 s. **Source:** *Steal an Egg* reference.

**Shown:** an **Upgrade Pen** sign. Upgrading visibly transforms the pen fence (orange → blue), with a "Successfully upgraded your base!" toast.

**Useful:** upgrades must *physically* change the object (applies to the treadmill and farm upgrades).

**Reference-only:** the pen-fence styling (SAE farms stay open; only the outer wall is substantial).

### V6 — `Desktop 2026.09.28 - 15.17.39.12.mp4`

**Parts:** 3 (Sets 08, 02, 01). **Reviewed:** 40.39 s. **Source:** *Steal an Egg* reference.

**Shown:**
* **Growing Eggs** panel (list with timers + claim).
* An egg on a nest with a **"Ready!"** label.
* The egg shakes/opens and a **triceratops pet emerges** and walks off.
* Income floater.
* **Pet Index**: world tabs, 7/8 progress bar, locked silhouettes, a "Claim All" reward button,
  an "Unlocked 81/104" counter, and a detail card on the right.
* An "…/Day **offline**" earnings banner.

**Useful:**
* The physical hatch/emerge moment.
* The Index layout: large grid, progress, rewards, detail panel.
* Growing Eggs UI.

**Correction:** staged hatch (§46), Index rebuild + discovery rewards (§66–71).

**Reference-only, and must NOT be copied:**
* **offline earnings** (SAE: no offline income);
* the word "Pet" (SAE: Characters);
* their art.

## 3. Cross-video conclusions for v02

1. The route must stay one open lane with the next World visible, and each World must have motion (V4).
2. **Secure keeps the egg in hand; placement is manual at the player's own farm; the timer starts there** (V4 2:38).
3. The hatch is a physical event (shake, open, character emerges) (V6).
4. Index: big cards, world progress, first-discovery reward, detail panel (V6), using SAE counts (41 + extras).
5. The treadmill is a premium centrepiece. The belt animates and the machine evolves per level (V3, N01).
6. The perimeter wall uses tan/orange checker blocks (V3/V4/V5 background).
7. Everything in V1/V2 is the **rejected current state**, not a target.
