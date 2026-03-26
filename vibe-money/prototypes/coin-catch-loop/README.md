# Prototype: Coin Catch Loop

**Hypothesis**: The coin-catching core loop is fun and satisfying with rainy-day vibes.

**Status**: In Progress — ready for playtest

## How to Run

1. Open Godot 4.6
2. Import this project: `prototypes/coin-catch-loop/project.godot`
3. Press F5 (or Play)

**Controls**:
- **Keyboard**: A/D or Left/Right arrows to move
- **Mouse**: Click and drag to move player to cursor X position
- **Touch**: Tap/drag to move (mobile)
- **R**: Restart after game over

## What's In the Prototype

- Player with smooth horizontal movement
- Falling coins (bronze = 1pt, silver = 3pt, gold = 10pt)
- Falling hazards (bomb, poop, spike)
- Streak multiplier (5x → 1.5x, 10x → 2x, 20x → 3x, 50x → 5x)
- 3 lives, difficulty ramps over 2 minutes
- Rain particle effect + city silhouette background
- HUD with score, streak, multiplier, lives
- End-of-run summary with retry

## Findings

See [REPORT.md](REPORT.md) for full analysis.
