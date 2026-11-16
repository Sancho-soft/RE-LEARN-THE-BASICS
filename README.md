# Re-Learn The Basics

A cozy elementary math educational game built with **Godot 4**. Players solve bite-sized math challenges with Pip to earn coins, per-level stars, **Rainbow Stars** on Level 8, and collectible stickers.

---

## Game Catalog

### Activities (8 Activities × 8 Levels = 64 Stages)

#### Page 1 — Core Math (`1–4`)
1. **The Little Shop** (`little_shop`) — Add `₱` prices & give friendly customers their change.
   - `Lvl 1`: Sums to 10
   - `Lvl 2`: Sums to 20
   - `Lvl 3`: Making Change
   - `Lvl 4`: Big Shop (to 100)
   - `Lvl 5`: Super Shop (to 250)
   - `Lvl 6`: Grand Market (to 500)
   - `Lvl 7`: Mega Mall (to 750)
   - `Lvl 8`: Master Cashier (to 999)
2. **Puzzle Doors** (`puzzle_doors`) — Multiply gems & solve order-of-operations locks.
   - `Lvl 1`: Equal Groups (`×2` to `×5`)
   - `Lvl 2`: Times Tables (to `9×9`)
   - `Lvl 3`: Missing Key & Two-Step
   - `Lvl 4`: Order of Operations
   - `Lvl 5`: Double-Digit Multiply
   - `Lvl 6`: Two-Product Locks
   - `Lvl 7`: Big Rune Multipliers
   - `Lvl 8`: Ancient Master Locks
3. **Little Builder** (`little_builder`) — Count blocks, area rows, fences & workshop sales (`%`).
   - `Lvl 1`: Stacking Bricks
   - `Lvl 2`: Wall Rows (Area)
   - `Lvl 3`: Garden Fence (Perimeter)
   - `Lvl 4`: Workshop Sales (`%`)
   - `Lvl 5`: Big Wall Area
   - `Lvl 6`: Two-Room Floorplan
   - `Lvl 7`: Grand Fence Perimeter
   - `Lvl 8`: Master Builder (`%`)
4. **Fair Sharing** (`fair_sharing`) — Divide snacks, explore fractions & match ratios.
   - `Lvl 1`: Equal Sharing (`÷2` to `÷5`)
   - `Lvl 2`: Larger Division
   - `Lvl 3`: Unit Fractions
   - `Lvl 4`: Fractions & Ratios
   - `Lvl 5`: Big Pack Division
   - `Lvl 6`: Big Fractions
   - `Lvl 7`: Banquet Ratios
   - `Lvl 8`: Master Fairness

#### Page 2 — Explorer Math (`5–8`)
5. **Number Patterns** (`number_patterns`) — Spot skip-counting jumps, doubles & mystery sequences.
   - `Lvl 1`: Skip-Count (`2s` & `5s`)
   - `Lvl 2`: Skip-Count (`3s`, `4s` & `10s`)
   - `Lvl 3`: Missing Middle Number
   - `Lvl 4`: Countdown Steps
   - `Lvl 5`: Doubling Chains
   - `Lvl 6`: Growing Jumps
   - `Lvl 7`: Two-Step Rules
   - `Lvl 8`: Master Sequences
6. **Clock & Time** (`clock_time`) — Convert hours, minutes & calculate cozy journey times.
   - `Lvl 1`: Hours to Minutes
   - `Lvl 2`: Hours + Extra Minutes
   - `Lvl 3`: Adding Minutes
   - `Lvl 4`: Days & Weeks
   - `Lvl 5`: Long Journeys
   - `Lvl 6`: Minutes to Hours
   - `Lvl 7`: Distance & Speed
   - `Lvl 8`: Master Timekeeper
7. **Rocket Shapes** (`rocket_shapes`) — Explore triangles, cubes, angles & space geometry.
   - `Lvl 1`: Counting Sides
   - `Lvl 2`: Square Area & Sides
   - `Lvl 3`: Triangle Angles (`180°`)
   - `Lvl 4`: Straight & Full Turns
   - `Lvl 5`: Right Triangle Area
   - `Lvl 6`: Cube & Box Volume
   - `Lvl 7`: Polygon Perimeters
   - `Lvl 8`: Master Space Geometry
8. **Coin Jar** (`coin_jar`) — Count coin stacks, savings goals & mystery number riddles.
   - `Lvl 1`: Coin Stacks
   - `Lvl 2`: Mixed Coin Jars
   - `Lvl 3`: Missing Addend (`?`)
   - `Lvl 4`: Balance Equations
   - `Lvl 5`: Weekly Savings
   - `Lvl 6`: Two-Step Mystery
   - `Lvl 7`: Fair Averages
   - `Lvl 8`: Master Vault Riddles

---

### Star & Progression System
- **Per-Level 3-Star Rating (`192` Total Max Stars)**: Each of the `8` levels inside each activity tracks its own `0–3` star high score (`24` max stars per activity; `192` total across all `8` activities).
- **Rainbow Stars (Max Level 8 Reward)**: Finishing **Level 8** unlocks **Rainbow Stars** (`assets/ui/star_rainbow.svg`) on the Level 8 activity card, the Results screen (`"RAINBOW STARS!"`), and the **My Math Journey** progress list (`(Max ★)`).
- **Save Migration**: Saved progress in `user://save_data.cfg` automatically migrates older per-activity star totals into per-level stars without losing earned stars.

### Sticker Shop (`Progress & Sticker Shop`)
Spend earned `₱` coins to unlock and pin a badge next to Pip on the Main Menu:
- **Sprout** — `₱15`
- **Cozy Kitty** — `₱25`
- **Rainbow** — `₱35`
- **Rocket** — `₱45`
- **Gold Crown** — `₱60`
- **Math Trophy** — `₱80`

### Audio, Settings & Secrets
- **Cozy Main Theme** (`assets/audio/bgm_cozy.mp3`) with smooth fade and SFX ducking.
- **BGM Volume Slider (`0%–100%`)**, **Music/SFX toggles**, **Reduce Motion**, and **Window Resolution / Fullscreen** presets on the **Settings** screen.
- **Secret Rare Theme**: Click a creator's name **5 times** on the **About** screen to fade out the default theme and switch to `re-learn the basics main theme (Secret).mp3` for the current session (resets back to default on relaunch).
