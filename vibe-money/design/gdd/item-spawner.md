# Item Spawner

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Vibe First, Challenge

## Overview

The Item Spawner creates falling items (coins and hazards) at the top of the screen at timed intervals during gameplay. It selects which item to spawn using weighted random selection from the Item Database's spawn table, positions items at random horizontal locations, and sets their fall speed using a base speed multiplied by each item's `fall_speed_modifier`. The spawner is the game's primary content generator — it turns the static Item Database into a dynamic rain of objects the player reacts to. The player never interacts with this system directly but experiences it constantly. Without it, nothing falls from the sky and there is no game.

## Player Fantasy

The sky is generous but unpredictable. Coins drift down like rain — sometimes sparse, sometimes in clusters that make your heart jump. A gold coin glints between two bombs, and you have to decide: go for it or play safe? The spawner creates the moment-to-moment tension in what is otherwise a relaxation game. It should feel like weather — organic, varied, never quite the same twice, but never unfair. The spawner is the invisible hand behind the "just one more run" feeling: each run generates a unique sequence of risk-reward moments that the player can never fully predict.

## Detailed Design

### Core Rules

1. **Spawn timer**: Items spawn on a repeating timer. Each tick, one item is created. The interval between spawns is controlled by `SPAWN_INTERVAL` (modified by the Difficulty Curve system over time).

2. **Item selection (weighted random)**:
   - Query `ItemRegistry.get_spawn_table()` for all spawnable items with their `rarity_weight`
   - The Difficulty Curve provides a `hazard_ratio_modifier` (0.0 to 1.0) that adjusts the coin-to-hazard balance
   - Adjusted weights: coin weights are multiplied by `(1.0 - hazard_ratio_modifier)`, hazard weights by `hazard_ratio_modifier`. Both are normalized so they still sum correctly.
   - Select one item via weighted random from adjusted weights.

3. **Spawn positioning (column-based with jitter)**:
   - Divide the viewport width into `SPAWN_COLUMNS` equal columns (default: 5)
   - Select a random column, avoiding the same column as the previous spawn (prevents vertical stacking)
   - Add horizontal jitter: `x = column_center + randf_range(-COLUMN_JITTER, COLUMN_JITTER)`
   - Y position: just above the top of the viewport (off-screen)

4. **Item instantiation**: Each spawned item is a scene instance with:
   - `ItemDef` resource reference (from Item Database)
   - Fall speed: `BASE_FALL_SPEED * item_def.fall_speed_modifier * difficulty_speed_multiplier`
   - Collision shape sized to `item_def.hitbox_radius`
   - Visual scaled to `item_def.visual_scale`

5. **Item movement**: Spawned items fall straight down at their assigned speed. No horizontal drift, no curves (MVP). Items are removed when they exit the bottom of the viewport.

6. **Object pooling**: Items are pooled and recycled rather than instantiated/freed each time. Pool size = `MAX_ACTIVE_ITEMS`. When the pool is full, no new items spawn until one is freed.

7. **Spawn-free opening**: The first `SAFE_PERIOD` seconds of a run spawn only coins (no hazards). This matches the game concept's "first 30 seconds are coins only" onboarding curve.

### States and Transitions

| State | Description | Spawning? | Transitions To |
|-------|-------------|-----------|---------------|
| **Inactive** | Not in a run (menu, summary) | No | Active (run starts) |
| **Safe Period** | First N seconds of run | Coins only | Normal (safe period expires) |
| **Normal** | Standard gameplay | All items | Inactive (run ends) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Item Database** | Upstream reads | `get_spawn_table()` for item selection | Hard dependency — confirmed by Item Database GDD |
| **Difficulty Curve** | Upstream reads | `hazard_ratio_modifier`, `speed_multiplier`, `spawn_rate_multiplier` | Difficulty Curve controls how the spawner changes over time |
| **Collection & Avoidance** | Downstream | Spawned items have collision areas that C&A detects | Spawner creates items; C&A handles what happens when they touch the player |
| **Run Manager** | Upstream | `start()` / `stop()` signals | Controls when spawning is active |
| **Game Juice System** | Downstream (indirect) | Items carry `feedback_tag` from their `ItemDef` | Juice system reads the tag on collection/hit, not from the spawner directly |

## Formulas

### Spawn Interval

```
effective_interval = BASE_SPAWN_INTERVAL / spawn_rate_multiplier
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_SPAWN_INTERVAL` | float | 0.6 | 0.3 - 1.5 | Seconds between spawns at difficulty 0 |
| `spawn_rate_multiplier` | float | 1.0 | 1.0 - 3.0 | From Difficulty Curve (increases over time) |
| `effective_interval` | float | 0.6 | 0.2 - 1.5 | Actual seconds between spawns |

At defaults: ~1.67 spawns/sec at start, ramping to ~5 spawns/sec at max difficulty.

### Fall Speed

```
fall_speed = BASE_FALL_SPEED * item_def.fall_speed_modifier * difficulty_speed_multiplier
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_FALL_SPEED` | float | 200.0 | 100 - 400 | Pixels per second at difficulty 0 |
| `item_def.fall_speed_modifier` | float | varies | 0.5 - 2.0 | Per-item modifier from Item Database |
| `difficulty_speed_multiplier` | float | 1.0 | 1.0 - 2.0 | From Difficulty Curve |

