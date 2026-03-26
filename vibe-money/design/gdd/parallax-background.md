# Parallax Background

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Vibe First

## Overview

The Parallax Background renders the game's layered city backdrop — a silhouette skyline with softly glowing windows, distant neon signs, and atmospheric depth. Multiple layers scroll at different speeds in response to player movement, creating a subtle parallax depth effect that makes the 2D world feel three-dimensional. The background is purely decorative with no gameplay interaction. It sets the mood: a rainy night in a warm, glowing city.

## Player Fantasy

You're standing on a rooftop. Behind you, the city stretches into the distance — buildings at different depths, some close with visible windows, others just distant silhouettes against a purple-gray sky. When you move, the world shifts gently — closer buildings move more, distant ones barely budge. It's a living diorama. The background is the "world" that makes the rain and coins feel grounded in a place, not floating in a void.

## Detailed Design

### Core Rules

1. **Layered composition** (back to front):
   - **Sky gradient**: Static. Deep purple-to-dark-blue gradient. No movement.
   - **Far buildings**: Silhouettes, very slow parallax (5% of player movement)
   - **Mid buildings**: More detailed silhouettes with glowing windows, moderate parallax (15%)
   - **Near buildings**: Largest, most detailed, strongest parallax (30%). Player and items render in front of this.
   - **Rain layers** render between mid and near buildings (handled by Rain VFX System)

2. **Parallax response**: Each layer's X offset = `player_x_normalized * layer_parallax_factor * MAX_PARALLAX_OFFSET`. When the player is centered, layers are at their default position. When the player moves right, layers shift left (proportionally to their depth).

3. **Glowing windows**: Mid and near building layers include small rectangles with a warm yellow/orange emissive glow. Windows pulse very subtly (brightness oscillation over 3-6 seconds) to feel alive. Window glow is achieved via a simple shader or animated sprite.

4. **Static Y position**: Background layers do not scroll vertically. There is no vertical parallax.

5. **Seamless tiling**: Each layer tiles horizontally so parallax scrolling never reveals an edge, even at maximum player offset.

### States and Transitions

Stateless. Always visible. No transitions needed.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Player Controller** | Upstream reads | Reads player X position for parallax offset | Soft dep — background works at static position without player data |
| **Rain VFX System** | Sibling | Rendering order coordination only | Rain renders between background layers |
| **Environment Manager** | Upstream (Alpha) | Swaps background asset sets for different environments | Not in MVP |

## Formulas

### Parallax Offset

```
layer_offset_x = (player_x / viewport_width - 0.5) * parallax_factor * MAX_PARALLAX_OFFSET
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `player_x` | float | — | 0 to viewport_width | Player horizontal position |
| `parallax_factor` | float | varies | 0.0 - 1.0 | Per-layer depth (far=0.05, mid=0.15, near=0.30) |
| `MAX_PARALLAX_OFFSET` | float | 50.0 | 20 - 100 | Max pixels of shift at screen edge |

### Window Glow Pulse

```
glow_intensity = BASE_GLOW + sin(time * TAU / GLOW_CYCLE) * GLOW_VARIANCE
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_GLOW` | float | 0.7 | 0.5 - 1.0 | Base window brightness |
| `GLOW_CYCLE` | float | 4.0 | 2 - 8 | Seconds per pulse cycle (randomized per window) |
| `GLOW_VARIANCE` | float | 0.15 | 0.0 - 0.3 | Brightness oscillation amount |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Player at extreme edge** | Parallax offset maxes at `MAX_PARALLAX_OFFSET`. No layer clipping due to seamless tiling. | Tiling prevents visual artifacts. |
| **No player data available (menu)** | Background renders at center position (offset = 0). | Default state before gameplay. |
| **Viewport resize** | Layers scale to fit. Parallax calculation uses current viewport width. | Responsive design. |

## Dependencies

### Upstream
None. Foundation-layer visual system.

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Environment Manager** | Soft (Alpha) | Swaps asset sets | Not in scope |

### External Dependencies
| Dependency | Notes |
|------------|-------|
| **Godot ParallaxBackground / ParallaxLayer** | Built-in parallax nodes |
| **Background art assets** | Silhouette sprites in `assets/art/backgrounds/` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `MAX_PARALLAX_OFFSET` | float | 50.0 | 20 - 100 | How much layers shift | Too low: no depth feel. Too high: distracting movement. |
| `FAR_PARALLAX` | float | 0.05 | 0.01 - 0.1 | Far layer movement ratio | |
| `MID_PARALLAX` | float | 0.15 | 0.05 - 0.3 | Mid layer movement ratio | |
| `NEAR_PARALLAX` | float | 0.30 | 0.1 - 0.5 | Near layer movement ratio | |
| `BASE_GLOW` | float | 0.7 | 0.5 - 1.0 | Window brightness base | |
| `GLOW_VARIANCE` | float | 0.15 | 0.0 - 0.3 | Window pulse intensity | 0: static windows. Too high: disco effect. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | At least 3 depth layers are visible with distinct parallax speeds | Move player left/right; observe different shift amounts per layer. |
| 2 | Background is visible on first frame of game launch | Launch game; verify no black/empty background. |
| 3 | Parallax responds to player movement | Move player; verify layers shift proportionally. |
| 4 | Window glow pulses subtly | Observe mid-layer buildings for 10 seconds; confirm glow oscillation. |
| 5 | No seams or edges visible at maximum parallax offset | Move player to screen edge; verify tiling is seamless. |
| 6 | Background rendering stays under 1ms GPU time | Profile on target hardware. |
