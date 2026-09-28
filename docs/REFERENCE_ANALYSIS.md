# Reference Analysis

Five screenshots were supplied as the quality bar. They were studied before any
UI was built. None of their branding, names, logos or artwork is copied; only
the *visual language* (construction techniques, density, proportions, color
behaviour) is extracted.

| # | Reference | Role in this analysis |
|---|-----------|-----------------------|
| R1 | In‑game world screenshot with left nav (Shop / Index / Slow Mode), bottom‑left Speed + Cash HUD, right icon rail (egg / paw / potion), bottom‑right timers | **Primary HUD / nav quality bar** |
| R2 | "Uova in crescita" (growing eggs) panel with *Grow All* + *OPEN* row | Panel construction reference (warm theme) |
| R3 | Close‑up of a Speed (shoe) + Cash HUD: `1.7M` / `$5.6T` | **Negative reference** – the speed icon style the user rejected |
| R4 | "UPGRADE PETS" panel: rows with portrait, rarity‑coloured name, `Lv.10 • $171/s`, green UPGRADE / dark MAX LEVEL buttons | Upgrade row structure reference |
| R5 | "NEGOZIO" shop with a featured ANIME EGG banner, drop‑chance portrait strip, 4 price buttons | **Primary shop / featured‑offer quality bar** |

---

## R1 — World HUD (primary bar)

**Nav buttons (Shop, Index)**
- Wide, chunky rectangles with *small* corner radius (~6–8 px), not pills.
- 3–4 px **near‑black outline** around every button; inner face is a saturated
  vertical gradient (Shop = lime green, Index = sky blue).
- A lighter **top bevel** band and darker bottom lip give a "plastic tile" depth.
- Icon sits **left**, drawn with its own thick black outline, white fill
  (cart, book). The icon is ~60 % of button height – readable at a glance.
- Label: heavy rounded display font, **white fill + thick black stroke**.
- A red circular **"!" notification badge** overlaps the top‑right corner,
  breaking the silhouette – this makes the button feel alive.
- The toggle ("Slow Mode") uses a dark track with a green knob; label sits
  outside the control, again white + black stroke.

**Right icon rail**
- Square 80 px tiles (red egg, orange paw, green potion) — one colour per
  function. Icons are **big** (≈75 % of tile), glossy, with their own outline.
- A green circular **count badge ("1")** overlaps the corner of the egg tile.

**Speed / Cash HUD (bottom‑left)**
- No container panel: the **icon + number float** directly on the world.
- Numbers are enormous (≈48–56 px) italic‑leaning display font: Speed in
  white/yellow, Cash in **bright green with dark outline**.
- A small yellow **"+" square button** overlaps the icon – purchase affordance.
- Icon art is chunky and slightly 3D (money stack with shading).

**Timers (bottom‑right)**
- Icon (potion / moon) + "in 8m 14s" in large white italic stroked text on a
  soft dark gradient fade — info is readable over any background.

**Takeaways:** outline everything; one hue per function; big icons that break
out of their containers; badges overlapping corners; numbers as hero elements.

---

## R2 — Growing eggs panel

- Panel is a **warm orange/brown** body with a **repeating square‑tile
  pattern** embossed into it (subtle, same hue family).
- Gold/tan **outer rim** with small riveted corner "bolts" (little rounded
  squares at each corner) → reads as a physical object, not a web card.
- Header bar: egg icon + title in white with dark stroke; to the right a
  **yellow CTA pill** ("Grow All") with a hand icon and premium price.
- List row: darker recessed slot, square thumbnail tile on the left,
  a large **green OPEN button** with lighter bevel and inner square pattern.
- Weakness to improve on: very flat body, a single row floats in a lot of empty
  pattern, the thumbnail is tiny and hard to read, no state information
  (hatching / ready) is visible.

## R3 — Speed + Cash close‑up (negative for the speed icon)

