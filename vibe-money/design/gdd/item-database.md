# Item Database

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Juicy Feedback, Vibe First

## Overview

The Item Database is the central registry of every falling object in Vibe Money — coins the player collects and hazards the player dodges. It defines each item type's properties: point value, visual category, fall speed modifier, rarity weight, and feedback tags. The system is pure data with no runtime behavior — it answers "what exists and what are its properties?" while other systems (Item Spawner, Collection & Avoidance, Score System) decide when to spawn items, how to detect collisions, and how to calculate scores. Without this system, item properties would be scattered across spawner code, collision handlers, and score logic, making balance tuning impossible.

## Player Fantasy

The player never interacts with the Item Database directly — they interact with the *items* it defines. The fantasy this system serves is **variety and discovery**: the sky isn't just raining generic coins, it's raining bronze pennies, shiny silver dollars, and rare gleaming gold bars. Each item type should feel distinct the moment it appears — different size, different shimmer, different sound — so the player's eyes learn to scan the rain and make split-second "go for it or dodge" decisions. The database makes this possible by giving each item a unique identity. When a gold coin appears and the player's pulse quickens slightly — that's this system working.

## Detailed Design

### Core Rules

1. **Item Definition Resource**: Each item type is a custom Godot Resource (`ItemDef`) with the following schema:

   | Property | Type | Description |
   |----------|------|-------------|
   | `id` | StringName | Unique identifier (e.g., `"coin_bronze"`, `"hazard_bomb"`) |
   | `display_name` | String | Player-facing name (e.g., `"Bronze Coin"`) |
   | `category` | Enum: COIN, HAZARD | Determines collection vs. avoidance behavior |
   | `point_value` | int | Base score awarded on collection (0 for hazards) |
   | `currency_value` | int | Persistent currency awarded (0 for hazards, 0 for MVP) |
   | `rarity_weight` | float | Relative spawn probability (higher = more common) |
   | `fall_speed_modifier` | float | Multiplier on base fall speed (1.0 = normal) |
   | `hitbox_radius` | float | Collision circle radius in pixels |
   | `visual_scale` | float | Display size multiplier (1.0 = standard) |
   | `feedback_tag` | StringName | Tag used by Game Juice and Audio systems (e.g., `"collect_gold"`, `"hit_bomb"`) |
   | `damage` | int | Lives lost on contact (0 for coins, 1 for standard hazards) |

2. **Item Registry**: A single autoload (`ItemRegistry`) loads all `ItemDef` resources at startup and provides lookup:
   - `get_item(id: StringName) -> ItemDef`
   - `get_items_by_category(category: Category) -> Array[ItemDef]`
   - `get_spawn_table() -> Array[ItemDef]` — returns all items with `rarity_weight > 0`, used by Item Spawner

3. **MVP Item Roster** (6 items):

   **Coins:**

   | ID | Name | Points | Rarity Weight | Fall Speed | Hitbox | Notes |
   |----|------|--------|---------------|------------|--------|-------|
   | `coin_bronze` | Bronze Coin | 10 | 60 | 1.0x | 16px | Common, bread-and-butter |
   | `coin_silver` | Silver Coin | 25 | 30 | 1.1x | 14px | Slightly faster, slightly smaller |
   | `coin_gold` | Gold Coin | 100 | 10 | 1.3x | 12px | Rare, fast, small — high risk/reward |

   **Hazards:**

   | ID | Name | Damage | Rarity Weight | Fall Speed | Hitbox | Notes |
   |----|------|--------|---------------|------------|--------|-------|
   | `hazard_bomb` | Bomb | 1 | 50 | 0.9x | 20px | Slow, large — easy to see, still threatening |
   | `hazard_poop` | Poop | 1 | 35 | 1.0x | 16px | Medium, standard |
   | `hazard_spike` | Spike | 1 | 15 | 1.4x | 10px | Fast, small — hard to spot, punishes inattention |

