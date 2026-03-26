# Run Summary Screen

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Respect the Player's Time, Juicy Feedback

## Overview

The Run Summary Screen displays the player's performance after each run ends. It receives `run_stats` from the Run Manager and presents: final score, longest streak, coins collected, run duration, and whether a new high score was achieved. The screen provides a "Retry" button for immediate replay and a "Menu" button to return to the main menu. It appears with a smooth overlay transition — the gameplay scene remains visible but dimmed beneath the summary. The rain keeps falling. The music keeps playing (ducked). The summary should feel like a natural pause in the experience, not an interruption.

## Player Fantasy

The summary is your moment of reflection. The numbers count up satisfyingly — score tallies from 0, coins clink as they're counted, your longest streak is highlighted. If you beat your high score, there's a special glow. But it doesn't overstay its welcome — the "Retry" button is prominent and immediate. One tap and you're back in the rain. The summary rewards your run without creating friction between "just one more."

## Detailed Design

### Core Rules

1. **Data displayed**:
   | Stat | Source | Format | Animation |
   |------|--------|--------|-----------|
   | Final Score | `run_stats.final_score` | Number with commas | Counts up from 0 over 1 second |
   | Longest Streak | `run_stats.longest_streak` | "Best Streak: 23" | Pops in after score finishes |
   | Coins Collected | `run_stats.coins_collected` | "42 coins" | Pops in |
   | Run Duration | `run_stats.run_duration` | "2:15" (mm:ss) | Pops in |
   | High Score | `run_stats.is_high_score` | "NEW HIGH SCORE!" banner | Glow animation if true |

2. **Layout**: Centered panel with semi-transparent dark overlay behind it. Stats arranged vertically. "Retry" button prominent at bottom-center. "Menu" button smaller, below or beside Retry.

3. **Appear transition**: Panel slides up from bottom (or fades in) over `APPEAR_DURATION` seconds. Gameplay scene stays visible but darkened beneath.

4. **Score count-up**: Final score animates from 0 to actual value over `COUNT_UP_DURATION` seconds using ease-out curve. The counting sound (soft rapid ticking) plays during count-up.

5. **Retry flow**: Tapping "Retry" dismisses the summary and immediately starts a new run (Run Manager handles the reset). No confirmation dialog.

6. **Menu flow**: Tapping "Menu" returns to the main menu / idle state.

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Hidden** | Not visible | Appearing (run_ended received) |
| **Appearing** | Slide-in animation playing | Displayed (animation complete) |
| **Displayed** | Fully visible, interactive | Hidden (Retry or Menu pressed) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Run Manager** | Upstream | `run_ended(run_stats)` signal with stat data | Hard dep |
| **Audio Manager** | Downstream | Count-up tick SFX, high score celebration SFX | Soft dep |
| **Run Manager** | Downstream | "Retry" triggers `start_new_run()`, "Menu" triggers `return_to_menu()` | Hard dep |

## Formulas

### Score Count-Up

```
displayed_score = int(lerp(0, final_score, ease_out(elapsed / COUNT_UP_DURATION)))
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `COUNT_UP_DURATION` | float | 1.0 | 0.5 - 2.0 | Seconds for score to count from 0 to final |
| `APPEAR_DURATION` | float | 0.3 | 0.2 - 0.5 | Panel slide-in animation time |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Score = 0** | Count-up is instant (nothing to count). Stats still display normally. | Don't animate counting to 0. |
| **Very high score (100,000+)** | Count-up speed auto-adjusts to always take COUNT_UP_DURATION. Font auto-scales. | Consistent timing regardless of score magnitude. |
| **Retry pressed during count-up** | Count-up stops, summary dismissed, new run starts. | Don't make the player wait for an animation. |
| **Multiple run_ended signals** | Only first is processed. | Per Run Manager edge case. |
| **No high score data (first run)** | First run is always a high score. | `session_best` starts at 0. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Run Manager** | Hard | `run_ended(run_stats)` | Designed |

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Run Manager** | Hard | Retry/Menu button actions | Designed |
| **Audio Manager** | Soft | Count-up and celebration SFX | Designed |

### External Dependencies
| Dependency | Notes |
|------------|-------|
| **Godot Control/Panel** | UI container |
| **Godot Tween** | Count-up and slide animations |
| **Godot Button** | Retry and Menu buttons |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `COUNT_UP_DURATION` | float | 1.0 | 0.5 - 2.0 | Score counting animation speed | Too fast: no drama. Too slow: boring wait. |
| `APPEAR_DURATION` | float | 0.3 | 0.2 - 0.5 | Panel slide-in speed | Too fast: jarring. Too slow: sluggish. |
| `OVERLAY_OPACITY` | float | 0.6 | 0.3 - 0.8 | Background dim amount | Too low: summary hard to read. Too high: can't see rain/world. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Summary appears after game over with correct stats | Complete a run; verify all displayed stats match gameplay. |
| 2 | Score counts up from 0 to final value with animation | Watch count-up; verify smooth number increase over ~1 second. |
| 3 | "NEW HIGH SCORE!" appears on first run and when beating previous best | Score 100, retry, score 200; verify high score banner on second run. |
| 4 | Retry button starts a new run immediately | Press Retry; verify new run begins with full reset. |
| 5 | Rain and music continue during summary | Observe summary screen; verify rain visible through overlay and music playing. |
| 6 | Summary panel doesn't obstruct the rain/world feel | Verify semi-transparent overlay, not opaque. |
| 7 | Retry pressed during count-up skips animation and starts run | Press Retry during count-up; verify immediate new run. |