- Blue sneaker clip‑art at a small size with a yellow "+" badge.
- Why it fails: generic shoe silhouette, flat blue with little shading, reads as
  "footwear" rather than "speed"; it is visually weaker than the cash text.
- What still works: **stacked icon + value rows**, yellow "+" badge,
  black‑stroked heavy numerals, cash in bright green.
- Direction for this lab: an **original speed emblem** — a dynamic running
  figure / motion streak with lightning energy in a blue‑cyan palette, with
  thick outline and gloss so it has the same visual weight as the cash stack.

## R4 — Upgrade Pets panel

- Same warm orange rim + patterned body as R2 (consistent family = good).
- Each row: **dark recessed card** (rounded 8 px) holding:
  square portrait tile → name coloured by rarity (blue, green, grey) with dark
  stroke → sub‑line `Lv.10 • $171/s` in light text → right‑aligned button.
- Button states: **green "UPGRADE $139"** (two‑line: verb + price) vs
  **dark slate "MAX LEVEL"** (disabled look, still outlined).
- Footer strip: "4 active pets • Upgrade anywhere" – contextual info in a
  darker band.
- Weakness to improve on: no level progress visualisation, no "current → next"
  preview, rows are dense text with small portraits.

## R5 — Shop featured offer (primary bar)

- Dark near‑black **carbon/hex pattern** background with a **red header band**
  ("NEGOZIO" in huge white stroked type with basket icon) and a red square
  **X close button** in the corner.
- Starter‑pack strip: a red gradient banner with "SPECIAL OFFER" sub‑line and a
  right‑aligned tag line — a promotional band above the main card.
- Featured card: **neon cyan outline**, starry purple night background, an
  enormous gradient **logo title** (purple→white→cyan) with outline.
- "NEW!" red tag top‑left, "DETAILS" dark pill top‑right.
- **Drop‑chance strip:** 5 portrait tiles, each outlined in a rarity colour,
  percent in bold white at the bottom corner; the rarest one is **larger**, has
  a gold frame, a "RARE DROP" label and yellow **1 %** — hierarchy by size.
- Price row: 4 equal buttons, best‑value one in **orange/red**, rest green;
  each has a currency glyph + big number and a small caption ("10 Eggs").

---

## Extracted visual language (applied to this lab)

1. **Ink outline everywhere.** A single deep "ink" colour (dark purple‑navy)
   strokes buttons, cards, icons and text → cohesive, cartoon, readable.
2. **Chunky 3‑layer buttons:** drop‑shadow lip (darker, offset down) + gradient
   face (light top → saturated bottom) + glossy top highlight band. Pressed =
   face moves down onto the lip.
3. **One hue per function:** Shop red/pink, Index sky blue, Eggs sunny orange,
   Characters violet, Upgrade lime green, Speed cyan‑blue, Cash money green.
4. **Icons break the frame.** Nav icons and panel title badges overflow their
   containers; badges (!, counts, NEW) overlap corners.
5. **Heavy display type** (Luckiest Guy / Fredoka One) in white with thick
   stroke and a subtle vertical gradient; numbers are hero‑sized.
6. **Textured surfaces:** panels carry a low‑contrast repeating pattern and a
   bright rim with corner rivets; nothing is a flat rectangle.
7. **Rarity as colour + size hierarchy:** rarer items get warmer/gold frames,
   bigger tiles, and glow/rays.
8. **State through colour + shape, not text only:** green = go/ready,
   slate = maxed/disabled, red = danger/unsafe, gold = premium/best.
9. **Promotional energy:** rays, sparkles, NEW / BEST VALUE ribbons, starry
   gradients for featured content.

## What must be *better* than the references

- Richer card layouts with more information hierarchy (progress bars, current →
  next values, level pips, state ribbons).
- Consistent family across all menus (R2/R4 and R5 feel like different games).
- An original speed icon with real energy (fixing R3).
- Responsive layout via anchors + UIScale + constraints instead of a single
  resolution.
