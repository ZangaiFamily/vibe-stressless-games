# Run Manager

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Respect the Player's Time

## Overview

The Run Manager orchestrates the lifecycle of a single gameplay run — from start to game over to summary. It is the central coordinator that tells other systems when to activate, when to stop, and when to reset. On run start, it resets all gameplay systems (score, lives, streak, difficulty, spawner) and enables input. On run end (triggered by `lives_depleted` from the Lives System), it disables input, stops the spawner, transitions the Audio Manager to summary state, and hands final stats to the Run Summary Screen. It also tracks run metadata: elapsed time, final score, longest streak. The player experiences this system as the seamless transition between "playing" and "seeing my results."

## Player Fantasy

The run should feel like a complete micro-experience with a clear beginning, middle, and end. Pressing "play" drops you instantly into the action — no loading, no countdown (or a very brief "3-2-1" if testing shows it's needed). Game over transitions smoothly into the summary — the rain keeps falling, the music keeps playing, and your stats appear. The "one more run" button is right there. The Run Manager's job is to make this loop feel frictionless: play → results → play again, with zero dead time.

## Detailed Design

### Core Rules

1. **Run lifecycle**:
   - **Pre-run**: Player is on menu or summary screen. Gameplay systems inactive.
   - **Run start**: On player input (tap "Play" or "Retry"), emit `run_started` signal. All gameplay systems initialize/reset.
   - **During run**: Elapsed timer ticks. Systems operate normally.
   - **Run end**: On `lives_depleted` signal, emit `run_ended(run_stats)`. All gameplay systems stop. Summary screen appears.

2. **Run stats collected**:
   - `final_score: int` — from Score System
   - `longest_streak: int` — tracked by listening to `streak_changed` and recording the max
   - `coins_collected: int` — count of `item_collected` signals
   - `run_duration: float` — elapsed seconds
   - `is_high_score: bool` — compared against stored best (MVP: session-only, no persistence)

3. **System coordination on run_started**:
   - Input System → `enable()`
   - Player Controller → `enable()`, reset position to center
   - Score System → reset to 0
   - Lives System → reset to MAX_LIVES
   - Streak Multiplier → reset to 0
   - Difficulty Curve → reset to t=0
   - Item Spawner → `start()`
   - Audio Manager → `set_state(Gameplay)`

4. **System coordination on run_ended**:
   - Input System → `disable()`
   - Item Spawner → `stop()`, clear all active items
   - Audio Manager → `set_state(Summary)`
   - Run Summary Screen → display with `run_stats`

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Idle** | Menu or between runs | Running (play pressed) |
| **Running** | Active gameplay | Ended (lives depleted) |
| **Ended** | Summary screen showing | Idle (player dismisses), Running (retry pressed) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Lives System** | Upstream | `lives_depleted` signal triggers run end | Hard dep |
| **Score System** | Reads | `final_score` on run end | Hard dep |
| **Streak Multiplier** | Reads | Tracks `longest_streak` via `streak_changed` signal | Soft dep |
| **Difficulty Curve** | Downstream | `start()` / `stop()` | Hard dep |
| **Item Spawner** | Downstream | `start()` / `stop()` | Hard dep |
| **Input System** | Downstream | `enable()` / `disable()` | Hard dep |
| **Player Controller** | Downstream | `enable()` / `disable()` | Hard dep |
| **Audio Manager** | Downstream | `set_state()` | Soft dep |
| **Run Summary Screen** | Downstream | `run_stats` data | Hard dep |

## Formulas

```
run_duration = current_time - run_start_time
is_high_score = final_score > session_best_score
```

No complex math. This system is coordination, not calculation.

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Player presses retry during run-end transition** | Input is buffered. Retry only processes after summary screen is fully displayed. | Prevents accidental skip of results. |
| **Run duration = 0 (instant death)** | Valid. Summary shows 0s, 0 score. | Edge case from testing with MAX_LIVES=0 or instant hazard spawn. |
| **lives_depleted fires multiple times** | Only first signal is processed. Subsequent signals ignored in Ended state. | Prevents double game-over from simultaneous hazard hits. |
| **System fails to reset** | Each system's `reset()` is called independently. If one fails, others still reset. Log error for the failed system. | Defensive — don't let one broken system cascade. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Lives System** | Hard | `lives_depleted` signal | Designed |
| **Score System** | Hard | `final_score` read | Designed |
| **Streak Multiplier** | Soft | `streak_changed` for longest tracking | Designed |

### Downstream (coordinates)
| System | Dep Type | Notes |
|--------|----------|-------|
| **Input System** | Hard | enable/disable |
| **Player Controller** | Hard | enable/disable/reset |
| **Item Spawner** | Hard | start/stop |
| **Difficulty Curve** | Hard | start/stop |
| **Audio Manager** | Soft | state transitions |
| **Run Summary Screen** | Hard | displays results |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `SUMMARY_DELAY` | float | 0.5 | 0.0 - 2.0 | Seconds between game over and summary appearing | 0: jarring instant transition. Too long: boring wait. |
| `RETRY_COOLDOWN` | float | 0.3 | 0.0 - 1.0 | Min seconds before retry can be pressed | 0: accidental immediate retry. Too long: friction. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | All gameplay systems reset correctly on run start | Start a new run after a previous run; verify score=0, lives=3, streak=0, difficulty=0. |
| 2 | Run ends when lives reach 0 | Hit 3 hazards; verify transition to summary. |
| 3 | Run stats (score, streak, duration, coins) are correct on summary | Play a run, note values during play, verify summary matches. |
| 4 | High score detection works within session | Score 100, then 200; verify second run shows "High Score!" |
| 5 | Retry from summary starts a clean new run | Press retry; verify full reset. |
| 6 | No gameplay systems are active during summary | During summary, verify no items spawning, no input processing. |
| 7 | Run start to first input accepted takes <100ms | Measure time from play button to character responding. |
