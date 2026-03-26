# Audio Manager

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Vibe First, Juicy Feedback

## Overview

The Audio Manager owns all sound in Vibe Money — lo-fi music, rain ambience, and gameplay SFX (coin clinks, hazard hits, streak popups, UI feedback). It provides a bus-based mixing architecture with three independent layers: Music, Ambience, and SFX. Other systems trigger sounds by emitting feedback tags (defined in the Item Database); the Audio Manager resolves tags to audio streams, applies pitch/volume variation, and manages polyphony limits. The player never interacts with this system directly, but they *feel* it constantly — it is the primary carrier of the "Vibe First" pillar. Without it, the prototype report confirmed the game feels incomplete even with all mechanics working.

## Player Fantasy

Close your eyes and imagine standing on a city rooftop at night. Rain taps gently on your umbrella. Somewhere below, a lo-fi beat hums through a cracked window. A coin lands in your hand with a warm *clink* — then another, higher-pitched — then another, even brighter, as your streak builds. The sounds layer into a personal soundtrack that responds to how you play. The Audio Manager's fantasy is **the world that sounds alive around you** — rain that never stops, music that never intrudes, and every coin catch that builds into an ASMR-like rhythm. This is the system that makes players put on headphones, close their eyes between runs, and stay longer than they planned. "The vibe IS the game" — and this system IS the vibe.

## Detailed Design

### Core Rules

