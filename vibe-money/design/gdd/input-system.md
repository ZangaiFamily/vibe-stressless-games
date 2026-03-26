# Input System

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Effortless to Play

## Overview

The Input System abstracts all player input — touch, mouse, keyboard, and gamepad — into a single normalized horizontal movement value ranging from -1.0 (full left) to +1.0 (full right). It is the sole interface between the player's physical controls and the game world. The system exists to ensure the game feels identically responsive across every platform with zero configuration, honoring the "Effortless to Play" pillar: one axis of movement, pick up and play in 2 seconds, no tutorials needed. Without this system, every gameplay system would need to handle raw input devices directly, creating fragile platform-specific code.

## Player Fantasy

The Input System is invisible infrastructure — a player should never think about "the controls." The fantasy it serves is **effortless flow**: the character moves where you want, the instant you want, with zero friction. On mobile, it should feel like dragging a coin across a table with your thumb. On keyboard, it should feel like the character is magnetically attached to your intent. The moment a player wonders "how do I move?" or fights the controls, this system has failed. Success means the controls disappear — all the player feels is the rain, the coins, and the vibe.

## Detailed Design

### Core Rules

1. **Single output**: The system produces one value per frame: `input_direction` — a float from -1.0 (full left) to +1.0 (full right). 0.0 means no movement.
2. **Four input providers**, processed in priority order (highest priority wins if multiple are active):
   - **Touch (drag-to-slide)**: On touch-down, record the X position as `drag_origin`. Each frame, `input_direction = clamp((touch_x - drag_origin) / drag_sensitivity, -1.0, 1.0)`. On touch-up, `input_direction = 0.0`. The drag origin resets on each new touch.
   - **Mouse**: Same as touch — mouse button down starts drag, horizontal delta drives movement. Primarily for PC playtesting.
   - **Keyboard**: A/Left Arrow = -1.0, D/Right Arrow = +1.0. Both pressed = 0.0. No analog range — digital snap.
   - **Gamepad**: Left stick X axis maps directly to `input_direction`. Deadzone applied (see Tuning Knobs).
3. **No vertical input**: The system intentionally ignores all vertical input. There is no jump, no duck, no vertical axis.
4. **Always active**: Input is processed every frame during gameplay. No input lock, no cutscenes, no states where the player loses control (exception: run-end screen).
5. **Platform auto-detection**: The system detects available input devices at startup and enables the relevant providers. No manual configuration by the player.

### States and Transitions

| State | Description | Transitions To | Input Processed? |
|-------|-------------|----------------|-----------------|
| **Idle** | No input detected | Active (any input received) | Yes (returns 0.0) |
| **Active** | Player is providing directional input | Idle (input released / returns to center) | Yes (returns -1.0 to 1.0) |
| **Disabled** | Run ended, summary screen showing | Idle (new run starts) | No (returns 0.0, ignores all input) |

Only two real states — the system is either listening or not. No complex state machine.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Player Controller** | Downstream | Reads `input_direction` each frame | The Player Controller is the sole consumer. It converts `input_direction` into character velocity. |
| **Run Manager** | Downstream | Sends `disable()` / `enable()` signals | Run Manager disables input on game over, re-enables on run start. |
| **HUD** | None | No interaction | HUD reads score/streak, not input. |

## Formulas

### Drag-to-Direction (Touch/Mouse)

```
input_direction = clamp((current_x - drag_origin_x) / DRAG_SENSITIVITY, -1.0, 1.0)
```

| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `current_x` | float | Current touch/mouse X position in screen pixels | 0 to screen_width |
| `drag_origin_x` | float | X position where the touch began | 0 to screen_width |
| `DRAG_SENSITIVITY` | float | Pixels of drag needed to reach full speed | 50 - 200 (default: 100) |
| `input_direction` | float | Output: normalized horizontal direction | -1.0 to 1.0 |

**Example**: Screen width 1080px. Player touches at x=540, drags to x=640. With DRAG_SENSITIVITY=100: `(640-540)/100 = 1.0` — full right.

### Gamepad Deadzone

```
if abs(raw_stick_x) < STICK_DEADZONE:
    input_direction = 0.0
else:
    input_direction = (raw_stick_x - sign(raw_stick_x) * STICK_DEADZONE) / (1.0 - STICK_DEADZONE)
```

| Variable | Type | Description | Range |
|----------|------|-------------|-------|
| `raw_stick_x` | float | Raw left stick horizontal value | -1.0 to 1.0 |
| `STICK_DEADZONE` | float | Ignore input below this threshold | 0.05 - 0.3 (default: 0.15) |

