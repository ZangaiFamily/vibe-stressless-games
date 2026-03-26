# Collection & Avoidance

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Juicy Feedback, Effortless to Play

## Overview

Collection & Avoidance is the collision resolution system — it detects when falling items overlap the player's collection area and determines the outcome. When a coin overlaps, it is collected: removed from play and its `point_value` is sent to the Score System, its `feedback_tag` to the Game Juice System. When a hazard overlaps, the player is hit: the Lives System is notified of `damage`, the streak resets, and hit feedback plays. This is the system where catching and dodging actually happen — without it, items would fall through the player with no effect.

## Player Fantasy

Every catch should feel like a small victory. A coin touches your umbrella and *clink* — gone, absorbed, yours. The collection radius should be generous enough that a near-miss still counts (the player should feel skillful, not cheated), but precise enough that weaving between a hazard and a coin feels intentional. When a hazard hits, it's a gentle "oops" — not a punishment, just a nudge that breaks your rhythm. The system should be invisible: the player thinks "I caught the coin" not "the collision system detected an overlap."

## Detailed Design

### Core Rules

1. **Collision detection**: Uses Godot's `Area2D` overlap system. The player has a collection `Area2D` (circle, radius = `COLLISION_RADIUS` from Player Controller). Each falling item has an `Area2D` (circle, radius = `item_def.hitbox_radius` from Item Database).

2. **On overlap (item enters player area)**:
   - Read `item_def.category` from the item's attached `ItemDef`
   - If **COIN**: emit `item_collected(item_def)` signal → Score System, Streak Multiplier, Game Juice. Remove item from play (return to pool).
   - If **HAZARD** and player is NOT invincible: emit `item_hit(item_def)` signal → Lives System, Streak Multiplier (reset), Game Juice. Remove item. Start invincibility period.
   - If **HAZARD** and player IS invincible: ignore. Item passes through.

3. **Invincibility frames**: After a hazard hit, the player enters invincible state for `INVINCIBILITY_DURATION` seconds. During this time, hazards pass through without effect. Coins can still be collected normally. Player sprite flashes to indicate invincibility.

4. **Items that miss**: Items that fall past the player without overlapping are simply returned to the pool when they exit the screen. No penalty for missing coins.

5. **Signal-based architecture**: This system detects overlaps and emits signals. It does NOT calculate score, subtract lives, or play sounds itself — those are handled by downstream systems listening to its signals.

### States and Transitions

| State | Description | Coins | Hazards | Transitions To |
|-------|-------------|-------|---------|---------------|
| **Normal** | Standard play | Collected | Deal damage | Invincible (hazard hit) |
| **Invincible** | Brief post-hit immunity | Collected | Pass through | Normal (timer expires) |
| **Disabled** | Run ended | Ignored | Ignored | Normal (new run) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Player Controller** | Upstream | Player's `Area2D` position and shape | Hard dependency |
| **Item Spawner** | Upstream | Spawned items with `Area2D` and `ItemDef` reference | Hard dependency |
| **Score System** | Downstream | `item_collected(item_def)` signal | Score reads `point_value` |
| **Lives System** | Downstream | `item_hit(item_def)` signal | Lives reads `damage` |
| **Streak Multiplier** | Downstream | `item_collected` (increment) and `item_hit` (reset) signals | |
| **Game Juice System** | Downstream | Both signals with `feedback_tag` | Triggers visual/audio feedback |
| **Item Database** | Indirect | `ItemDef` attached to each item provides `category`, `damage`, `feedback_tag` | |

## Formulas

```
# Collision check (handled by Godot physics)
overlap = player_area.overlaps_area(item_area)

# Invincibility timer
invincible = elapsed_since_hit < INVINCIBILITY_DURATION
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `INVINCIBILITY_DURATION` | float | 1.0 | 0.3 - 2.0 | Seconds of post-hit immunity |

No complex math — this system is logic, not calculation. The formulas live in Score System and Lives System.

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Coin and hazard overlap player simultaneously** | Both are processed. Coin is collected (score + streak), hazard hits (damage + streak reset). Net effect: score gained, streak reset, life lost. | Process in signal order — both events are independent. |
| **Multiple coins overlap in same frame** | Each coin triggers `item_collected` independently. All are counted. | Dense coin clusters should feel rewarding, not lose items. |
| **Hazard hits during invincibility** | Ignored. Hazard passes through and falls off screen. | Core purpose of i-frames. |
| **Item overlaps player at exact moment run ends** | If run-end signal arrives first, the collision is ignored (Disabled state). | Race condition resolved by state check at overlap time. |
| **Player moves into item (not item falling into player)** | Same overlap detection. No difference. | Godot Area2D doesn't distinguish who moved. |
| **Zero-radius collision shapes** | No overlap possible. Item is uncatchable/unhittable. | Per Item Database edge case for decorative items. |

## Dependencies

### Upstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Player Controller** | Hard | Player Area2D | Designed |
| **Item Spawner** | Hard | Spawned item Area2Ds with ItemDef | Designed |

### Downstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Score System** | Hard | `item_collected(item_def)` signal | Not yet designed |
| **Lives System** | Hard | `item_hit(item_def)` signal | Not yet designed |
| **Streak Multiplier** | Hard | Both signals | Not yet designed |
| **Game Juice System** | Soft | Both signals with feedback_tag | Not yet designed |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `INVINCIBILITY_DURATION` | float | 1.0 | 0.3 - 2.0 | Post-hit immunity window | Too short: chain-hits from clusters. Too long: player can ignore hazards. |

Note: Collision radii are owned by Player Controller (`COLLISION_RADIUS`) and Item Database (`hitbox_radius`). This system uses them but doesn't define them.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Coins touching the player area are collected and removed | Walk into a coin; verify score increases and coin disappears. |
| 2 | Hazards touching the player area deal damage and trigger hit feedback | Walk into a bomb; verify life lost and visual/audio feedback. |
| 3 | Invincibility activates after a hit for INVINCIBILITY_DURATION seconds | Hit a hazard, immediately walk into another; verify second hazard passes through. |
| 4 | Coins are still collected during invincibility | Hit a hazard, then catch a coin during i-frames; verify coin is collected. |
| 5 | Player sprite visually flashes during invincibility | Hit a hazard; observe flashing sprite for ~1 second. |
| 6 | Items that fall past the player without touching are removed cleanly | Let items fall; verify no items accumulate off-screen. |
| 7 | Simultaneous coin + hazard overlap processes both correctly | Engineer overlap; verify both score gained and life lost. |
| 8 | Collision processing stays under 0.2ms per frame with 30 active items | Profile during max-density gameplay. |
