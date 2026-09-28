# World Composition Correction — Pre-Correction Checkpoint (v02)

Created before applying the Owner's "World Production Correction Directive" (Blender composition, background,
Akaza preservation, QA gate). Nothing listed here is deleted. This is the recovery point for the seven Blender worlds.

| Item | Value |
|---|---|
| Branch | `claude/loving-pasteur-oayq18` |
| Checkpoint commit (all seven worlds, pre-correction) | `a39cc9388950f63b6a917a50cb26b7e0e369b172` |
| Recover a world at this state | `git checkout a39cc93 -- art/blender/worlds/<NN_Name>.blend art/exports/worlds/<NN_Name> tools/blender/worlds/<script>.py` |
| Scripts | `tools/blender/sae_bpy.py`, `tools/blender/worlds/w02_mha.py` … `w08_sololeveling.py` |
| Exports | `art/exports/worlds/<NN_Name>/` (FBX modules + `manifest.json`) |
| Renders ("before") | `art/review_renders/v02/<NN_Name>/pre_correction_*.png`: byte-identical copies of the checkpoint `final_*.png`, kept because the correction pass overwrites `final_*.png` |

## `.blend` sources at the checkpoint

| File | SHA-256 |
|---|---|
| `art/blender/worlds/02_MHA.blend` | `41d904307200b97dd0e6ca5e7a3fb9565e9aee7e8a5f784289a32cc25464d689` |
| `art/blender/worlds/03_DragonBall.blend` | `afc99b079f3634e521b5fbeefae7fbec94a37d8b08a7f0e3ab9c2da90839fac1` |
| `art/blender/worlds/04_OnePiece.blend` | `c69d38f2551f3147a384a8eb4873764b00aeaae27edac84c8a6d795688ee0fb2` |
| `art/blender/worlds/05_Naruto.blend` | `e66b77e25ea830aaa7e7222fa8fa0bd50225c3d176c8d4eb209e955321ab9f3d` |
| `art/blender/worlds/06_Bleach.blend` | `27108f6b05fff6f44bdcd26b96d5eff7738d389b0b901561e6ab48de594909f0` |
| `art/blender/worlds/07_JJK.blend` | `7fc0608215e3603f29510f0bf12a4959f939b400907644da25569463aacf8cd0` |
| `art/blender/worlds/08_SoloLeveling.blend` | `b7eb44e952376be276efcdf485af2534a54dcbe86362f24c4b84e1332d4035ee` |

## Why a correction is needed (Owner directive §4)

The pre-correction pass treated the whole legacy v01 world slot (`y ∈ [-30, 228]`) as a hard limit for **all**
geometry. It then removed or displaced reference composition to open the view to the next world:
* the MHA city/bridge behind Shigaraki;
* the One Piece stands behind Doflamingo;
* the Naruto Hokage Rock, moved off to the side.

The directive makes the references the visual authority. The legacy slot remains a gameplay constraint for
PLAYABLE/COLLISION geometry only.