4. **Rarity weight is relative, not absolute**: The Item Spawner normalizes weights into probabilities. With the weights above: Bronze = 60/200 (30%), Silver = 30/200 (15%), Gold = 10/200 (5%), Bomb = 50/200 (25%), Poop = 35/200 (17.5%), Spike = 15/200 (7.5%). Total coins = 50%, total hazards = 50%. The Difficulty Curve system adjusts this ratio over time.

5. **Immutable at runtime**: Item definitions are read-only during gameplay. No item changes its properties mid-run. Balance changes happen between builds, not between frames.

### States and Transitions

The Item Database is stateless. It is loaded once at startup and serves as a read-only lookup for the lifetime of the application. No state machine needed.

### Interactions with Other Systems

| System | Direction | Interface | Data Exchanged |
|--------|-----------|-----------|---------------|
| **Item Spawner** | Downstream reads | `get_spawn_table()`, `get_items_by_category()` | Item roster with rarity weights for spawn selection |
| **Collection & Avoidance** | Downstream reads | `item_def.category`, `item_def.damage` | Determines collect vs. hurt behavior on contact |
| **Score System** | Downstream reads | `item_def.point_value` | Base points before streak multiplier |
| **Game Juice System** | Downstream reads | `item_def.feedback_tag`, `item_def.visual_scale` | Determines which particle/animation/sound to play |
| **Audio Manager** | Downstream reads | `item_def.feedback_tag` | Maps to specific SFX (e.g., `"collect_gold"` → gold coin clink) |
| **Difficulty Curve** | Indirect | Does not read Item Database directly | Adjusts spawner's coin-to-hazard ratio, not item definitions |
| **Cosmetic System** | Downstream reads (Vertical Slice) | `item_def.id` | Maps item IDs to unlockable visual variants |

## Formulas

### Spawn Probability (computed by Item Spawner, defined here for reference)

```
probability(item) = item.rarity_weight / sum(all_active_items.rarity_weight)
```

| Variable | Description | MVP Value |
|----------|-------------|-----------|
| `rarity_weight` | Per-item weight from the roster table | See Core Rules |
| `sum(all_active_items.rarity_weight)` | Sum of weights for all items currently in the spawn pool | 200 (MVP: 60+30+10+50+35+15) |

**MVP Probability Table:**

| Item | Weight | Probability | Expected per 100 spawns |
|------|--------|-------------|------------------------|
| Bronze Coin | 60 | 30.0% | 30 |
| Silver Coin | 30 | 15.0% | 15 |
| Gold Coin | 10 | 5.0% | 5 |
| Bomb | 50 | 25.0% | 25 |
| Poop | 35 | 17.5% | 17-18 |
| Spike | 15 | 7.5% | 7-8 |

### Expected Score per Item (before streak multiplier)

```
expected_value(item) = item.point_value * probability(item)
```

| Item | Points | Probability | Expected Value Contribution |
|------|--------|-------------|---------------------------|
| Bronze Coin | 10 | 30.0% | 3.0 per spawn |
| Silver Coin | 25 | 15.0% | 3.75 per spawn |
| Gold Coin | 100 | 5.0% | 5.0 per spawn |
| **Weighted average score per spawn** | | | **11.75 points** |

At ~2 spawns/second, base earn rate is ~23.5 points/second (before multiplier, assuming perfect collection of all coins).

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Empty spawn table** | `get_spawn_table()` returns empty array. Item Spawner must handle this gracefully (spawn nothing). | Should never happen in production but protects against misconfigured data files. |
| **All rarity weights are 0** | Same as empty spawn table — no items are spawnable. | Prevents division by zero in probability calculation. |
| **Single item in spawn table** | That item spawns 100% of the time. System works correctly. | Valid for testing or special game modes. |
| **Duplicate item IDs** | `ItemRegistry` logs an error at startup and keeps the first loaded definition. | Fail-loud so the designer notices immediately. |
| **Missing item ID lookup** | `get_item()` returns `null`. Calling systems must null-check. | Protects against typos in other systems referencing item IDs. |
| **Very high rarity weight on one item** | That item dominates the spawn pool. Mathematically correct but gameplay may suffer. | Not an error — this is a balance issue, not a bug. Flag in playtesting. |
| **Negative point values** | Allowed by schema. A coin with negative points would subtract score. | Reserved for future "trick item" designs. Not used in MVP. |
| **Zero hitbox radius** | Item cannot be collected or hit. Effectively invisible to gameplay. | Useful for purely visual items (e.g., decorative rain sparkles). Not used in MVP. |
| **New items added post-launch** | Adding a new `.tres` resource and placing it in the items directory is sufficient. No code changes needed. | Data-driven design enables live content updates. |

