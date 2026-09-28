# World Animation / VFX Audit — v02

**Rule:** runtime VFX and animation belong to Roblox (ParticleEmitters, Beams, PointLights, Texture scrolling,
TweenService, client-side motion). Blender provides only the geometry and named `VFX_*` anchor empties. Those are
exported in each world's `manifest.json` and become Attachments under `<World>.V02_VFX`.

**Status:** nothing in this file is **ANIMATION/VFX VERIFIED**. That requires Studio.

| # | World | Anchors (Blender) | Planned runtime effects | Status |
|---|---|---|---|---|
| 1 | Demon Slayer (Akaza) | none. Existing hooks: `AnimatedRiverFlow` textures, `FlowingWaterfall` beams, compass inlay, lantern lights | River scroll + foam, compass pulse, mist, lantern flicker, petals/energy. Everything goes in a new `V02_VFX` folder and the Akaza fingerprint must pass before and after (`AKAZA_PRESERVATION_AUDIT_v02.md` §5) | PLANNED |
| 2 | MHA (Shigaraki) | `VFX_ThroneAura`, `VFX_BossStage`, `VFX_EggNest1–5`, `VFX_Lantern_*` ×6, `VFX_BarNeonFlicker` (14 total) | Decay purple aura + dust at the throne; purple swirl + rising motes on egg nests; crack-glow pulse (Neon `Color` tween on `CrackGlow`, `WallCracks`, `PillarCracks`); lantern flicker; bar neon flicker + smoke haze; banner/cloak sway (small client CFrame oscillation) | ANCHORS EXPORTED · runtime code PENDING |
| 3 | Dragon Ball (Frieza) | `VFX_BossStage`, `VFX_FriezaArch`, `VFX_EggNest1–5`, `VFX_Lantern_*` ×8, `VFX_SeaShimmer±`, `VFX_Waterfall1–6`, `VFX_DragonBalls` (24 total) | Sea texture scroll + sparkles; waterfall beams + splash mist; arch glow pulse + swirling portal; Frieza purple energy aura; ki-aura rings + rising sparks on egg pedestals; Dragon Ball glow shimmer; gentle Ajisa canopy sway; lantern lights | ANCHORS EXPORTED · runtime code PENDING |
| 4 | One Piece (Doflamingo) | `VFX_BossStage`, `VFX_FeatherSway`, `VFX_Birdcage`, `VFX_EggNest1–5`, `VFX_Lamp_*` ×10, `VFX_CrowdCheer±` (20 total) | Crowd bob/cheer (client tween) + confetti at the boss fight; birdcage string shimmer/tighten pulse; feather-fan sway; pink string aura on Doflamingo; golden sparkle + glint on egg pedestals; banner/pennant flutter; lamp lights | ANCHORS EXPORTED · runtime code PENDING |
| 5 | Naruto (Madara) | `VFX_BossStage`, `VFX_UchihaCrest`, `VFX_HokageDust`, `VFX_PaperLanterns`, `VFX_EggNest1–5`, `VFX_Lantern_*` ×8 (17 total) | Falling leaves along the street + off the Hokage Rock; paper lantern sway + soft red glow; banner flutter; Uchiha crest pulse; dark chakra / Susanoo-blue aura on Madara; orange chakra swirl on egg pedestals; lantern lights | ANCHORS EXPORTED · runtime code PENDING |
| 6 | Bleach (Yhwach) | `VFX_BossStage`, `VFX_ThroneAura`, `VFX_Brazier_*` ×18, `VFX_EggNest1–5` (25 total) | Brazier fire + embers + flickering warm lights; dark aura + rising blue reishi motes at the throne; black-shadow / blue reishi aura on Yhwach; blue reishi motes + Quincy-cross pulse on egg pedestals; slow banner sway | ANCHORS EXPORTED · runtime code PENDING |
| 7 | JJK (Sukuna) | `VFX_BossStage`, `VFX_Shrine`, `VFX_ToriiGlow`, `VFX_NeonFlicker±`, `VFX_EggNest1–6`, `VFX_Lamp_*` ×8 (19 total) | Neon sign flicker/buzz; crimson cursed-energy aura on Sukuna; Malevolent Shrine red haze + slash effects during the boss fight; torii rim-light pulse; cursed-energy flames + black sparks on the 6 egg pedestals; cursed-crack pulse; street lights | ANCHORS EXPORTED · runtime code PENDING |
| 8 | Solo Leveling (Sung Jin-Woo) | `VFX_BossStage`, `VFX_Gate`, `VFX_CorridorFog`, `VFX_ShadowArmy±`, `VFX_BlueFire_*` ×20, `VFX_EggNest1–5` (30 total) | Low blue floor fog; blue fire + sparks + cold lights; shadow-army eye pulse + smoke at their feet (statues kneel when the boss wakes); violet/black Monarch aura + "ARISE" shadow burst; gate swirl + portal shimmer; shadow smoke + blue/violet motes on egg pedestals | ANCHORS EXPORTED · runtime code PENDING |

## Composition correction pass: added anchors

| World | New anchors | Planned runtime effect |
|---|---|---|
| MHA | `VFX_HighwayTraffic`, `VFX_CitySmoke` (16 total) | Distant traffic light streaks along the elevated highway; purple smoke drifting over the ruined end blocks |
| Dragon Ball | `VFX_WaterfallsFar` (25 total) | Distant waterfall beams + mist on the restored horizon mesas |
| One Piece | `VFX_CrowdCheerFar` (21 total) | Far-stand crowd bob/cheer + confetti during the boss fight |
| Bleach | `VFX_PalaceFacade` (26 total) | Cold blue reishi wisps down the façade + lancet glow pulse |
| Naruto / JJK / Solo Leveling | anchors unchanged. Naruto `VFX_HokageDust` and `VFX_UchihaCrest` moved with the cliff/stage; the Solo Leveling end-wall guards share `VFX_ShadowArmy±` behaviour | — |

**Status (directive §18):**
* The geometry/composition pass is complete, and every anchor is exported in the manifests.
* The world-specific **runtime motion/VFX layer is NOT implemented yet**: no Roblox code exists for it. **No world
  is "visually complete" until it is.**
* Akaza's additive VFX (river motion, compass pulse, mist, blue energy) must stay inside `V02_VFX` and be guarded by
  the fingerprint check.
