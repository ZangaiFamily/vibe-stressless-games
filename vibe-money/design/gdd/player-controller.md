# Player Controller

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Effortless to Play, Juicy Feedback

## Overview

The Player Controller converts the Input System's normalized direction (-1.0 to 1.0) into physical character movement within the game world. It owns the player character's position, velocity, and collision boundaries — the player moves left and right along the bottom of the screen to catch coins and dodge hazards. The controller enforces screen boundaries so the character cannot leave the play area, applies acceleration and deceleration for smooth movement feel, and exposes the character's collision area for the Collection & Avoidance system. The player actively controls this system every moment of gameplay. Without it, input would have no effect on the world.

## Player Fantasy

The character is you — or rather, your thumb. Movement should feel like an extension of your body, not like pushing a game piece around a board. When you slide right, the character glides right with weight and momentum but no delay. When you stop, the character settles into place with a gentle deceleration — not an abrupt halt, not a long slide. The fantasy is **graceful, grounded movement in a cozy world**: you're a person standing in the rain, shifting your weight to catch what falls. The movement itself should feel pleasant — smooth enough to be meditative, responsive enough to be precise when a gold coin falls between two bombs.

## Detailed Design

### Core Rules

1. **Horizontal movement only**: The player character moves along the X axis at a fixed Y position near the bottom of the screen. No jumping, no vertical movement.

2. **Velocity-based movement**: Each `_physics_process` frame:
   - Read `input_direction` from the Input System (-1.0 to 1.0)
   - Calculate `target_velocity = input_direction * MOVE_SPEED`
   - Accelerate toward `target_velocity` using `ACCELERATION` (when input is active) or decelerate toward 0 using `DECELERATION` (when input is released)
   - Apply velocity to position: `position.x += velocity.x * delta`

3. **Screen boundary clamping**: The character's position is clamped so the character sprite stays fully within the viewport. Boundaries are calculated from the viewport width minus half the character's collision width.

4. **Collision shape**: The player has a circular collision area (matching the umbrella/character visual) used by the Collection & Avoidance system to detect overlaps with falling items. The Player Controller owns this shape but does not process collisions itself.

5. **Fixed Y position**: The character's Y position is set once at spawn (e.g., 85% of viewport height from top) and never changes during gameplay.

6. **CharacterBody2D**: Implemented as a Godot `CharacterBody2D` node, using `move_and_slide()` for built-in collision handling. However, since movement is horizontal-only with screen-edge clamping, physics collisions are minimal — the collision shape is primarily for item overlap detection via `Area2D`.

### States and Transitions

| State | Description | Movement | Transitions To |
|-------|-------------|----------|---------------|
| **Moving** | `input_direction != 0` | Accelerating toward `target_velocity` | Stopping (input released) |
| **Stopping** | `input_direction == 0`, `velocity != 0` | Decelerating toward 0 | Idle (velocity reaches ~0), Moving (new input) |
| **Idle** | `input_direction == 0`, `velocity == 0` | None | Moving (input received) |
| **Disabled** | Run ended / not in gameplay | Frozen, no processing | Idle (new run starts) |

Transitions are implicit — no explicit state machine needed. The acceleration/deceleration math handles Moving ↔ Stopping ↔ Idle naturally.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Input System** | Upstream | Reads `input_direction: float` each `_physics_process` | Hard dependency — confirmed by Input System GDD |
| **Collection & Avoidance** | Downstream | Exposes player's `Area2D` collision shape and position | C&A detects when falling items overlap the player's area |
| **Game Juice System** | Downstream | Emits `player_moved(velocity)` signal | For subtle movement-based effects (umbrella tilt, footstep dust) |
| **Run Manager** | Upstream | Receives `disable()` / `enable()` | Freezes/unfreezes the controller between runs |

**Cross-reference with Input System GDD**: The Input System specifies that `input_direction` is read in `_physics_process` and that the Player Controller is the "sole consumer." This design honors that contract.

## Formulas

### Movement Per Frame