**Example**: Gold coin (1.3x modifier) at max difficulty (2.0x): `200 * 1.3 * 2.0 = 520 px/sec`. At 60fps on a 1080p screen, that's ~2 seconds to cross the screen — still reactable.

### Column Position

```
column_width = viewport_width / SPAWN_COLUMNS
column_center = (selected_column + 0.5) * column_width
x = clamp(column_center + randf_range(-COLUMN_JITTER, COLUMN_JITTER), margin, viewport_width - margin)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `SPAWN_COLUMNS` | int | 5 | 3 - 8 | Number of horizontal lanes |
| `COLUMN_JITTER` | float | 20.0 | 0 - 50 | Random horizontal offset from column center (px) |

### Time on Screen

```
time_on_screen = viewport_height / fall_speed
```

At defaults (200 px/sec, 1920px height): ~9.6 seconds. At max difficulty+fast item: ~3.7 seconds. Both provide adequate reaction time.

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Pool exhausted (MAX_ACTIVE_ITEMS reached)** | Spawn tick is skipped. Timer continues. Next tick spawns if a slot freed. | Prevents memory growth. At max difficulty with ~5 spawns/sec and ~4 sec screen time, ~20 items max. Pool of 30 handles spikes. |
| **Only one spawn column available (after excluding previous)** | That column is used. No exclusion if only 1 column. | Prevents deadlock with SPAWN_COLUMNS=2. |
| **Empty spawn table** | Spawner logs warning, does nothing. Timer still ticks. | Per Item Database edge case. |
| **Safe period longer than run** | Run is all coins. Valid edge case for very short runs during testing. | Not harmful — just a chill run. |
| **Viewport resize** | Column widths recalculate on next spawn. Items already falling are unaffected. | Handles PC window resize. |
| **Two items spawn at near-identical positions** | Column exclusion prevents consecutive same-column. Jitter may still cause overlap. Acceptable — items overlap visually but both are independently collectible/hittable. | Perfect de-overlap isn't worth the complexity for this game. |

## Dependencies

### Upstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Item Database** | Hard | `get_spawn_table()`, `get_items_by_category(COIN)` | Designed |

### Downstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Collection & Avoidance** | Hard | Spawned item Area2D nodes with ItemDef reference | Not yet designed |
| **Difficulty Curve** | Upstream control | Provides `hazard_ratio_modifier`, `speed_multiplier`, `spawn_rate_multiplier` | Not yet designed |

### External Dependencies

| Dependency | Notes |
|------------|-------|
| **Godot Timer** | Spawn interval timer |
| **Godot PackedScene** | Item scene template for pooling |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `BASE_SPAWN_INTERVAL` | float | 0.6 | 0.3 - 1.5 | How often items appear at start | Too low: overwhelming. Too high: boring, empty sky. |
| `BASE_FALL_SPEED` | float | 200.0 | 100 - 400 | How fast items fall at start | Too slow: tedious. Too fast: unreactable. |
| `SPAWN_COLUMNS` | int | 5 | 3 - 8 | Horizontal spread of spawns | Too few: predictable patterns. Too many: effectively random. |
| `COLUMN_JITTER` | float | 20.0 | 0 - 50 | Randomness within columns | 0: items look grid-locked. Too high: defeats column system. |
| `MAX_ACTIVE_ITEMS` | int | 30 | 15 - 50 | Object pool size | Too low: items stop spawning at high difficulty. Too high: wasted memory. |
| `SAFE_PERIOD` | float | 5.0 | 0 - 30 | Coins-only period at run start | 0: hazards immediately (harsh). Too long: boring start. |
| `SPAWN_MARGIN` | float | 32.0 | 16 - 64 | Min distance from screen edge | Too small: items clip edge. Too large: narrow play area. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Items spawn at regular intervals matching `BASE_SPAWN_INTERVAL` | Count spawns over 10 seconds; verify ~16-17 items at default 0.6s interval. |
| 2 | Item type distribution matches rarity weights over 100+ spawns | Run 200 spawns, tally types, chi-squared test against expected probabilities. |
| 3 | Items spread across all columns with no consecutive same-column spawns | Visual inspection over 50 spawns; verify horizontal spread. |
| 4 | Safe period spawns only coins for the configured duration | Start run, verify no hazards for first `SAFE_PERIOD` seconds. |
| 5 | Items fall at correct speed (BASE_FALL_SPEED * modifiers) | Measure gold coin (1.3x) fall time vs bronze (1.0x); verify proportional difference. |
| 6 | Items are removed when they exit the bottom of the screen | Let items fall without catching; verify no accumulation below viewport. |
| 7 | Object pool prevents unbounded instance creation | Monitor node count at max difficulty for 60 seconds; verify stays under MAX_ACTIVE_ITEMS. |
| 8 | Spawner stops on run end and resumes on run start | End a run; verify no new items spawn during summary screen. |
| 9 | Spawning + movement processing stays under 0.5ms per frame at max load | Profile with 30 active items falling simultaneously. |
