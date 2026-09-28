# Steal An Anime Egg — Guidebook v2 (Full Production)

**Status:** describes the Owner Review build v01 (`docs/OWNER_REVIEW_BUILD.md`).
**Supersedes:** the pre-takeover design (Last CP). **Removed from the game:** Rebirth, Boxing Bag,
Muscle/Strength, the 6-zone route. Numbers marked *provisional* are development balance, not an
approved economy (`docs/generated/BALANCE_TABLES.md`). Not yet play-tested in Roblox Studio.

---

## 1. The game in one paragraph

Up to **7 players** each own a farm inside one big fenced **Farm Safe Zone**. Every round (300 s)
the **fog gate** opens after 7 s, and players run a linear route through **9 anime worlds**. They
grab one character egg, dodge that world's **boss** and other players' bats, and carry the egg home.
The egg is secured **automatically** the moment you step inside the safe zone. It hatches in
60 s; **OPEN** it to reveal the real character, which is added to your Index and earns Cash on your
farm. Cash buys farm slots, character upgrades, treadmill levels and trails. Speed comes from running
on your treadmill, and trails multiply it.

## 2. Map & route

```
[ Farm Safe Zone: 7 farms + Makima Trail Shop + Rem Sell stand ]
                  │  fog gate (closed 7 s at round start)
World 1 ─ World 2 ─ … ─ World 9      (one straight line, each world wider = Akaza ×1.5 footprint)
```

* Every world has the same footprint: 150 studs wall-to-wall and 230 long, plus a 30-stud entry
  portal carrying its title. It holds 5 egg pedestals, and the boss waits at the far end.
* Lighting is **local per world**: entering a world tweens your own lighting only (e.g. Akaza's
  night).

| # | World | Boss | Characters (5 each, boss included) | Local lighting |
|---|---|---|---|---|
| 1 | Demon Slayer (existing Akaza world, widened ×1.5) | Akaza | Tanjiro, Rengoku, Yoriichi, Muzan, Akaza | AkazaNight |
| 2 | My Hero Academia | Shigaraki *(seated)* | Deku, Bakugo, Todoroki, All Might, Shigaraki | VillainViolet |
| 3 | Dragon Ball | Frieza | Goku, Vegeta, Gohan, Broly, Frieza | NamekDay |
| 4 | One Piece | Doflamingo | Luffy, Zoro, Nami, Kaido, Doflamingo | DressrosaSun |
| 5 | Naruto | Madara | Naruto, Sasuke, Kakashi, Itachi, Madara | KonohaDusk |
| 6 | Berserk | Griffith / Femto | Guts, Casca, Skull Knight, Zodd, Griffith | CrimsonEclipse |
| 7 | Bleach | Yhwach – The Almighty *(seated)* | Ichigo, Aizen (Muken; galaxy egg), Kenpachi, Yamamoto, Yhwach | HopelessPalace |
| 8 | Jujutsu Kaisen | Sukuna | Yuji, Gojo, Toji, Mahoraga, Sukuna | CursedShibuya |
| 9 | Solo Leveling | Sung Jin-Woo *(seated)* | Igris, Beru, Cha Hae-In, Thomas Andre, Sung Jin-Woo | ShadowMonarch |

## 3. Eggs

* **45 character eggs**, one per character. Each egg is specific to its character, and 9 of them
  are boss eggs.
* The Demon Slayer eggs are the **approved central set** (unchanged). Giyu's egg is preserved in the
  archive, and the Tanjiro egg is provisional.
* **Carry limit 1.** Hold **E** to pick up (0.35 s). The carry banner reads **"Reach the Farm Safe Zone!"**
* **DROP** is allowed while unsafe. A dropped egg stays for **30 s** (*provisional*) and then returns
  to its pedestal.
* **Auto-secure:** crossing into the Farm Safe Zone secures the egg instantly. It is server-detected;
  there is no button or remote.
* **Hatch:** 60 s, counted from a server `hatchAt` timestamp, so it survives rejoin. Eggs **take no
  character slots**.
* **OPEN** the egg (hatch widget or Eggs menu) to reveal the **real 3D character model**. The Index
  discovery happens **on open**.

## 4. Characters & farm

* Every hatched character is a **unit with its own UID**, and duplicates are allowed.
* **5 slots initially**. Farm upgrades raise this to 10 (*provisional* costs). Only equipped units
  earn income, and there is **no offline income**.
* **Equip Best** ranks purely by actual **$/sec**.
* Equipped characters **wander inside your own plot**.
* **Character upgrades:** levels 1–10, priced and applied **by the server** (Upgrade menu).
* **Sell** at Rem's stand: multi-select, sort by Value / $/sec / World / Name. The final value is
  computed by the server (current $/sec × 45, *provisional*).

## 5. Speed, treadmill, trails

* Speed comes **only from active use** of your farm's **treadmill**: you must be running on the
  belt, grounded and moving. Standing still earns nothing.
* The treadmill has **10 levels**, and each one looks visibly different (rails, fins, energy core,
  pistons, spinning rings, gold wings and aura). Upgrade it at the **physical sign** beside it.
  The farm itself upgrades at the **farm sign**.
