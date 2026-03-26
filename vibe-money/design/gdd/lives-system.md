# Lives System

> **Status**: Designed
> **Author**: User + Claude Code Game Studios
> **Last Updated**: 2026-03-26
> **Implements Pillar**: Vibe First, Effortless to Play

## Overview

The Lives System tracks the player's remaining hit points during a run. The player starts each run with `MAX_LIVES` (default: 3). When the Collection & Avoidance system emits an `item_hit` signal, this system subtracts the hazard's `damage` value (typically 1). When lives reach 0, the system emits `lives_depleted` to end the run. The system is deliberately forgiving — hitting a hazard resets your streak but doesn't immediately end the game, honoring the "Vibe First" pillar: failure is a gentle nudge, not a harsh punishment.

## Player Fantasy

Lives are your safety net, not a countdown to doom. Losing a life should feel like "aww, I lost my streak" not "I'm about to die." The 3-life system gives you room to make mistakes and still have a good run. When you're down to your last life, there's a gentle tension — not panic, but heightened awareness. The game over should feel like a natural endpoint ("well, that was a good run"), not a punishment.

## Detailed Design

### Core Rules

1. **Starting lives**: `current_lives = MAX_LIVES` at run start.
2. **Taking damage**: On `item_hit(item_def)`, subtract `item_def.damage` from `current_lives`. Emit `life_lost(current_lives, damage)` signal.
3. **Game over**: When `current_lives <= 0`, emit `lives_depleted` signal. The Run Manager listens for this to end the run.
4. **No healing**: Lives cannot be regained within a run (MVP). No health pickups, no extra lives.
5. **No overkill tracking**: If damage exceeds remaining lives, lives go to 0. No negative lives.

### States and Transitions

| State | Description | Transitions To |
|-------|-------------|---------------|
| **Full** | `current_lives == MAX_LIVES` | Damaged (hit) |
| **Damaged** | `0 < current_lives < MAX_LIVES` | Damaged (hit again), Depleted (lives reach 0) |
| **Depleted** | `current_lives == 0` | Full (new run starts) |

### Interactions with Other Systems

| System | Direction | Interface | Notes |
|--------|-----------|-----------|-------|
| **Collection & Avoidance** | Upstream | `item_hit(item_def)` signal | Hard dep — triggers damage |
| **HUD** | Downstream | `life_lost(current_lives, damage)` signal | Displays remaining lives |
| **Run Manager** | Downstream | `lives_depleted` signal | Triggers run end |
| **Game Juice System** | Downstream (indirect) | `life_lost` signal | Triggers hit VFX/screen flash |

## Formulas

```
current_lives = max(current_lives - item_def.damage, 0)
```

| Variable | Type | Default | Range | Description |
|----------|------|---------|-------|-------------|
| `MAX_LIVES` | int | 3 | 1 - 5 | Starting lives per run |
| `item_def.damage` | int | 1 | 0 - 3 | Damage per hazard (from Item Database) |

## Edge Cases

| Edge Case | What Happens | Rationale |
|-----------|-------------|-----------|
| **Damage > remaining lives** | Lives clamp to 0. Single `lives_depleted` signal. | No negative lives, no double game-over. |
| **Damage = 0 hazard** | No life lost. `life_lost` signal not emitted. | Supports future "annoyance" hazards that reset streak without dealing damage. |
| **Hit during invincibility** | Collection & Avoidance handles this — Lives System never receives the signal. | i-frames are upstream of Lives System. |
| **MAX_LIVES = 1** | One-hit game over. Valid for hard mode. | Supported but not recommended for the "chill" design goal. |

## Dependencies

### Upstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **Collection & Avoidance** | Hard | `item_hit(item_def)` signal | Designed |

### Downstream
| System | Dep Type | Interface | Status |
|--------|----------|-----------|--------|
| **HUD** | Soft | `life_lost` signal | Not yet designed |
| **Run Manager** | Hard | `lives_depleted` signal | Not yet designed |

## Tuning Knobs

| Knob | Type | Default | Safe Range | What It Affects | What Breaks If Wrong |
|------|------|---------|------------|-----------------|---------------------|
| `MAX_LIVES` | int | 3 | 1 - 5 | How forgiving the game is | 1: too punishing for casual. 5+: no tension, hazards feel irrelevant. |

## Acceptance Criteria

| # | Criterion | How to Verify |
|---|-----------|---------------|
| 1 | Player starts with MAX_LIVES | Start run; verify HUD shows 3 lives. |
| 2 | Hitting a hazard reduces lives by hazard's damage value | Hit bomb (damage 1); verify lives = 2. |
| 3 | Lives reaching 0 triggers run end | Hit 3 hazards; verify game over screen appears. |
| 4 | Lives cannot go below 0 | Hit 4 hazards rapidly (during non-i-frame window); verify lives = 0, not negative. |
| 5 | Lives reset to MAX_LIVES on new run | End a run, start new; verify 3 lives. |
| 6 | `life_lost` signal fires with correct values | Log signal; verify current_lives and damage values. |
