# Score System

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Juicy Feedback

## Overview

The Score System tracks the player's point total during a run. It listens for `item_collected` signals from the Collection & Avoidance system, reads the item's `point_value` from its `ItemDef`, multiplies it by the current streak multiplier from the Streak Multiplier system, and adds the result to the running total. The score is the primary measure of run performance, displayed on the HUD during play and on the Run Summary Screen at run end. The system also tracks the run's high score and reports the final score to the Run Manager.

## Player Fantasy

The score counter is your scoreboard — a constantly climbing number that validates every catch. When your streak multiplier is high and you catch a gold coin, watching the score jump by 500 points feels like hitting a jackpot. The score should feel generous (big numbers feel better than small ones) and responsive (the counter should punch up immediately on catch, not lag behind).

## Detailed Design

### Core Rules

1. **Score calculation per catch**:
   ```
   points_earned = item_def.point_value * streak_multiplier
   total_score += points_earned
   ```

2. **Score only increases**: There is no score penalty for getting hit, missing coins, or any other event. Score is a pure accumulator.

3. **Score resets each run**: `total_score = 0` on run start. The previous run's score is preserved in the Run Summary.

4. **Float-to-int display**: Score is tracked as `int`. No fractional points. The streak multiplier is applied before rounding: `points_earned = int(item_def.point_value * streak_multiplier)`.

5. **Score events**: Emits `score_changed(total_score, points_earned)` signal each time score increases, for HUD and Game Juice to react.

### States and Transitions

Stateless accumulator. Active during gameplay, frozen during summary/menu.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Collection & Avoidance** | Upstream | Listens to `item_collected(item_def)` | Hard dep — triggers score calculation |
| **Streak Multiplier** | Upstream reads | `get_multiplier() -> float` | Hard dep — multiplies point value |
| **HUD** | Downstream | `score_changed(total, earned)` signal | Displays score |
| **Run Summary Screen** | Downstream | `final_score` on run end | Displays end-of-run score |
| **Run Manager** | Downstream | Reports `final_score` | For run records |

## Formulas

```
points_earned = int(item_def.point_value * streak_multiplier)
total_score += points_earned
```

| Variable | Description | Range |
|----------|-------------|-------|
| `item_def.point_value` | Base points from Item Database | 10 (bronze), 25 (silver), 100 (gold) |
| `streak_multiplier` | From Streak Multiplier system | 1.0x - 5.0x |
| `points_earned` | Points for this catch | 10 - 500 |

**Example earnings at different streaks:**

| Coin | Base | 1x | 1.5x | 2x | 3x | 5x |
|------|------|----|------|----|----|-----|
| Bronze | 10 | 10 | 15 | 20 | 30 | 50 |
| Silver | 25 | 25 | 37 | 50 | 75 | 125 |
| Gold | 100 | 100 | 150 | 200 | 300 | 500 |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Streak multiplier changes between collection signal and score calc** | Score uses multiplier at time of calculation (same frame as collection). | Signals are synchronous within a frame. |
| **Integer overflow** | At 500 points/catch * 5 spawns/sec * 300 seconds = 750,000 max theoretical. Well within int32 range. | Not a real risk for this game's scale. |
| **Score of 0 at run end** | Valid. Player dodged everything and caught nothing. Display "0" normally. | No special handling needed. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Collection & Avoidance** | Hard | `item_collected(item_def)` signal | Designed |
| **Streak Multiplier** | Hard | `get_multiplier()` | Not yet designed |

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **HUD** | Soft | `score_changed` signal | Not yet designed |
| **Run Summary Screen** | Soft | `final_score` | Not yet designed |
| **Run Manager** | Soft | `final_score` | Not yet designed |

## Tuning Knobs

No dedicated tuning knobs — score scaling is controlled by Item Database `point_value` and Streak Multiplier thresholds. This system is pure passthrough math.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Collecting a bronze coin at 1x streak adds exactly 10 points | Catch bronze at streak 0; verify score = 10. |
| 2 | Streak multiplier is correctly applied | Catch gold at 5x streak; verify 500 points added. |
| 3 | Score resets to 0 on new run | Start new run after scoring; verify score = 0. |
| 4 | Score never decreases within a run | Hit hazards, miss coins; verify score only goes up or stays same. |
| 5 | `score_changed` signal fires with correct values on every collection | Log signal emissions; verify total and earned values. |
| 6 | Final score is correctly reported to Run Summary | Complete a run; verify summary shows same score as HUD at game over. |
