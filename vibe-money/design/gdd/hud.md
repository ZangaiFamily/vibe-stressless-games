# HUD

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Effortless to Play, Juicy Feedback

## Overview

The HUD (Heads-Up Display) shows the player's current run status: score, streak count with multiplier, and remaining lives. It overlays the gameplay area without obstructing the action. The HUD updates in real-time by listening to signals from the Score System, Streak Multiplier, and Lives System. It is minimal by design — three pieces of information, no clutter — honoring the "Effortless to Play" pillar. The HUD also provides brief animated reactions (score punch, life icon shake) to reinforce the "Juicy Feedback" pillar.

## Player Fantasy

The HUD is a glanceable dashboard. You don't study it — you sense it in your peripheral vision. The score climbing in the corner, the streak counter building, the heart icons showing your safety margin. When you catch a coin, the score punches up briefly (scales larger then settles). When you lose a life, the heart icon shakes. The HUD tells you how you're doing without requiring you to think about it.

## Detailed Design

### Core Rules

1. **Layout** (positioned to avoid the gameplay center):
   - **Score**: Top-left. Large, clear number. Animates on change (punch scale).
   - **Streak + Multiplier**: Top-center. Shows "Streak: 12 (2.0x)" format. Glows when at 2x+.
   - **Lives**: Top-right. Heart icons (filled = alive, empty = lost). Icons shake on loss.

2. **Score display**: Listens to `score_changed(total, earned)`. On each change:
   - Update displayed number
   - Play punch animation (scale up to 1.2x then ease back to 1.0x over 0.15s)

3. **Streak display**: Listens to `streak_changed(count, multiplier)`:
   - Update streak count and multiplier text
   - At multiplier > 1.0x, text color shifts warmer (white → yellow → orange at 5x)
   - On streak reset: brief fade-to-gray animation

4. **Lives display**: Listens to `life_lost(current_lives, damage)`:
   - Remove one heart (animate: shrink + red flash)
   - Remaining hearts shake briefly

5. **Visibility**: HUD is visible only during gameplay state. Hidden during menu and faded during summary (score persists on summary as "Final Score").

6. **Touch-safe positioning**: On mobile, HUD elements are positioned away from the bottom 40% of the screen (the touch/drag area) to prevent finger occlusion.

### States and Transitions

| State | Description | Visible? |
|-------|-------------|----------|
| **Hidden** | Menu, pre-game | No |
| **Active** | During gameplay | Yes, all elements |
| **Summary** | Run-end screen | Score visible (as "Final"), others hidden |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Score System** | Upstream | `score_changed(total, earned)` signal | Hard dep |
| **Streak Multiplier** | Upstream | `streak_changed(count, multiplier)` signal | Hard dep |
| **Lives System** | Upstream | `life_lost(current_lives, damage)` signal | Hard dep |
| **Run Manager** | Upstream | State changes (Hidden ↔ Active ↔ Summary) | Hard dep |

## Formulas

### Score Punch Animation

```
scale = 1.0 + PUNCH_SCALE * (1.0 - elapsed / PUNCH_DURATION)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `PUNCH_SCALE` | float | 0.2 | 0.1 - 0.4 | Extra scale on score change (1.2x total at peak) |
| `PUNCH_DURATION` | float | 0.15 | 0.1 - 0.3 | Seconds for punch to settle |

### Streak Color Interpolation

```
color = lerp(WHITE, STREAK_MAX_COLOR, (multiplier - 1.0) / (MAX_MULTIPLIER - 1.0))
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `STREAK_MAX_COLOR` | Color | Orange (#FF8C00) | Color at maximum multiplier |
| `MAX_MULTIPLIER` | float | 5.0 | From Streak Multiplier system |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Score exceeds display width** | Score text auto-scales font size down to fit. | Prevents overflow for high scores. |
| **Streak 0 with 1.0x multiplier** | Display shows "Streak: 0 (1.0x)" in white. | Clear baseline state. |
| **All lives lost** | All hearts show empty. Brief delay before HUD transitions to Summary. | Player sees the empty hearts before summary — reinforces the game-over moment. |
| **Rapid score changes (5 coins in <1s)** | Each triggers a punch animation. Animations overlap — latest punch wins. | Prevents jittery rapid-fire scaling. |
| **Portrait vs landscape** | HUD repositions elements based on aspect ratio. Core layout remains top-edge. | Mobile orientation support. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Score System** | Hard | `score_changed` signal | Designed |
| **Streak Multiplier** | Hard | `streak_changed` signal | Designed |
| **Lives System** | Hard | `life_lost` signal | Designed |
| **Run Manager** | Hard | State transitions | Designed |

### Downstream
None. HUD is a terminal display system.

### External Dependencies
| Dependency | Notes |
|------------|-------|
| **Godot CanvasLayer** | Renders above gameplay on its own layer |
| **Godot Label / RichTextLabel** | Text rendering |
| **Godot TextureRect** | Heart icons |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `PUNCH_SCALE` | float | 0.2 | 0.1 - 0.4 | Score change animation intensity | Too low: unnoticeable. Too high: distracting. |
| `PUNCH_DURATION` | float | 0.15 | 0.1 - 0.3 | Animation settle time | Too short: barely visible. Too long: feels laggy. |
| `HUD_MARGIN` | float | 16.0 | 8 - 32 | Padding from screen edges | Too small: feels cramped. Too large: wastes space. |
| `SCORE_FONT_SIZE` | int | 32 | 24 - 48 | Score text size | Too small: unreadable at distance/mobile. Too large: obstructs gameplay. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Score, streak, and lives are all visible during gameplay | Start a run; verify all three elements displayed. |
| 2 | Score updates immediately on coin collection with punch animation | Catch a coin; observe number change and brief scale animation. |
| 3 | Streak counter increments and shows correct multiplier | Build streak to 5; verify "Streak: 5 (1.5x)" displayed. |
| 4 | Lives hearts decrease on hazard hit with shake animation | Hit a hazard; observe heart removal and shake. |
| 5 | HUD is hidden during menu state | View main menu; verify no HUD elements visible. |
| 6 | HUD elements don't overlap the gameplay area center | Verify all elements are in the top 15% of the screen. |
| 7 | Text is readable at target mobile screen sizes | Test on 5-inch phone; verify all text legible. |
