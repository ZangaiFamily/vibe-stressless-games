# Difficulty Curve

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Challenge, Vibe First

## Overview

The Difficulty Curve controls how the game gets harder over the course of a single run. It outputs three multipliers — spawn rate, fall speed, and hazard ratio — that feed directly into the Item Spawner. Difficulty ramps smoothly from 0% (easy start) to 100% (max challenge) over a configurable duration, using an ease-in curve so the early game stays gentle and the ramp accelerates in the back half. The player never sees this system, but they feel it: the sky gradually fills with more items falling faster, and hazards become more frequent. This is the system that makes a 3-minute run feel like a complete arc rather than a flat line.

## Player Fantasy

The difficulty curve serves the **"just one more run"** feeling. Each run tells a tiny story: calm beginning, rising tension, intense finale. The first 30 seconds are pure catching bliss — coins fall gently, you find your rhythm. Then hazards start appearing, items fall faster, the sky gets busier. By the 2-minute mark you're weaving between threats, streak on the line, making split-second decisions. The curve ensures every player — beginner or expert — experiences that satisfying arc from relaxation to challenge. When you finally lose, it feels earned, not cheap.

## Detailed Design

### Core Rules

1. **Time-based difficulty**: Difficulty is a function of elapsed run time only. No player-performance adaptation (MVP). A fixed curve means every run has a predictable arc.

2. **Difficulty value (0.0 to 1.0)**: A single normalized value `t` representing how far through the difficulty ramp we are:
   ```
   raw_t = clamp(elapsed_time / RAMP_DURATION, 0.0, 1.0)
   t = ease(raw_t, EASE_CURVE)
   ```

3. **Three output multipliers** derived from `t`:
   - `spawn_rate_multiplier = lerp(1.0, MAX_SPAWN_RATE_MULT, t)`
   - `speed_multiplier = lerp(1.0, MAX_SPEED_MULT, t)`
   - `hazard_ratio_modifier = lerp(MIN_HAZARD_RATIO, MAX_HAZARD_RATIO, t)`

4. **Difficulty plateaus at max**: After `RAMP_DURATION` seconds, all multipliers hold at their maximum values. The game doesn't get harder, but it doesn't get easier either.

5. **No difficulty reset within a run**: Difficulty never decreases. Losing a life does not reduce difficulty — this maintains the "chill but challenging" feel without punishing death with a boring reset.

### States and Transitions

| State | Description | `t` Value | Transitions To |
|-------|-------------|-----------|---------------|
| **Inactive** | Not in a run | N/A | Ramping (run starts) |
| **Ramping** | Difficulty increasing | 0.0 → 1.0 | Maxed (t reaches 1.0), Inactive (run ends) |
| **Maxed** | Full difficulty | 1.0 (held) | Inactive (run ends) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Item Spawner** | Downstream reads | `spawn_rate_multiplier`, `speed_multiplier`, `hazard_ratio_modifier` | Spawner queries these every spawn tick |
| **Run Manager** | Upstream | `start()` / `stop()` — resets elapsed time to 0 on run start | Run Manager owns the run lifecycle |

## Formulas

### Difficulty Value

```
raw_t = clamp(elapsed_time / RAMP_DURATION, 0.0, 1.0)
t = ease(raw_t, EASE_CURVE)
```

Godot's `ease()` function: `EASE_CURVE > 1.0` = ease-in (slow start, fast end). Default 2.0 means quadratic ease-in.

### Output Multipliers