* **Trails** (Makima's Trail Shop): x1.5, 2, 2.5, 3, 3.5, 4, 4.5, 5, 7, 10, 14, 20. You can equip
  **one at a time** and they **never stack**. Visually each one is a flat ground ribbon from the
  feet that widens with age, following the reference video. Tier families add wisps, streaks,
  embers, lightning arcs, stars, shadow flames and rings, and the top tiers cycle their colours.
* WalkSpeed = soft-capped conversion of (trained Speed + base) × trail multiplier, from 16 up to a
  cap of 110 (*provisional*).

## 6. Bosses

* One boss per world (never per-player copies).
* A boss reacts about **1 s after** any egg of its world is picked up, then chases **the carrier
  closest to the Farm Safe Zone**, re-picking its target after every resolution.
* A catch **inside its world** returns the egg to its pedestal and applies a **moderate knockback**.
  A catch **after you left the world** (before the safe zone) makes you drop the egg.
* Bosses never enter the safe zone.
* **Shigaraki, Yhwach and Sung Jin-Woo** start **seated** on thrones and rise when the chase begins.

## 7. PvP

* Everyone gets a **Bat**. A hit on a carrier knocks the egg loose, and it becomes a dropped egg
  (30 s).
* Hits are resolved **entirely by the server** (range, cone, cooldown).

## 8. Rounds

* **300 s** rounds: a **7 s fog gate** (worlds closed; a countdown board shows over the gate), then
  open play.
* At round end, players outside the safe zone are returned to the farm, and all eggs and bosses
  reset.
* The round timer is shown at the top of the HUD.

## 9. Menus (UI Lab design system)

| Menu | How to open | What it does |
|---|---|---|
| Shop | nav, or **+** on Speed/Cash | Robux packs/boosts/passes. Items with no id show **COMING SOON** |
| Index | nav | 9 world tabs, 5 cards each. Discovered = real 3D model; locked = black silhouette of the real model |
| Eggs | nav (badge = ready eggs) | secured eggs with live timers, then **OPEN** |
| Characters | nav | slots, farm income, Equip/Unequip, **Equip Best** |
| Upgrade | nav | farm slots, treadmill, per-character upgrades (server-priced) |
| Trail Shop | Makima kiosk (prompt) | buy / equip / unequip trails |
| Sell | Rem kiosk (prompt) | multi-select, sort, sell |
| Hatch reveal | on OPEN | real model, NEW DISCOVERY / BOSS tags |

The HUD shows Speed, Cash with **+$/s**, the round timer, the carry banner, the hatch widget and
toasts.

## 10. Monetization & data

* `MarketplaceConfig`: cash packs, speed pack, 2× boosts, trails, VIP and a Starter Pack. **All ids
  are nil** until the Owner creates them.
* Purchases are granted in `ProcessReceipt`, with receipt ids persisted to prevent duplicates.
* **Saving:** DataStore profiles with **session locking**, autosave every 90 s and save on leave or
  shutdown.

## 11. Technical architecture (for developers)

| Layer | Location | Notes |
|---|---|---|
| Shared config + pure logic | `ReplicatedStorage.SAE_Shared` (`game/src/shared`) | Worlds, Balance, Economy, Profile, Layout, BossLogic, Trails, TrailFx, Net, MarketplaceConfig, Animations |
| Server | `ServerScriptService.SAE_Server` (`game/src/server`) | one entry script: Init Remotes/Data/Farm/Egg, then Start Data → Farm → Egg → Boss → Character → Hatch → FarmCharacter → Treadmill → Movement → Trail → PvP → Sign → Market → Dev → Round (last) |
| Client | `StarterPlayerScripts.SAE_Client` (`game/src/client`) | UIController (UI Lab), HudApp, MenusApp, ViewportService, WorldClient, FxClient, DevClient |
| UI | `StarterGui.SAE_UI` (`game/ui/SAE_UI.rbxmx`) | generated by `node tools/build-prod.js` |
| World | `Workspace.SAE_World` | baked by `lune run game/assembler/build.luau` |
| Assets | `ServerStorage.SAE_Assets`, `ReplicatedStorage.SAE_Preview` | farm rigs; preview rigs/eggs for ViewportFrames |
| Archive | `ServerStorage.SAE_Archive` | legacy content, preserved |

**Server-authoritative rules:** clients send **intent only** (ids/uids). Every cost, payout, level,
ownership check and safe-zone test runs on the server. A per-player mutation lock and rate limits
protect the remotes. Countdowns come from absolute server timestamps; the server never sends
per-second tick remotes. The forbidden names `RequestSecure`, `SecureEgg`, `GiveCash`,
`SetSpeed` and `SetCash` do not exist, and the tests check for that.

**Rebuild everything:**
```
node tools/build-prod.js                 # UI  -> game/ui/SAE_UI.rbxmx
lune run game/assembler/build.luau       # place -> checkpoints/…OwnerReview_v01.rbxlx
lune run game/tests/unit.luau            # 289 logic tests
lune run game/tests/place.luau           # 558 place checks
```
