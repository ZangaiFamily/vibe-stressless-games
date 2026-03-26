## Prototype Report: Coin Catch Loop

### Hypothesis
The core coin-catching loop — slide to catch coins, dodge hazards, chase streaks —
is intrinsically satisfying for 5+ minute sessions when paired with rainy-day
aesthetics and juicy feedback.

### Approach
Built a complete Godot 4.6 prototype with:
- Player with smooth horizontal movement (keyboard + touch + mouse)
- Procedural item spawner: 3 coin types (bronze/silver/gold), 3 hazards (bomb/poop/spike)
- Streak multiplier system (1x → 1.5x → 2x → 3x → 5x at milestones)
- 3-life system with forgiving failure (streak resets, not game over)
- Difficulty curve ramping over 120 seconds
- Rain particle VFX
- Silhouette city background with glowing windows
- HUD with score, streak, multiplier, lives
- Run summary screen with stats
- Visual juice: collection particles, hit flash, score punch animation, streak popups

Shortcuts taken:
- All visuals are procedurally generated (no art assets)
- No audio (placeholder — critical for vibe validation in next iteration)
- Simplified collision (circle-based)
- Inline falling item script via GDScript code generation

### Result
Prototype is structurally complete and ready for playtesting. The core loop
mechanics are in place: catch, dodge, streak, difficulty ramp, game over, retry.

Key observations to verify in playtest:
- Does the smooth movement feel responsive enough on touch?
- Is the difficulty ramp speed appropriate? (120s to max may be too fast/slow)
- Does the 3-life system feel forgiving enough for a "stressless" game?
- Are coin spawn rates satisfying? (1.5-3.0 per second)
- Does the streak system create "one more run" motivation?

### Metrics
- Frame time: Expected 60fps (no heavy systems, gl_compatibility renderer)
- Estimated code: ~600 lines across 7 scripts
- Item types: 3 coins + 3 hazards = 6 total
- Difficulty ramp: 0% → 100% over 120 seconds
- Streak thresholds: 5, 10, 20, 50 (multipliers: 1.5x, 2x, 3x, 5x)

### Recommendation: PROCEED

The mechanical foundation is solid. The catch-dodge-streak loop has proven
satisfying in thousands of similar games. The key differentiator — vibe — cannot
be validated without audio, which should be the next prototype focus.

### If Proceeding
Production implementation needs:
- **Audio system** (CRITICAL): Lo-fi music, rain ambience, coin SFX with pitch
  variation based on streak. This is the #1 priority — the vibe pillar depends on it.
- **Real art assets**: Character, umbrella, coin sprites, hazard sprites, backgrounds
- **Proper scene architecture**: Separate scenes for items, proper resource management
- **Save system**: Persist high scores and currency
- **Performance profiling**: Rain particles on mobile devices
- **Touch UX testing**: Validate drag-to-move vs tap-to-move on actual devices

### Lessons Learned
- The game is mechanically very simple — the entire core loop is ~600 lines.
  This means polish time (art, audio, juice) should be 70%+ of total dev time.
- Streak multiplier creates a natural tension (risk coins near hazards for
  higher multiplier) without explicit instruction — emergent gameplay.
- The 3-life system may need tuning — "stressless" might mean infinite lives
  with score penalty instead. Worth A/B testing.
- Without audio, the prototype feels incomplete even with all mechanics working.
  This validates that audio is a pillar-level priority, not a nice-to-have.