1. **Three audio buses** (mapped to Godot's AudioServer bus layout):

   | Bus | Purpose | Content | Default Volume |
   |-----|---------|---------|---------------|
   | **Music** | Lo-fi background track | Single looping track (MVP) | -6 dB |
   | **Ambience** | Environmental atmosphere | Rain loop, distant city hum | -3 dB |
   | **SFX** | Gameplay feedback | Coin clinks, hazard hits, streak popups, UI sounds | 0 dB |

   All three buses route to a **Master** bus. Each bus has independent volume control.

2. **Tag-based SFX playback**: Other systems trigger sounds by calling `AudioManager.play_sfx(tag: StringName)`. The Audio Manager maps `feedback_tag` values (defined in Item Database) to audio streams:

   | Tag | Sound | Notes |
   |-----|-------|-------|
   | `collect_bronze` | Soft metallic clink | Low pitch base |
   | `collect_silver` | Bright metallic clink | Medium pitch base |
   | `collect_gold` | Resonant chime | High pitch base |
   | `hit_bomb` | Muffled thud + glass crack | Dissonant, brief |
   | `hit_poop` | Wet splat | Comic, not gross |
   | `hit_spike` | Sharp metallic scrape | Piercing but short |
   | `streak_milestone` | Ascending chime flourish | Plays at streak 5, 10, 20, 50 |
   | `life_lost` | Soft descending tone | Gentle "aww", not punishing |
   | `run_start` | Rain intensifies briefly | Signals beginning |
   | `run_end` | Music fades, rain continues | Smooth transition to summary |
   | `ui_tap` | Soft click | For button presses |

3. **Streak-based pitch scaling**: When a coin is collected, the SFX pitch is modified based on current streak:

   ```
   pitch_scale = BASE_PITCH + (streak_count * PITCH_INCREMENT)
   pitch_scale = clamp(pitch_scale, MIN_PITCH, MAX_PITCH)
   ```

   Streak resets → pitch resets to `BASE_PITCH`. This creates the "musical escalation" described in the player fantasy.

4. **Polyphony management**: The SFX bus supports up to `MAX_POLYPHONY` simultaneous sounds. When the limit is reached, the oldest playing SFX is stopped to make room. This prevents audio overload during dense item clusters.

5. **Music playback**: A single `AudioStreamPlayer` on the Music bus loops the lo-fi track continuously. Music starts on game launch and never stops — it plays through menus, gameplay, and summary screens. Volume dips slightly during run-end summary (ducking).

6. **Ambience playback**: Rain ambience plays continuously on the Ambience bus. Like music, it never stops. Rain intensity (volume + filter cutoff) can be modulated by the Game Juice System for emphasis moments.

7. **Volume ducking**: When a high-priority SFX plays (e.g., `streak_milestone`, `life_lost`), the Music bus volume temporarily dips by `DUCK_AMOUNT_DB` for `DUCK_DURATION` seconds, then fades back. This ensures important feedback cuts through the mix.

### States and Transitions

| State | Description | Music | Ambience | SFX |
|-------|-------------|-------|----------|-----|
| **Menu** | Main menu / pre-game | Playing (full volume) | Playing (full volume) | UI sounds only |
| **Gameplay** | Active run | Playing (full volume) | Playing (full volume) | All SFX active |
| **Summary** | Run-end screen | Playing (ducked -3 dB) | Playing (full volume) | UI sounds only |
| **Muted** | Player muted audio | Silent | Silent | Silent |

Transitions are crossfaded — no hard audio cuts.

### Interactions with Other Systems

| System | Direction | Interface | Data Exchanged |
|--------|-----------|-----------|---------------|
| **Game Juice System** | Upstream triggers | `AudioManager.play_sfx(tag)` | Feedback tags from item collection/hit events |
| **Streak Multiplier** | Upstream provides | `AudioManager.set_streak(count: int)` | Current streak count for pitch scaling |
| **Run Manager** | Upstream triggers | `AudioManager.set_state(state)` | Triggers state transitions (Menu → Gameplay → Summary) |
| **Item Database** | Indirect | Defines `feedback_tag` per item | Tags are the contract — Audio Manager maps tags to sounds |
| **Settings System** | Downstream reads (Vertical Slice) | Per-bus volume settings | Player volume preferences |

**Cross-reference with Item Database**: The `feedback_tag` field in `ItemDef` is the interface contract. Every tag listed in the Item Database roster must have a corresponding sound mapping in the Audio Manager. Currently: `collect_bronze`, `collect_silver`, `collect_gold`, `hit_bomb`, `hit_poop`, `hit_spike`.

## Formulas

### Streak Pitch Scaling

```
pitch_scale = BASE_PITCH + (streak_count * PITCH_INCREMENT)
pitch_scale = clamp(pitch_scale, MIN_PITCH, MAX_PITCH)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `BASE_PITCH` | float | 1.0 | 0.8 - 1.2 | Starting pitch at streak 0 |
| `PITCH_INCREMENT` | float | 0.02 | 0.01 - 0.05 | Pitch increase per consecutive catch |
| `MIN_PITCH` | float | 0.8 | 0.5 - 1.0 | Floor (never goes below, even with negative offset) |
| `MAX_PITCH` | float | 1.6 | 1.3 - 2.0 | Ceiling (prevents chipmunk sounds) |
| `streak_count` | int | 0 | 0 - 999 | Current consecutive catches |

**Example progression** (with defaults):

| Streak | Pitch | Musical Feel |
|--------|-------|-------------|
| 0 | 1.00 | Normal |
| 5 | 1.10 | Slightly brighter |
| 10 | 1.20 | Noticeably higher |
| 20 | 1.40 | Excited, climbing |
| 30+ | 1.60 (capped) | Maximum brightness |

### Volume Ducking

```
ducked_volume = bus_volume + DUCK_AMOUNT_DB
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `DUCK_AMOUNT_DB` | float | -6.0 | -12.0 to -3.0 | How much to lower music (negative = quieter) |
| `DUCK_DURATION` | float | 0.5 | 0.2 - 1.0 | Seconds the duck lasts before fade-back |
| `DUCK_FADE_TIME` | float | 0.3 | 0.1 - 0.5 | Fade-in/out time for smooth ducking |

### Pitch Randomization (per SFX play)

```
final_pitch = pitch_scale + randf_range(-PITCH_VARIANCE, PITCH_VARIANCE)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `PITCH_VARIANCE` | float | 0.05 | 0.0 - 0.15 | Random pitch offset per play — prevents robotic repetition |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Rapid coin collection (5+ coins in <1 second)** | Polyphony limit kicks in — oldest sound stops. Each coin still gets its own SFX trigger with correct streak pitch. | Prevents audio overload while maintaining the musical escalation feel. |
| **Unknown feedback tag** | `play_sfx()` logs a warning and plays nothing. No crash. | Graceful degradation when a new item type is added without a corresponding sound mapping. |
| **Streak pitch at max + pitch variance** | Final pitch can temporarily exceed `MAX_PITCH` by up to `PITCH_VARIANCE`. Acceptable — the clamp is on the base, not the randomized output. | Tiny overshoot adds organic feel. Clamping the final output would create an audible "ceiling" at high streaks. |
| **Simultaneous duck triggers** | If two high-priority SFX fire in the same frame, only one duck is applied (no double-ducking). Duck timer resets to full duration. | Prevents music from disappearing entirely during intense moments. |
| **Audio focus lost (phone call, app switch)** | Godot handles this natively — audio pauses when the app loses focus and resumes when regained. | No custom handling needed. |
| **Music track ends before loop point** | Music stream is set to loop. If the file has no embedded loop markers, Godot loops from the start. Ensure music files have seamless loop points. | A perceptible "restart" breaks the vibe. Asset requirement, not a code fix. |
| **All buses muted by player** | Game plays silently. All `play_sfx()` calls are still processed (to keep streak pitch state correct) but produce no audible output. | Pitch state must stay in sync even when muted, so unmuting mid-streak sounds correct. |
| **SFX triggered during state transition** | SFX in-flight during a state change (e.g., Gameplay → Summary) are allowed to finish. New gameplay SFX are not accepted until state returns to Gameplay. | Prevents abrupt sound cuts on game over. |
| **No audio assets loaded (first prototype)** | All `play_sfx()` calls silently no-op. Music and ambience players are silent. No errors. | Allows the game to run without audio assets during early development. |

## Dependencies

### Upstream (this system depends on)

None. The Audio Manager is a foundation-layer system with zero dependencies.

### Downstream (these systems depend on this)

| System | Dependency Type | Interface | Status |
|--------|----------------|-----------|--------|
| **Game Juice System** | Soft | Calls `play_sfx(tag)` for collection/hit feedback | Not yet designed |
| **Streak Multiplier** | Soft | Calls `set_streak(count)` for pitch scaling | Not yet designed |
| **Run Manager** | Soft | Calls `set_state(state)` for audio state transitions | Not yet designed |
| **Settings System** | Soft (Vertical Slice) | Reads/writes per-bus volume levels | Not yet designed |

All downstream dependencies are **soft** — every system works without audio, just without sound feedback.

### External Dependencies

| Dependency | Notes |
|------------|-------|
| **Godot AudioServer** | Bus layout, volume control, effects processing |
| **Godot AudioStreamPlayer** | Playback nodes for Music, Ambience, and SFX pool |
| **Audio assets** | `.ogg` for music/ambience (streaming), `.wav` for SFX (low-latency). Stored in `assets/audio/` |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `MUSIC_VOLUME_DB` | float | -6.0 | -20 to 0 | Music loudness | Too loud: drowns SFX. Too quiet: no vibe. |
| `AMBIENCE_VOLUME_DB` | float | -3.0 | -20 to 0 | Rain/environment loudness | Too loud: fatiguing. Too quiet: atmosphere lost. |
| `SFX_VOLUME_DB` | float | 0.0 | -12 to 6 | Gameplay feedback loudness | Too loud: jarring. Too quiet: no feedback. |
| `BASE_PITCH` | float | 1.0 | 0.8 - 1.2 | Starting coin SFX pitch | Below 0.8: sounds "wrong". Above 1.2: too bright at start. |
| `PITCH_INCREMENT` | float | 0.02 | 0.01 - 0.05 | How fast pitch rises per streak | Too low: no perceptible change. Too high: chipmunk by streak 10. |
| `MAX_PITCH` | float | 1.6 | 1.3 - 2.0 | Pitch ceiling | Below 1.3: escalation feels flat. Above 2.0: sounds broken. |
| `PITCH_VARIANCE` | float | 0.05 | 0.0 - 0.15 | Random pitch offset per play | 0: robotic repetition. Above 0.15: sounds random, not musical. |
| `MAX_POLYPHONY` | int | 8 | 4 - 16 | Simultaneous SFX sounds | Below 4: noticeable sound drops. Above 16: potential performance issue on mobile. |
| `DUCK_AMOUNT_DB` | float | -6.0 | -12 to -3 | Music dip on priority SFX | Too deep: music vanishes. Too shallow: SFX lost in mix. |
| `DUCK_DURATION` | float | 0.5 | 0.2 - 1.0 | How long music stays ducked | Too short: barely noticeable. Too long: music feels broken. |
| `DUCK_FADE_TIME` | float | 0.3 | 0.1 - 0.5 | Duck in/out smoothness | Too fast: audible click. Too slow: duck misses the moment. |

**Interaction warnings:**
- `BASE_PITCH`, `PITCH_INCREMENT`, and `MAX_PITCH` are tightly coupled — changing one requires re-evaluating the others.
- `MAX_POLYPHONY` interacts with Item Spawner's spawn rate. At max difficulty (~3 spawns/sec), 8 polyphony voices should be sufficient since coin SFX are short (<0.5s).
- `MUSIC_VOLUME_DB` and `DUCK_AMOUNT_DB` combine — if music is already at -20 dB, ducking by -6 dB makes it inaudible.

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Music plays on game launch and loops seamlessly with no audible gap or click | Listen through 3+ full loops; record and inspect waveform at loop boundary. |
| 2 | Rain ambience plays continuously and is audibly distinct from music | Mute music bus; confirm rain is still audible and atmospheric. |
| 3 | All 6 MVP item feedback tags produce the correct SFX | Trigger each tag via debug console; verify correct sound plays. |
| 4 | Coin SFX pitch rises audibly with streak count | Collect 30 coins consecutively; confirm pitch progression from normal to bright. |
| 5 | Streak reset (hazard hit) resets pitch to BASE_PITCH | Build a streak, hit a hazard, collect a coin; confirm pitch dropped back to normal. |
| 6 | Rapid collection (5+ items in <1s) does not produce audio glitches or silence | Spawn dense item cluster; confirm all sounds play cleanly within polyphony limit. |
| 7 | Volume ducking is audible on `streak_milestone` and `life_lost` SFX | Trigger milestone at streak 5; confirm music dips briefly and recovers smoothly. |
| 8 | Unknown feedback tag logs a warning but does not crash | Call `play_sfx("nonexistent_tag")`; verify warning in console, no error. |
| 9 | Audio state transitions (Menu → Gameplay → Summary) have no hard cuts | Play through a full run; listen for smooth crossfades at each transition. |
| 10 | Total audio CPU usage stays below 1ms per frame | Profile with Godot's built-in audio profiler during peak gameplay (max difficulty). |
| 11 | Game runs without errors when no audio assets are present | Delete all audio files, launch game; confirm no crashes, only silent playback. |

