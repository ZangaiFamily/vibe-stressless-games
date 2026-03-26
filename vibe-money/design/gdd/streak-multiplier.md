# Streak Multiplier

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Challenge, Juicy Feedback

## Overview

The Streak Multiplier tracks consecutive coin catches without hitting a hazard. Each catch increments the streak counter. At defined thresholds (5, 10, 20, 50), the score multiplier steps up. Hitting a hazard resets both the streak counter and multiplier to their base values. The system creates emergent risk-reward gameplay: players near a streak threshold may take risks to reach the next multiplier tier, and losing a high streak feels meaningful without being devastating. The streak count and current multiplier are displayed on the HUD and feed into the Audio Manager for pitch scaling.

## Player Fantasy

The streak is your hot hand, your flow state made visible. Each consecutive catch builds momentum — the pitch rises, the multiplier climbs, and you're in the zone. Reaching streak 50 at 5x multiplier feels like being on fire. When a bomb breaks your streak, there's a brief "aww" — but you immediately want to start building again. The streak is the emotional engine of the game: it transforms routine coin-catching into a tense, rewarding chase.

## Detailed Design

### Core Rules

1. **Streak counter**: Starts at 0 each run. Incremented by 1 on every `item_collected` signal. Reset to 0 on every `item_hit` signal.

2. **Multiplier tiers** (stepped, not continuous):

   | Streak Threshold | Multiplier |
   |-----------------|------------|
   | 0 - 4 | 1.0x |
   | 5 - 9 | 1.5x |
   | 10 - 19 | 2.0x |
   | 20 - 49 | 3.0x |
   | 50+ | 5.0x |

3. **Milestone events**: When the streak crosses a threshold, emit `streak_milestone(tier, multiplier)` signal. This triggers a celebration sound (Audio Manager `streak_milestone` tag) and visual flourish (Game Juice System).

4. **Streak reset**: On `item_hit`, streak resets to 0 and multiplier resets to 1.0x. Emit `streak_reset(previous_streak)` signal.

5. **Interface**: `get_multiplier() -> float` returns the current multiplier for the Score System. `get_streak() -> int` returns the current streak count for the HUD and Audio Manager.

### States and Transitions

| State | Description | Multiplier | Transitions To |
|-------|-------------|------------|---------------|
| **Base** | Streak 0-4 | 1.0x | Tier 1 (streak reaches 5) |
| **Tier 1** | Streak 5-9 | 1.5x | Tier 2 (10), Base (hit) |
| **Tier 2** | Streak 10-19 | 2.0x | Tier 3 (20), Base (hit) |
| **Tier 3** | Streak 20-49 | 3.0x | Tier 4 (50), Base (hit) |
| **Tier 4** | Streak 50+ | 5.0x | Base (hit) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Collection & Avoidance** | Upstream | `item_collected` (increment) and `item_hit` (reset) signals | Hard dep |
| **Score System** | Downstream | `get_multiplier()` called on each collection | Hard dep |
| **Audio Manager** | Downstream | `set_streak(count)` for pitch scaling; `streak_milestone` tag | Soft dep |
| **HUD** | Downstream | `streak_changed(count, multiplier)` signal | Soft dep |
| **Game Juice System** | Downstream | `streak_milestone` and `streak_reset` signals | Soft dep |

## Formulas

```
# Multiplier lookup (stepped)
func get_multiplier() -> float:
    for i in range(THRESHOLDS.size() - 1, -1, -1):
        if streak_count >= THRESHOLDS[i].streak:
            return THRESHOLDS[i].multiplier
    return 1.0
```

| Variable | Type | Description |
|----------|------|-------------|
| `streak_count` | int | Current consecutive catches (0+) |
| `THRESHOLDS` | Array | Sorted list of {streak, multiplier} pairs |

**Expected multiplier distribution per run** (assuming ~50% catch rate, 2 spawns/sec, 120s run, 2 hazard hits):
- Most time spent at 1.0x-2.0x. Reaching 3.0x is a good run. Reaching 5.0x is exceptional.

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Coin collected on same frame as hazard hit** | Collection & Avoidance processes both. Coin increments streak, then hazard resets it. Net: streak = 0. Score for that coin uses the pre-reset multiplier. | Score calculation happens during `item_collected` before `item_hit` resets streak. |
| **Streak = 999+** | Counter continues incrementing. Multiplier stays at 5.0x. No overflow risk with int32. | No cap needed — just stays at max tier. |
| **All thresholds removed (empty array)** | `get_multiplier()` returns 1.0x always. | Graceful degradation — game works, just no multiplier. |
| **Threshold at 0** | Multiplier starts above 1.0x from the first catch. | Valid for testing. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Collection & Avoidance** | Hard | `item_collected` and `item_hit` signals | Designed |

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Score System** | Hard | `get_multiplier()` | Designed |
| **Audio Manager** | Soft | `set_streak(count)` | Designed |
| **HUD** | Soft | `streak_changed` signal | Not yet designed |
| **Game Juice System** | Soft | `streak_milestone` / `streak_reset` signals | Not yet designed |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `THRESHOLDS` | Array | [{5, 1.5x}, {10, 2.0x}, {20, 3.0x}, {50, 5.0x}] | Streaks 3-100, multipliers 1.1x-10x | Progression pacing, risk-reward tension | Too easy to reach high tiers: no tension. Too hard: multiplier feels unreachable. |

**Interaction warning**: Multiplier values directly scale score (Score System) and audio pitch (Audio Manager). Changing thresholds affects both systems simultaneously.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Streak increments by 1 on each coin catch | Catch 5 coins; verify streak display shows 5. |
| 2 | Multiplier steps up at correct thresholds | Catch 5 coins; verify multiplier changes from 1.0x to 1.5x. |
| 3 | Streak and multiplier reset to 0/1.0x on hazard hit | Build streak to 10, hit hazard; verify streak = 0, multiplier = 1.0x. |
| 4 | Milestone signal fires at each threshold crossing | Cross streak 5; verify celebration sound/visual plays. |
| 5 | Score System correctly reads multiplier at time of collection | Catch gold at 5x; verify 500 points earned (not 100). |
| 6 | Audio Manager receives streak count for pitch scaling | Build streak; verify coin pitch rises. |
| 7 | Streak persists across milestone boundaries | At streak 4, catch coin; verify streak = 5 (not reset). |