This remaps the post-deadzone range to 0.0-1.0 so the player gets the full speed range after passing the deadzone threshold.

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Multi-touch** | Only the first touch is tracked. Additional fingers are ignored. | Prevents accidental two-finger input from fighting itself. |
| **Touch starts off-screen / in UI area** | If touch begins on a UI element (pause button, etc.), the input system does not claim it. Touch must begin in the gameplay area. | Prevents drag-to-move from hijacking UI taps. |
| **Drag origin drift** | Drag origin does NOT drift or recenter over time. It stays where the finger first touched until lift. | Drifting origin causes the "treadmill" feel where you keep sliding your finger. Fixed origin is more predictable. |
| **Screen resize / orientation change** | `DRAG_SENSITIVITY` is defined in physical pixels, not relative to screen width. On wider screens, the same finger distance produces the same result. | Consistent feel across devices. May need per-DPI tuning — flag as tuning knob. |
| **Gamepad connected mid-run** | Hot-plug supported. Gamepad input is accepted immediately. No restart required. | Godot handles device connection events natively. |
| **Gamepad disconnected mid-run** | Input falls back to keyboard/touch. `input_direction` returns to 0.0 for one frame (the frame the gamepad disconnects). | Graceful degradation. One-frame zero is imperceptible. |
| **All inputs simultaneous** | Priority: Touch > Gamepad > Keyboard. Highest-priority active provider wins. | Touch is most intentional (requires physical contact), so it takes priority. |
| **Keyboard both-keys-pressed** | A + D or Left + Right simultaneously = `input_direction = 0.0`. | Standard convention. Player is likely lifting one key while pressing another — brief zero is fine. |
| **Input during Disabled state** | All input is consumed and discarded. `input_direction` stays 0.0. | Prevents buffered input from causing movement on the next run start. |

## Dependencies

### Upstream (this system depends on)

None. The Input System is a foundation-layer system with zero dependencies.

### Downstream (these systems depend on this)

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Player Controller** | Hard | Reads `input_direction: float` every `_physics_process` frame | Not yet designed |

### External Dependencies

| Dependency | Notes |
|------------|-------|
| **Godot Input singleton** | Uses `Input.get_action_strength()` for keyboard/gamepad, `InputEventScreenTouch`/`InputEventScreenDrag` for touch |
| **Godot Input Map** | Requires actions defined: `move_left`, `move_right` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `DRAG_SENSITIVITY` | float | 100.0 | 50 - 200 | Pixels of drag needed for full speed | Too low: twitchy, overshoots. Too high: sluggish, can't reach edges. |
| `STICK_DEADZONE` | float | 0.15 | 0.05 - 0.3 | Gamepad stick dead zone threshold | Too low: drift when stick is at rest. Too high: requires large stick movement to register. |
| `INPUT_SMOOTHING` | float | 0.0 | 0.0 - 0.5 | Lerp factor applied to `input_direction` between frames (0 = no smoothing, raw input) | Too high: input feels laggy/delayed. Any value >0 adds perceived latency. Start at 0 and only add if raw input feels jittery on specific devices. |

**Interaction warning**: `DRAG_SENSITIVITY` and the Player Controller's `MOVE_SPEED` are tightly coupled. Changing one without the other will make movement feel wrong. When tuning, adjust `DRAG_SENSITIVITY` first (how fast input reaches 1.0), then tune `MOVE_SPEED` (how fast 1.0 moves the character).

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Keyboard left/right moves character at full speed with no perceptible input lag (<1 frame) | Press A/D, observe immediate movement via frame-by-frame recording |
| 2 | Touch drag-to-slide produces smooth, proportional movement from 0 to full speed | Touch and slowly drag; confirm character speed scales linearly with drag distance |
| 3 | Gamepad left stick produces smooth analog movement with no drift at rest | Leave stick at neutral for 10 seconds; confirm character position unchanged |
| 4 | Releasing all input returns `input_direction` to 0.0 within one frame | Release touch/key/stick, confirm character stops within one physics frame |
| 5 | Multi-touch does not cause erratic movement | Touch with two fingers simultaneously; confirm only first touch is tracked |
| 6 | Input is ignored during Disabled state (run-end screen) | During summary screen, press keys / touch / move stick; confirm no character movement |
| 7 | Input provider priority works: Touch > Gamepad > Keyboard | Provide input on multiple devices simultaneously; confirm highest-priority wins |
| 8 | Gamepad hot-plug works without restart | Connect gamepad mid-run; confirm it works immediately |
| 9 | Input processing completes within 0.1ms per frame | Profile `_physics_process`; confirm negligible frame budget usage |
| 10 | No input configuration is required by the player — it works on first launch | Fresh install on PC and mobile; confirm movement works with zero setup |