## Dependencies

### Upstream (this system depends on)

None. The Item Database is a foundation-layer system with zero dependencies.

### Downstream (these systems depend on this)

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Item Spawner** | Hard | `get_spawn_table()`, `get_items_by_category()` | Not yet designed |
| **Collection & Avoidance** | Hard | Reads `category`, `damage`, `point_value` from `ItemDef` | Not yet designed |
| **Score System** | Hard | Reads `point_value` from `ItemDef` | Not yet designed |
| **Game Juice System** | Hard | Reads `feedback_tag`, `visual_scale` from `ItemDef` | Not yet designed |
| **Audio Manager** | Soft | Reads `feedback_tag` for SFX mapping (works without it, just no item-specific sounds) | Not yet designed |
| **Cosmetic System** | Soft (Vertical Slice) | Maps `id` to visual variants | Not yet designed |

### External Dependencies

| Dependency | Notes |
|------------|-------|
| **Godot Resource system** | `ItemDef` extends `Resource`. Loaded via `ResourceLoader` or preload. |
| **File system convention** | All `.tres` item files stored in `assets/data/items/` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `point_value` (per item) | int | See roster | 1 - 1000 | Score pacing and how "valuable" items feel | Too low: score feels stagnant. Too high: numbers become meaningless. |
| `rarity_weight` (per item) | float | See roster | 1 - 100 | How often each item appears | Too low on coins: frustrating drought. Too high on hazards: overwhelming. |
| `fall_speed_modifier` (per item) | float | See roster | 0.5 - 2.0 | Per-item difficulty and visual distinctness | Below 0.5: items feel frozen. Above 2.0: unreactable on mobile. |
| `hitbox_radius` (per item) | float | See roster | 8 - 32 | Collection/avoidance forgiveness | Too small: unfair misses. Too large: no skill expression. |
| `damage` (per hazard) | int | 1 | 0 - 3 | Punishment severity | 0: hazards become harmless. >1: may feel unfair for a "chill" game. |

**Interaction warnings:**
- `rarity_weight` across all items determines the coin-to-hazard ratio. Changing one item's weight affects every other item's spawn probability.
- `fall_speed_modifier` interacts with the Difficulty Curve's base speed. A 2.0x modifier at max difficulty could make items unreactable.
- `hitbox_radius` and `visual_scale` should stay proportional — a visually large item with a tiny hitbox feels broken.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | All 6 MVP items load successfully at startup with no errors | Launch game, check console for errors. `ItemRegistry` logs item count. |
| 2 | `get_item(id)` returns the correct `ItemDef` for all 6 MVP item IDs | Unit test: query each ID, assert properties match roster table. |
| 3 | `get_item(invalid_id)` returns `null` without crashing | Unit test: query non-existent ID, assert null return. |
| 4 | `get_spawn_table()` returns exactly the items with `rarity_weight > 0` | Unit test: verify array length and contents. |
| 5 | `get_items_by_category(COIN)` returns 3 coins; `get_items_by_category(HAZARD)` returns 3 hazards | Unit test: assert counts and categories. |
| 6 | Duplicate item IDs are detected and logged as errors at startup | Add a duplicate `.tres`, launch, verify error log. |
| 7 | Spawn probability math is correct (weights sum to expected total) | Unit test: sum all `rarity_weight` values, verify probability calculation. |
| 8 | Adding a new `.tres` item file requires zero code changes | Create a new item resource, launch, verify it appears in `get_spawn_table()`. |
| 9 | Item definitions are truly immutable at runtime | Unit test: attempt to modify a property after load, assert it fails or has no effect. |
| 10 | Registry loads in <10ms on target hardware | Profile `ItemRegistry._ready()`. 6 resources should be near-instant. |

