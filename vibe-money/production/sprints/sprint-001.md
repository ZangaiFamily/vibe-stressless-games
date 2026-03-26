# Sprint 1 — MVP Core Loop

## Sprint Goal
Implement all 16 MVP systems to produce a fully playable core loop: catch coins, dodge hazards, chase streaks, with rain VFX, lo-fi audio, and juicy feedback.

## Milestone
MVP — First Playable (see `design/gdd/game-concept.md` Scope Tiers)

## Capacity
- Total sessions: 5 (estimated)
- Buffer (20%): 1 session reserved for integration bugs and tuning
- Available: 4 sessions of focused implementation

## Architecture Reference
- ADR-0001: Signal Bus + Autoload Services (`docs/architecture/adr-0001-core-architecture.md`)
- 3 Autoloads: GameEvents, AudioManager, ItemRegistry
- All gameplay systems as scene-tree nodes
- Data as Godot Resources (.tres)

---

## Tasks

### Phase 1: Foundation (Session 1)

| ID | Task | GDD Source | Est. | Dependencies | Acceptance Criteria |
|----|------|-----------|------|-------------|-------------------|
| T01 | Create Godot project structure matching directory layout | ADR-0001 | S | None | Project runs, folders match spec |
| T02 | Implement GameEvents autoload (signal bus) | ADR-0001 | S | T01 | All signals declared per GDD contracts |
| T03 | Implement ItemDef Resource class + 6 MVP item .tres files | item-database.md | S | T01 | Resources load with correct properties |
| T04 | Implement ItemRegistry autoload | item-database.md | S | T03 | get_item(), get_spawn_table() return correct data |
| T05 | Implement Input System | input-system.md | S | T01 | Keyboard + mouse drag input produces -1.0 to 1.0 |
| T06 | Implement AudioManager autoload (bus setup, play_sfx stub) | audio-manager.md | M | T02 | 3 buses created, play_sfx accepts tags, no crash on missing audio |

### Phase 2: Core Gameplay (Session 2)

| ID | Task | GDD Source | Est. | Dependencies | Acceptance Criteria |
|----|------|-----------|------|-------------|-------------------|
| T07 | Implement Player Controller (movement, boundaries, Area2D) | player-controller.md | S | T05 | Character moves, stays in bounds, has collision area |
| T08 | Implement Item Spawner (timer, weighted selection, columns, pooling) | item-spawner.md | M | T04 | Items spawn at intervals, weighted random, column-based positioning |
| T09 | Implement falling item scene (movement, off-screen removal) | item-spawner.md | S | T08 | Items fall at correct speed, removed at bottom |
| T10 | Implement Collection & Avoidance (overlap detection, signals) | collection-avoidance.md | M | T07, T08, T02 | Coins emit item_collected, hazards emit item_hit, i-frames work |
| T11 | Implement Difficulty Curve | difficulty-curve.md | S | T08 | Multipliers ramp from 0% to 100% over RAMP_DURATION |

### Phase 3: Scoring & State (Session 3)

| ID | Task | GDD Source | Est. | Dependencies | Acceptance Criteria |
|----|------|-----------|------|-------------|-------------------|
| T12 | Implement Score System | score-system.md | S | T10 | Score accumulates with multiplier applied |
| T13 | Implement Lives System | lives-system.md | S | T10 | Lives decrease on hit, lives_depleted emits at 0 |
| T14 | Implement Streak Multiplier | streak-multiplier.md | S | T10 | Streak increments/resets, multiplier steps at thresholds |
| T15 | Implement Run Manager (lifecycle, reset, stats) | run-manager.md | M | T12, T13, T14, T11 | Full run lifecycle: start → play → game over → summary → retry |
| T16 | Wire AudioManager streak pitch + state transitions | audio-manager.md | S | T14, T15, T06 | Pitch rises with streak, state transitions work |

### Phase 4: Presentation & UI (Session 4)

| ID | Task | GDD Source | Est. | Dependencies | Acceptance Criteria |
|----|------|-----------|------|-------------|-------------------|
| T17 | Implement Rain VFX System (2-layer GPUParticles2D) | rain-vfx-system.md | M | T01 | Rain visible, 2 depth layers, wind variation |
| T18 | Implement Parallax Background (city silhouette layers) | parallax-background.md | S | T01 | 3+ layers with parallax response to player movement |
| T19 | Implement Game Juice System (particles, shake, popups, flash) | game-juice-system.md | M | T10, T14, T13 | Visual feedback for all events in the feedback mapping table |
| T20 | Implement HUD (score, streak, lives) | hud.md | S | T12, T14, T13 | All 3 stats displayed, update in real-time, punch animation |
| T21 | Implement Run Summary Screen | run-summary-screen.md | S | T15 | Stats display, score count-up, retry/menu buttons work |

### Phase 5: Integration & Polish (Buffer Session)

| ID | Task | GDD Source | Est. | Dependencies | Acceptance Criteria |
|----|------|-----------|------|-------------|-------------------|
| T22 | Add placeholder audio assets (SFX + music + rain) | audio-manager.md | S | T06 | All feedback tags have corresponding sounds |
| T23 | Integration testing — full play-through | All GDDs | M | All | Complete run: start → catch → dodge → streak → game over → retry |
| T24 | Tuning pass — adjust defaults based on feel | All GDDs | S | T23 | Game feels good per Vibe First pillar |
| T25 | Performance profiling on target platforms | technical-preferences.md | S | T23 | 60fps sustained, rain VFX within budget |

---

## Task Summary

| Priority | Tasks | Count |
|----------|-------|-------|
| Phase 1 (Foundation) | T01-T06 | 6 |
| Phase 2 (Core Gameplay) | T07-T11 | 5 |
| Phase 3 (Scoring & State) | T12-T16 | 5 |
| Phase 4 (Presentation & UI) | T17-T21 | 5 |
| Phase 5 (Integration) | T22-T25 | 4 |
| **Total** | | **25** |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Rain VFX tanks FPS on mobile | Medium | High | Build quality tiers (Full/Lite/Minimal) from the start. Profile early. |
| Audio assets not ready | High | Medium | Use placeholder/generated sounds. Audio polish is a later sprint. |
| Signal wiring bugs at integration | Medium | Medium | Test each system's signal connections as they're built, not at the end. |
| Godot 4.6 API differences from training data | Medium | Low | Reference `docs/engine-reference/godot/` for post-cutoff changes. |

## Dependencies on External Factors
- Godot 4.6 stable must be installed on dev machine
- Placeholder audio assets (can be generated or sourced from free libraries)
- Placeholder art (procedural/generated as in prototype — real art is a later milestone)

## Definition of Done for this Sprint
- [ ] All 16 MVP systems implemented and wired together
- [ ] A player can: start a run, catch coins, dodge hazards, build streaks, see score, lose lives, see game over summary, and retry
- [ ] Rain VFX and parallax background are visible
- [ ] Audio plays (music loop, rain ambience, coin/hazard SFX with streak pitch)
- [ ] Game runs at 60fps on development machine
- [ ] No crash bugs in the core play loop
- [ ] Code follows naming conventions from technical-preferences.md
- [ ] Each system's acceptance criteria from its GDD are met
