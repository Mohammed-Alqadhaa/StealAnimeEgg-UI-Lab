# Visual Review

```
ROBLOX STUDIO VISUAL VERIFICATION: NOT PERFORMED
```
Roblox Studio is not available in the cloud build environment. Nothing in this document
claims Studio rendering. Visual review was done with the **browser preview**
(`preview/index.html`), a purpose-built renderer that interprets the *same* instance tree
that is exported to `.rbxm/.rbxmx` using Roblox layout semantics (UDim2 + AnchorPoint,
UIPadding, UIListLayout, UIGridLayout, UIScale, AutomaticSize, UICorner, UIStroke Border /
Contextual, UIGradient, ImageRect atlases, ImageColor3 multiply). Expect small differences
in Studio: font metrics/line height, stroke anti-aliasing, gradient span on rotated
gradients, and exact `TextScaled` fitting.

## What was verified (automated, in this environment)

| Check | Tool | Result |
|---|---|---|
| Model builds (XML + **binary**) and place builds | Rojo 7.7.0 `rojo build` | ✅ `.rbxmx`, `.rbxm`, `_Demo.rbxlx` |
| Every property has the correct Roblox type | Rojo binary serializer (fails on any type mismatch) | ✅ (it caught and we fixed `BorderSizePixel`, `MaxTextSize`, `MinTextSize` int types) |
| Binary ↔ XML round-trip identical | `rbxm → rojo → rbxmx`, class histogram diff | ✅ 4,397 instances, identical |
| Luau lint | selene (Luau std + Roblox globals, offline) | ✅ 0 errors, 0 warnings, 0 parse errors |
| Luau parses | StyLua (Luau grammar) | ✅ |
| Structure + preview logic against the real `.rbxm` | Lune 0.10.5 `tools/tests/verify_model.luau` | ✅ **91 passed, 0 failed** |
| Layout at 5 viewports | Playwright + Chromium screenshots | ✅ `docs/screenshots/` |

### Headless test run (Lune)
`lune run tools/tests/verify_model.luau` loads `dist/StealAnimeEgg_UI_Lab.rbxm` and checks the
brief's structural rules: 5 menus + nav buttons, no Rebirth/Boxing Bag, locked portraits are
black silhouettes with `???`, 4 egg states per card, DROP only in UNSAFE, 3 upgrade pages,
separate duplicate units, and every ImageLabel keyed. It then **executes the real
`PREVIEW_Controller` source** against the model: lock/unlock index, egg cycle, carry states,
hatch READY, Equip Best (by $/sec → Yoriichi, Rengoku #1, Muzan, Akaza; $368/s), duplicate
unit #3, upgrade tabs + MAX LEVEL, and the 60s timer ticking (1:00 → 0:58). An audit fails the
run if any hierarchy path used by the controller doesn't resolve. Not covered: input events
and `UIController` animations (Lune has no input or render loop), which are linted only.

## Screenshots (`docs/screenshots/`)

| File | Shows |
|---|---|
| `hud_desktop.png` | Nav, Speed/Cash HUD, hatch widget (HATCHING), carry UNSAFE with DROP, preview panel |
| `carry_secured_ready.png` | carry SECURED (no DROP) + hatch widget READY/OPEN |
| `menu_shop.png`, `menu_shop_scrolled.png`, `desktop_1080p_shop.png` | Shop top + scrolled (cash packs, boosts) + 1080p |
| `menu_index.png`, `menu_index_all_unlocked.png`, `phone_index.png` | Index 3/5 with silhouettes, 5/5, phone |
| `menu_eggs.png`, `tablet_eggs.png` | all four egg states at once; 4:3 tablet |
| `menu_characters.png`, `menu_characters_equipbest.png`, `phone_characters.png` | units, duplicates, Equip Best |
| `menu_upgrade_character/treadmill/farm.png` | the three upgrade tabs incl. MAX LEVEL row |
| `nav_states_hover_shop.png`, `nav_states_pressed_eggs.png` | hover (grow + brighten), pressed (face sinks), selected (glow ring) |
| `art_contact_sheet.png` | all 53 original art assets |

## Self-review iterations

**Pass 1: art.** First render of the contact sheet: the portraits' bangs drew an ink
"headband" line across every forehead → bangs now stroke only their spiky lower edge.
Speed runner's back leg read as a stub → re-posed into a proper back-kick. Silhouettes of
all five characters checked at black: each stays identifiable (flame mane, fedora,
ponytail, short spikes, medium spikes).

**Pass 2: HUD.** Nav label had been shortened to "HEROES" to fit → restored to
**CHARACTERS** (brief requirement) by widening the nav and using a tighter size for
long labels. Screenshots were being downscaled → fixed to 1:1 capture.

**Pass 3: menus (first full render).** Found and fixed:
* Shop: drop-chance strip collided with the price buttons (featured banner enlarged and
  re-laid-out); "STARTER PACK" collided with the −70 % burst (burst moved onto the gift);
  VIP's third perk sat under the price button (cards made taller).
* Eggs: "DEMON SLAYER EGG" overflowed (now `TextScaled` + `UITextSizeConstraint`), the
  SKIP button covered the timer (moved next to the progress bar), helper text clipped.
* Characters: equipped check badge covered the level pill (moved onto the portrait).
* Index: locked portraits multiplied by near-black still showed faint detail → true
  black (`ImageColor3 = 0,0,0`) on a lighter violet well for a crisp silhouette.
* Global: menus competed with the world → added `MenuBackdrop` dim layer (nav stays above
  it); weak nav selection → double ring + white glow + spinning sparkle; menu moved up to
  reduce overlap with the carry banner.

**Pass 4: layout conflicts.** Preview panel overlapped the hatch widget → hatch widget
moved to bottom-right. Preview chip grid was 1 px too narrow for 3 columns → widened.
Checked 1280×720, 1920×1080, 1024×768, 844×390, 667×375.

## Honest self-assessment

Strong: consistent ink-outline family across 53 icons and every component; every surface
has depth, pattern and gloss; state changes are colour + shape; icons break frames;
information hierarchy is richer than the references (progress bars, current → next,
level pips, state pills, drop-chance tiles).

Still worth a human pass in Studio:
* Luckiest Guy in Roblox renders slightly narrower than in the browser; a few labels
  (e.g. `CHARACTERS` nav label, long upgrade names) may need ±1–2 TextSize.
* `UIStroke` on rotated frames (tags, badges) is anti-aliased differently in Roblox.
* Idle animations (spin/wobble/bob/pulse) and the menu pop-in have only been exercised
  in code review/lint, not visually in Studio.
* On very small phones (≤ 667×375) the UI hits the 0.45 minimum scale; text stays
  readable in the preview, but confirm touch-target comfort with the Device emulator.
* Character portraits are original chibi fan-style busts made for this lab. Replace them with
  your licensed/official character art in production if required.
