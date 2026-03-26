# Rain VFX System

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Vibe First

## Overview

The Rain VFX System renders a continuous particle rain effect across the entire screen. It is the primary visual element of the game's rainy-day aesthetic — the thing that makes Vibe Money look and feel like standing in the rain. The system uses Godot's `GPUParticles2D` to emit thousands of small, semi-transparent rain streaks falling at a slight angle, with subtle wind variation. Rain plays continuously from game launch through menus, gameplay, and summary screens — it never stops. The system also provides a "rain intensity" interface that the Game Juice System can modulate for emphasis moments (e.g., brief rain surge on streak milestone).

## Player Fantasy

The rain is the game's soul. It's the first thing you see, the last thing you see, and the thing that makes you want to stay. Each raindrop catches the ambient light — some are bright streaks, others are faint whispers. The rain should feel organic and alive, not like a grid of falling lines. When you're deep in a run and everything clicks, the rain is your companion. This system is the single biggest contributor to the "I want to put on headphones and just vibe" feeling.

## Detailed Design

### Core Rules

1. **Continuous emission**: Rain particles emit every frame, regardless of game state. The rain never pauses or stops.

2. **Particle properties**:
   - Shape: Thin vertical streak (elongated circle or line)
   - Direction: Slightly angled (5-15 degrees from vertical) to simulate gentle wind
   - Speed: Variable per particle (MIN_RAIN_SPEED to MAX_RAIN_SPEED) for depth illusion
   - Opacity: Variable (0.2 to 0.6) — faster/larger drops are more opaque (closer), slower/smaller are faint (farther)
   - Color: White to light blue, matching the ambient palette
   - Lifetime: Calculated so drops traverse the full screen height

3. **Layered depth**: Two particle emitters at different visual layers:
   - **Background rain**: Slower, smaller, fainter — appears behind the gameplay area
   - **Foreground rain**: Faster, larger, brighter — appears in front of the player (above gameplay layer)

4. **Wind variation**: A slow sine wave modulates the rain angle over time (`WIND_CYCLE_SECONDS`), creating subtle left-right drift that makes the rain feel alive.

5. **Rain intensity interface**: `set_intensity(value: float)` where 0.0 = light drizzle, 1.0 = normal, 2.0 = heavy downpour. Adjusts emission rate and particle size. Default gameplay = 1.0.

6. **Quality tiers**: For mobile/low-end devices:
   - **Full**: Both layers, max particle count
   - **Lite**: Foreground layer only, 50% particle count
   - **Minimal**: Single layer, 25% count, no wind variation

### States and Transitions

Stateless. Always emitting. Intensity can be modulated but the system is never off.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Game Juice System** | Upstream | `set_intensity(value)` for emphasis moments | Soft dep — rain works at default intensity without Juice |
| **Parallax Background** | Sibling | Rain renders between background layers and foreground | Rendering order coordination only, no data exchange |
| **Settings System** | Upstream (Vertical Slice) | Quality tier selection | Soft dep |

## Formulas

### Particle Count

```
active_particles = int(BASE_PARTICLE_COUNT * intensity * quality_multiplier)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_PARTICLE_COUNT` | int | 500 | 200 - 1000 | Particles per emitter at intensity 1.0 |
| `intensity` | float | 1.0 | 0.0 - 2.0 | From Game Juice System |
| `quality_multiplier` | float | 1.0 | 0.25 - 1.0 | From quality tier (Full=1.0, Lite=0.5, Minimal=0.25) |

### Wind Angle

```
wind_offset = sin(elapsed_time / WIND_CYCLE_SECONDS * TAU) * MAX_WIND_ANGLE
rain_angle = BASE_RAIN_ANGLE + wind_offset
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_RAIN_ANGLE` | float | 10.0 | 0 - 20 | Base angle from vertical (degrees) |
| `WIND_CYCLE_SECONDS` | float | 8.0 | 4 - 20 | Seconds for one full wind cycle |
| `MAX_WIND_ANGLE` | float | 5.0 | 0 - 15 | Maximum additional angle from wind |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Intensity set to 0** | No particles emit. Screen is dry. | Valid for testing or "clear sky" environment. |
| **Intensity set to 2.0+ (heavy rain)** | Double particles, larger size. May impact FPS on low-end. | Game Juice should only spike briefly (~0.5s). |
| **Viewport resize** | Emitter width adjusts to new viewport width. Particles already falling are unaffected. | Continuous coverage. |
| **Quality tier changes mid-game** | Particle count adjusts on next emission cycle. No jarring transition. | Smooth quality switching. |
| **Very low FPS (<30)** | Particle system is GPU-driven — maintains visual density even at low CPU FPS. | GPUParticles2D advantage over CPUParticles2D. |

## Dependencies

### Upstream
None. Foundation-layer visual system.

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Game Juice System** | Soft | Reads `set_intensity()` | Not yet designed |

### External Dependencies
| Dependency | Notes |
|------------|-------|
| **Godot GPUParticles2D** | Primary particle system |
| **Godot ParticleProcessMaterial** | Particle behavior configuration |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `BASE_PARTICLE_COUNT` | int | 500 | 200 - 1000 | Rain density | Too low: sparse, not rainy. Too high: GPU overload on mobile. |
| `MIN_RAIN_SPEED` | float | 300.0 | 100 - 500 | Slowest raindrop (background depth) | Too slow: looks like snow. |
| `MAX_RAIN_SPEED` | float | 800.0 | 500 - 1200 | Fastest raindrop (foreground) | Too fast: streaks become invisible. |
| `BASE_RAIN_ANGLE` | float | 10.0 | 0 - 20 | Base wind angle | 0: perfectly vertical (unnatural). >20: hurricane feel. |
| `WIND_CYCLE_SECONDS` | float | 8.0 | 4 - 20 | Wind variation speed | Too fast: jittery. Too slow: static feel. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Rain is visible immediately on game launch | Launch game; verify rain particles within first frame. |
| 2 | Rain plays continuously through all game states | Navigate menu → gameplay → summary; verify rain never stops. |
| 3 | Two depth layers are visually distinguishable | Observe background rain (faint, slow) vs foreground rain (bright, fast). |
| 4 | Wind variation is visible over 8-second cycle | Watch rain for 15 seconds; observe subtle angle shift. |
| 5 | `set_intensity(2.0)` produces visibly heavier rain | Call from debug; verify more/larger particles. |
| 6 | Lite quality tier runs at 60fps on target mobile device | Profile on low-end device with Lite mode. |
| 7 | Full quality stays under 2ms GPU time per frame | Profile GPUParticles2D render time on target PC. |
