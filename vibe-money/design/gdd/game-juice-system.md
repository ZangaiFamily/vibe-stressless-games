# Game Juice System

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Juicy Feedback

## Overview

The Game Juice System is the feedback orchestrator — it listens for gameplay events (coin collected, hazard hit, streak milestone, life lost) and triggers coordinated visual and audio responses. For each event, it fires the appropriate combination of: particle burst, screen shake, score popup animation, sprite flash, Audio Manager SFX call, and Rain VFX intensity spike. The system does not own any gameplay logic — it purely transforms gameplay signals into sensory feedback. It is the primary implementor of the "Juicy Feedback" pillar: every action the player takes should FEEL good through layered, immediate, satisfying responses.

## Player Fantasy

Catching a coin isn't just "+10 points" — it's a burst of golden particles, a satisfying clink that rises in pitch, and a score number that punches up from the catch point. Hitting a hazard isn't just "-1 life" — it's a brief screen flash, a muffled thud, and a subtle camera shake. At streak milestones, the rain surges briefly, the screen glows warmer, and a chime flourish plays. The Game Juice System is the difference between a spreadsheet and a game — it makes numbers feel like experiences.

## Detailed Design

### Core Rules

1. **Event-to-feedback mapping**: The system subscribes to signals from Collection & Avoidance, Streak Multiplier, and Lives System. Each signal triggers a feedback preset:

   | Event Signal | Particles | Screen Shake | Score Popup | Sprite Flash | Audio Tag | Rain Spike |
   |-------------|-----------|-------------|-------------|-------------|-----------|-----------|
   | `item_collected` (bronze) | Small gold burst | None | "+10" float-up | None | `collect_bronze` | None |
   | `item_collected` (silver) | Medium silver burst | Tiny (1px, 0.05s) | "+25" float-up | None | `collect_silver` | None |
   | `item_collected` (gold) | Large gold burst + sparkles | Small (2px, 0.1s) | "+100" float-up (larger font) | Brief glow | `collect_gold` | Brief 1.2x |
   | `item_hit` (any hazard) | Dark burst | Medium (4px, 0.15s) | None | Red flash (0.1s) | Per hazard tag | None |
   | `streak_milestone` | Radial sparkle ring | None | "1.5x!" / "2x!" etc popup | Screen edge glow | `streak_milestone` | Brief 1.5x |
   | `life_lost` | None | Large (6px, 0.2s) | None | Red vignette (0.3s) | `life_lost` | Brief 0.5x (calmer) |

2. **Score popups**: Floating text that spawns at the collected item's position, drifts upward, and fades out over `POPUP_DURATION` seconds. Font size scales with point value (gold popups are visually bigger than bronze).

3. **Screen shake**: Camera offset by random amount within `shake_intensity` pixels, decaying over `shake_duration`. Uses a simple decay shake (not perlin — keep it light for a chill game).

4. **Sprite flash**: Player sprite's modulate is briefly set to a color (white for glow, red for hit) then restored. Duration controlled per-event.

5. **Feedback is fire-and-forget**: Each feedback element runs independently. Multiple overlapping events (catching 3 coins rapidly) produce overlapping effects — they stack naturally.

6. **Audio delegation**: The Game Juice System calls `AudioManager.play_sfx(feedback_tag)` — it does not play audio itself. The Audio Manager handles pitch, polyphony, and bus routing.

### States and Transitions

Stateless. Feedback triggers are reactive — no persistent state.

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Collection & Avoidance** | Upstream | `item_collected(item_def)` and `item_hit(item_def)` signals | Hard dep |
| **Streak Multiplier** | Upstream | `streak_milestone(tier, multiplier)` and `streak_reset` signals | Soft dep |
| **Lives System** | Upstream | `life_lost(current_lives, damage)` signal | Soft dep |
| **Audio Manager** | Downstream | `play_sfx(tag)` | Soft dep — juice works visually without audio |
| **Rain VFX System** | Downstream | `set_intensity(value)` for brief spikes | Soft dep |
| **Camera/Viewport** | Downstream | Camera offset for screen shake | Direct manipulation |