```
spawn_rate_multiplier = lerp(1.0, MAX_SPAWN_RATE_MULT, t)
speed_multiplier = lerp(1.0, MAX_SPEED_MULT, t)
hazard_ratio_modifier = lerp(MIN_HAZARD_RATIO, MAX_HAZARD_RATIO, t)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `RAMP_DURATION` | float | 120.0 | 60 - 300 | Seconds from easiest to hardest |
| `EASE_CURVE` | float | 2.0 | 1.0 - 4.0 | Ease-in exponent (1.0 = linear, 2.0 = quadratic, 4.0 = very late ramp) |
| `MAX_SPAWN_RATE_MULT` | float | 2.5 | 1.5 - 4.0 | Spawn rate at max difficulty |
| `MAX_SPEED_MULT` | float | 1.8 | 1.3 - 2.5 | Fall speed at max difficulty |
| `MIN_HAZARD_RATIO` | float | 0.3 | 0.1 - 0.5 | Hazard proportion at start |
| `MAX_HAZARD_RATIO` | float | 0.7 | 0.5 - 0.9 | Hazard proportion at max |

**Example progression** (defaults, ease 2.0):

| Time | raw_t | t (eased) | Spawn Rate | Speed | Hazard % |
|------|-------|-----------|------------|-------|----------|
| 0s | 0.00 | 0.00 | 1.0x | 1.0x | 30% |
| 30s | 0.25 | 0.06 | 1.1x | 1.05x | 33% |
| 60s | 0.50 | 0.25 | 1.4x | 1.2x | 40% |
| 90s | 0.75 | 0.56 | 1.8x | 1.45x | 52% |
| 120s | 1.00 | 1.00 | 2.5x | 1.8x | 70% |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Run shorter than RAMP_DURATION** | Player dies before max difficulty. Normal — most runs will end before plateau. | The curve is designed so the mid-game is already engaging. |
| **RAMP_DURATION = 0** | `t` immediately = 1.0. Game starts at max difficulty. | Valid for testing or hard mode. |
| **EASE_CURVE = 1.0** | Linear ramp, no ease. Difficulty increases at constant rate. | Valid but doesn't match the gentle-start design goal. |
| **MIN_HAZARD_RATIO > MAX_HAZARD_RATIO** | Hazard ratio would decrease over time. Technically valid but backwards. | Log a warning. Let it work — could be interesting for testing. |
| **Run paused (if pause is added later)** | Elapsed time should NOT advance while paused. | Prevents difficulty spiking after a long pause. |

## Dependencies

### Upstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Run Manager** | Hard | Provides run start/stop signals and elapsed time | Not yet designed |

### Downstream

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Item Spawner** | Hard | Reads `spawn_rate_multiplier`, `speed_multiplier`, `hazard_ratio_modifier` | Designed |

### External Dependencies

None. Pure math — no engine-specific APIs beyond `ease()` and `lerp()`.

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `RAMP_DURATION` | float | 120.0 | 60 - 300 | How long until max difficulty | Too short: overwhelming before flow state. Too long: boring mid-game. |
| `EASE_CURVE` | float | 2.0 | 1.0 - 4.0 | Shape of the ramp | 1.0: linear, no gentle start. 4.0+: nothing happens for 80% of the run then spikes. |
| `MAX_SPAWN_RATE_MULT` | float | 2.5 | 1.5 - 4.0 | How many items at max difficulty | Too high: screen overload. Too low: no pressure increase. |
| `MAX_SPEED_MULT` | float | 1.8 | 1.3 - 2.5 | How fast items fall at max | Above 2.5: unreactable. Below 1.3: speed barely changes. |
| `MIN_HAZARD_RATIO` | float | 0.3 | 0.1 - 0.5 | Starting hazard proportion | Below 0.1: almost all coins (too easy). Above 0.5: stressful from start. |
| `MAX_HAZARD_RATIO` | float | 0.7 | 0.5 - 0.9 | Max hazard proportion | Above 0.8: almost all hazards (frustrating). Below 0.5: never feels dangerous. |

**Interaction warning**: All three multipliers compound. Max spawn rate * max speed * max hazard ratio together determine the peak difficulty "feel." Tune them as a set, not individually.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Difficulty starts at 0% (t=0) on run start | Log t value; verify 0.0 at frame 1. |
| 2 | Difficulty reaches 100% (t=1.0) at exactly RAMP_DURATION seconds | Log t value; verify 1.0 at 120s. |
| 3 | Ease-in curve is applied (early game ramps slowly) | Log t values at 30s intervals; verify quadratic progression matching the formula table. |
| 4 | All three multipliers update correctly each frame | Log multipliers; compare to expected values from formula table. |
| 5 | Difficulty resets to 0 on new run | End run, start new run; verify t=0 and all multipliers at minimum. |
| 6 | Difficulty does not decrease within a run under any circumstance | Play for 120+ seconds; verify multipliers only increase or hold. |
| 7 | System processing costs <0.01ms per frame | Profile; it's just math — should be near-zero. |