```
target_velocity = input_direction * MOVE_SPEED

if input_direction != 0:
    velocity.x = move_toward(velocity.x, target_velocity, ACCELERATION * delta)
else:
    velocity.x = move_toward(velocity.x, 0.0, DECELERATION * delta)

position.x = clamp(position.x, LEFT_BOUND, RIGHT_BOUND)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `input_direction` | float | — | -1.0 to 1.0 | From Input System |
| `MOVE_SPEED` | float | 400.0 | 200 - 800 | Max horizontal speed in px/sec |
| `ACCELERATION` | float | 2000.0 | 800 - 4000 | How fast the character reaches max speed (px/sec²) |
| `DECELERATION` | float | 1800.0 | 800 - 4000 | How fast the character stops (px/sec²) |
| `velocity.x` | float | 0.0 | -MOVE_SPEED to MOVE_SPEED | Current horizontal velocity |
| `LEFT_BOUND` | float | computed | — | `0 + collision_width / 2` |
| `RIGHT_BOUND` | float | computed | — | `viewport_width - collision_width / 2` |

**Example timeline** (with defaults, at 60fps, delta = 0.0167):
- Frame 0: Input = 1.0, velocity = 0 → accelerates by 33.3 px/sec → velocity = 33.3
- Frame 6 (~0.1s): velocity ≈ 200 (half speed)
- Frame 12 (~0.2s): velocity = 400 (full speed reached)
- Input released: decelerates by 30 px/sec per frame → stops in ~13 frames (~0.22s)

Time to full speed: **~0.2 seconds**. Time to stop: **~0.22 seconds**. Both short enough to feel responsive, long enough to feel smooth.

### Screen Boundary

```
LEFT_BOUND = SCREEN_MARGIN + collision_width / 2
RIGHT_BOUND = viewport_width - SCREEN_MARGIN - collision_width / 2
```

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `SCREEN_MARGIN` | float | 8.0 | Padding from viewport edge in pixels |
| `collision_width` | float | 32.0 | Player collision circle diameter |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Character at screen edge + input toward edge** | Position stays clamped at boundary. Velocity is set to 0 when at boundary and still pushing. | Prevents "stuck" feel — releasing input from an edge doesn't cause a deceleration slide in the wrong direction. |
| **Rapid direction reversal (left → right instantly)** | Acceleration applies from current velocity. Character decelerates through 0 then accelerates in new direction. With defaults, full reversal takes ~0.4s. | Feels intentional and weighty without being sluggish. |
| **Very small input_direction (e.g., 0.05 from gamepad)** | `target_velocity = 0.05 * 400 = 20 px/sec`. Character moves very slowly. Valid behavior — analog input should produce analog speed. | Supports the gamepad's analog range. |
| **Delta spike (frame hitch)** | `move_toward` uses `delta`, so a long frame produces a proportionally larger velocity change. Position clamping prevents overshooting the screen. | Frame-rate independent movement. |
| **Viewport resize during gameplay** | Boundaries recalculate on next frame. Character position re-clamps if now outside bounds. | Handles window resizing on PC. |
| **Disabled state entered while moving** | Velocity is immediately set to 0. No deceleration slide after game over. | Clean stop prevents the character from drifting during the summary screen. |
| **Re-enabled after disabled** | Position resets to center of screen. Velocity = 0. | Fresh start for new run. |

## Dependencies

### Upstream (this system depends on)

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Input System** | Hard | Reads `input_direction: float` every `_physics_process` frame | Designed ([input-system.md](input-system.md)) |

### Downstream (these systems depend on this)

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Collection & Avoidance** | Hard | Reads player `Area2D` position and collision shape for overlap detection | Not yet designed |
| **Game Juice System** | Soft | Listens to `player_moved(velocity)` signal for movement-based effects | Not yet designed |

### External Dependencies

| Dependency | Notes |
|------------|-------|
| **Godot CharacterBody2D** | Base node type for the player |
| **Godot Area2D** | Child node for item collection/hit detection |
| **Viewport** | Reads `get_viewport_rect().size` for boundary calculation |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `MOVE_SPEED` | float | 400.0 | 200 - 800 | Maximum horizontal speed (px/sec) | Too low: can't reach coins at screen edge. Too high: overshoots targets, feels twitchy. |
| `ACCELERATION` | float | 2000.0 | 800 - 4000 | Time to reach full speed | Too low: sluggish, unresponsive. Too high: effectively instant (defeats the purpose of accel). |
| `DECELERATION` | float | 1800.0 | 800 - 4000 | Time to stop after input release | Too low: long slide, imprecise. Too high: abrupt stop, feels mechanical. |
| `PLAYER_Y_PERCENT` | float | 0.85 | 0.7 - 0.95 | Vertical position as fraction of viewport height | Too high: character clips bottom. Too low: too much empty space below, reduces reaction time to items. |
| `COLLISION_RADIUS` | float | 16.0 | 10 - 32 | Player collection/hit detection radius | Too small: frustrating misses. Too large: no skill expression, catches everything. |
| `SCREEN_MARGIN` | float | 8.0 | 0 - 32 | Padding from viewport edge | 0: character visually clips edge. Too high: reduced play area. |

**Interaction warnings:**
- `MOVE_SPEED` is tightly coupled with Input System's `DRAG_SENSITIVITY` (per Input System GDD). Tune `DRAG_SENSITIVITY` first, then `MOVE_SPEED`.
- `COLLISION_RADIUS` must stay proportional to item hitbox radii in the Item Database (8-32px range). If player radius is much larger than item radii, collection feels automatic.
- `ACCELERATION` and `DECELERATION` together determine the movement "feel." Roughly equal values feel natural. Very different values (high accel, low decel) create a "skating" feel.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Character moves left/right in response to Input System's `input_direction` | Press A/D or drag touch; confirm character moves in correct direction. |
| 2 | Movement has visible acceleration (not instant snap to full speed) | Hold input from standstill; observe ~0.2s ramp-up to full speed. |
| 3 | Movement has visible deceleration (not instant stop) | Release input at full speed; observe ~0.22s gentle stop. |
| 4 | Character cannot leave the screen boundaries | Hold input toward edge for 5 seconds; character stays within viewport. |
| 5 | Analog input (gamepad stick) produces proportional speed | Tilt stick halfway; confirm character moves at roughly half `MOVE_SPEED`. |
| 6 | Character position resets to center on new run | Complete a run, start new run; confirm character is centered. |
| 7 | Character freezes immediately on disable (game over) | Hit third hazard; confirm character stops with no drift. |
| 8 | Movement is frame-rate independent | Test at 30fps and 60fps; confirm character covers same distance over same real-time interval. |
| 9 | Player collision area correctly sized at `COLLISION_RADIUS` | Visualize collision shape in debug mode; confirm it matches expected radius. |
| 10 | Movement processing completes in <0.1ms per frame | Profile `_physics_process`; confirm negligible frame budget usage. |