## Formulas

### Screen Shake Decay

```
current_shake = shake_intensity * (1.0 - elapsed / shake_duration)
camera_offset = Vector2(randf_range(-current_shake, current_shake), randf_range(-current_shake, current_shake))
```

### Score Popup Movement

```
popup_y = spawn_y - POPUP_RISE_SPEED * elapsed
popup_alpha = 1.0 - (elapsed / POPUP_DURATION)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `POPUP_DURATION` | float | 0.8 | 0.5 - 1.5 | Seconds before popup fades completely |
| `POPUP_RISE_SPEED` | float | 60.0 | 30 - 120 | Pixels per second upward drift |
| `MAX_SHAKE_INTENSITY` | float | 6.0 | 2 - 12 | Maximum shake pixels (for life_lost) |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Many simultaneous feedback events** | All fire independently. Particles may overlap visually. Audio polyphony managed by Audio Manager. | Stacking is fine — it creates exciting "jackpot" moments. |
| **Feedback during screen transition** | Effects continue until their duration expires. New state doesn't cancel in-flight effects. | Smooth transitions. |
| **Screen shake during summary** | Shake is suppressed during Disabled/Summary state. | Don't shake the results screen. |
| **Unknown feedback_tag** | Audio Manager handles gracefully (logs warning). Visual feedback still fires based on item category. | Decoupled — audio failure doesn't block visual feedback. |
| **Popup text off-screen** | Popups are spawned at item position. If item was at screen edge, popup may drift partially off-screen. Acceptable. | Not worth the clamp complexity for a brief floating number. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Collection & Avoidance** | Hard | `item_collected`, `item_hit` signals | Designed |
| **Streak Multiplier** | Soft | `streak_milestone`, `streak_reset` signals | Designed |
| **Lives System** | Soft | `life_lost` signal | Designed |

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Audio Manager** | Soft | `play_sfx(tag)` | Designed |
| **Rain VFX System** | Soft | `set_intensity(value)` | Designed |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `POPUP_DURATION` | float | 0.8 | 0.5 - 1.5 | How long score popups persist | Too short: unreadable. Too long: screen clutter. |
| `POPUP_RISE_SPEED` | float | 60.0 | 30 - 120 | How fast popups float up | Too slow: clutter. Too fast: unreadable. |
| `MAX_SHAKE_INTENSITY` | float | 6.0 | 2 - 12 | Strongest shake (life_lost) | Too high: nauseating. Too low: unnoticeable. |
| `COIN_PARTICLE_COUNT` | int | 8 | 4 - 20 | Particles per coin collection | Too few: underwhelming. Too many: visual noise. |
| `HIT_FLASH_DURATION` | float | 0.1 | 0.05 - 0.3 | Red flash on hazard hit | Too short: invisible. Too long: annoying. |

**Interaction warning**: Juice intensity must respect the "Vibe First" pillar. Screen shake should be subtle — this is a chill game, not an action game. When in doubt, less is more.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Collecting each coin type produces visually distinct feedback | Catch bronze, silver, gold; verify different particle colors/sizes. |
| 2 | Score popup appears at item position and floats up | Catch a coin; observe "+10" popup at catch point rising and fading. |
| 3 | Hazard hit produces screen shake and red flash | Walk into bomb; observe shake and flash. |
| 4 | Streak milestone triggers celebration effects | Reach streak 5; observe sparkle ring and milestone popup. |
| 5 | Audio plays for every feedback event | Verify each event produces its corresponding SFX. |
| 6 | Rapid events don't cause visual glitches | Catch 5 coins in <1 second; verify all popups and particles render. |
| 7 | Screen shake is suppressed during summary screen | Game over; verify no shake on summary. |
| 8 | Feedback processing stays under 0.5ms per frame | Profile during peak event density. |
