# Systems Index: Vibe Money

> **Status**: Draft
> **Created**: 2026-03-26
> **Last Updated**: 2026-03-26
> **Source Concept**: design/gdd/game-concept.md

---

## Overview

Vibe Money is a small-scope casual arcade game with a tight core loop: catch coins, dodge hazards, chase streaks. The systems are deliberately minimal — the game's differentiation comes from audiovisual polish (Pillar: Vibe First, Juicy Feedback), not mechanical complexity. Foundation systems handle input and scene management, gameplay systems drive the catch-and-dodge loop, and presentation systems deliver the rain-soaked aesthetic that makes the game feel special.

---

## Systems Enumeration

| # | System Name | Category | Priority | Status | Design Doc | Depends On |
|---|-------------|----------|----------|--------|------------|------------|
| 1 | Input System | Core | MVP | Designed | [input-system.md](input-system.md) | — |
| 2 | Player Controller | Core | MVP | Designed | [player-controller.md](player-controller.md) | Input System |
| 3 | Item Database | Core | MVP | Designed | [item-database.md](item-database.md) | — |
| 4 | Item Spawner | Gameplay | MVP | Designed | [item-spawner.md](item-spawner.md) | Item Database |
| 5 | Collection & Avoidance | Gameplay | MVP | Designed | [collection-avoidance.md](collection-avoidance.md) | Player Controller, Item Spawner |
| 6 | Lives System | Gameplay | MVP | Designed | [lives-system.md](lives-system.md) | Collection & Avoidance |
| 7 | Score System | Gameplay | MVP | Designed | [score-system.md](score-system.md) | Collection & Avoidance |
| 8 | Streak Multiplier | Gameplay | MVP | Designed | [streak-multiplier.md](streak-multiplier.md) | Score System, Collection & Avoidance |
| 9 | Difficulty Curve | Gameplay | MVP | Designed | [difficulty-curve.md](difficulty-curve.md) | Item Spawner |
| 10 | Run Manager | Core | MVP | Designed | [run-manager.md](run-manager.md) | Lives System, Score System, Difficulty Curve |
| 11 | Rain VFX System | Presentation | MVP | Designed | [rain-vfx-system.md](rain-vfx-system.md) | — |
| 12 | Parallax Background | Presentation | MVP | Designed | [parallax-background.md](parallax-background.md) | — |
| 13 | Game Juice System | Presentation | MVP | Designed | [game-juice-system.md](game-juice-system.md) | Collection & Avoidance, Streak Multiplier |
| 14 | Audio Manager | Audio | MVP | Designed | [audio-manager.md](audio-manager.md) | — |
| 15 | HUD | UI | MVP | Designed | [hud.md](hud.md) | Score System, Streak Multiplier, Lives System |
| 16 | Run Summary Screen | UI | MVP | Designed | [run-summary-screen.md](run-summary-screen.md) | Run Manager, Score System |
| 17 | Main Menu | UI | Vertical Slice | Not Started | — | — |
| 18 | Currency Wallet (inferred) | Economy | Vertical Slice | Not Started | — | Score System |
| 19 | Cosmetic System (inferred) | Progression | Vertical Slice | Not Started | — | Item Database, Currency Wallet |
| 20 | Shop / Unlock Screen | UI | Vertical Slice | Not Started | — | Cosmetic System, Currency Wallet |
| 21 | Save / Load System (inferred) | Persistence | Vertical Slice | Not Started | — | Currency Wallet, Cosmetic System |
| 22 | Settings System (inferred) | Persistence | Vertical Slice | Not Started | — | Audio Manager |
| 23 | Environment Manager (inferred) | Presentation | Alpha | Not Started | — | Parallax Background, Cosmetic System |
| 24 | Achievement System (inferred) | Progression | Alpha | Not Started | — | Score System, Run Manager |
| 25 | Leaderboard (inferred) | Meta | Full Vision | Not Started | — | Score System, Save / Load System |
| 26 | Onboarding / First-Run (inferred) | Meta | Full Vision | Not Started | — | Run Manager |

---

## Categories

| Category | Description | Systems |
|----------|-------------|---------|
| **Core** | Foundation systems everything else builds on | Input System, Player Controller, Item Database, Run Manager |
| **Gameplay** | The catch-dodge-score loop | Item Spawner, Collection & Avoidance, Lives System, Score System, Streak Multiplier, Difficulty Curve |
| **Economy** | Currency tracking | Currency Wallet |
| **Progression** | How the player grows | Cosmetic System, Achievement System |
| **Persistence** | Saving state between sessions | Save / Load System, Settings System |
| **UI** | Screens and overlays | HUD, Run Summary Screen, Main Menu, Shop / Unlock Screen |
| **Presentation** | Visual and audio polish | Rain VFX System, Parallax Background, Game Juice System, Audio Manager, Environment Manager |
| **Meta** | Outside the core loop | Leaderboard, Onboarding / First-Run |

---

## Priority Tiers

| Tier | Definition | Target Milestone | Systems Count |
|------|------------|------------------|---------------|
| **MVP** | Core loop: catch coins, dodge hazards, score, streak, game over | First playable (2-3 days) | 16 |
| **Vertical Slice** | Full session: earn currency, unlock cosmetics, save progress | Polished demo (1 week) | 6 |
| **Alpha** | Multiple environments, achievements | Feature complete (2 weeks) | 2 |
| **Full Vision** | Leaderboards, onboarding, seasonal events | Release (3-4 weeks) | 2 |

---

## Dependency Map

### Foundation Layer (no dependencies)

1. **Input System** — abstracts touch/keyboard/controller into horizontal movement
2. **Item Database** — defines all coin types, hazard types, and their properties
3. **Rain VFX System** — particle rain, purely visual, no gameplay deps
4. **Parallax Background** — layered scrolling background art
5. **Audio Manager** — music playback, rain ambience, SFX bus routing

### Core Layer (depends on foundation)

1. **Player Controller** — depends on: Input System
2. **Item Spawner** — depends on: Item Database
3. **Difficulty Curve** — depends on: Item Spawner (controls spawn rates/speeds)

### Feature Layer (depends on core)

1. **Collection & Avoidance** — depends on: Player Controller, Item Spawner
2. **Score System** — depends on: Collection & Avoidance
3. **Lives System** — depends on: Collection & Avoidance
4. **Streak Multiplier** — depends on: Score System, Collection & Avoidance
5. **Run Manager** — depends on: Lives System, Score System, Difficulty Curve
6. **Currency Wallet** — depends on: Score System
7. **Cosmetic System** — depends on: Item Database, Currency Wallet
8. **Achievement System** — depends on: Score System, Run Manager

### Presentation Layer (depends on features)

1. **Game Juice System** — depends on: Collection & Avoidance, Streak Multiplier
2. **HUD** — depends on: Score System, Streak Multiplier, Lives System
3. **Run Summary Screen** — depends on: Run Manager, Score System
4. **Main Menu** — standalone UI screen
5. **Shop / Unlock Screen** — depends on: Cosmetic System, Currency Wallet
6. **Environment Manager** — depends on: Parallax Background, Cosmetic System

### Polish Layer (depends on everything)

1. **Save / Load System** — depends on: Currency Wallet, Cosmetic System
2. **Settings System** — depends on: Audio Manager
3. **Leaderboard** — depends on: Score System, Save / Load System
4. **Onboarding / First-Run** — depends on: Run Manager

---

## Recommended Design Order

| Order | System | Priority | Layer | Est. Effort |
|-------|--------|----------|-------|-------------|
| 1 | Input System | MVP | Foundation | S |
| 2 | Item Database | MVP | Foundation | S |
| 3 | Audio Manager | MVP | Foundation | M |
| 4 | Player Controller | MVP | Core | S |
| 5 | Item Spawner | MVP | Core | M |
| 6 | Difficulty Curve | MVP | Core | S |
| 7 | Collection & Avoidance | MVP | Feature | M |
| 8 | Score System | MVP | Feature | S |
| 9 | Lives System | MVP | Feature | S |
| 10 | Streak Multiplier | MVP | Feature | S |
| 11 | Run Manager | MVP | Feature | M |
| 12 | Rain VFX System | MVP | Foundation | M |
| 13 | Parallax Background | MVP | Foundation | S |
| 14 | Game Juice System | MVP | Presentation | M |
| 15 | HUD | MVP | Presentation | S |
| 16 | Run Summary Screen | MVP | Presentation | S |
| 17 | Currency Wallet | Vertical Slice | Feature | S |
| 18 | Main Menu | Vertical Slice | Presentation | S |
| 19 | Cosmetic System | Vertical Slice | Feature | M |
| 20 | Shop / Unlock Screen | Vertical Slice | Presentation | S |
| 21 | Save / Load System | Vertical Slice | Polish | M |
| 22 | Settings System | Vertical Slice | Polish | S |
| 23 | Environment Manager | Alpha | Presentation | M |
| 24 | Achievement System | Alpha | Feature | S |
| 25 | Leaderboard | Full Vision | Polish | M |
| 26 | Onboarding / First-Run | Full Vision | Polish | S |

Effort: S = 1 session, M = 2-3 sessions

---

## Circular Dependencies

- None found. The dependency graph is a clean DAG.

---

## High-Risk Systems

| System | Risk Type | Risk Description | Mitigation |
|--------|-----------|-----------------|------------|
| Rain VFX System | Technical | Particle-heavy rain may tank FPS on mobile/web | Profile early; build "lite rain" quality tier |
| Audio Manager | Technical | Layering rain + music + pitch-shifting SFX may cause muddy audio | Mix early; define audio bus hierarchy upfront |
| Game Juice System | Design | Over-juicing breaks the "chill" pillar; under-juicing feels flat | Prototype juice levels; playtest with vibe-sensitive testers |
| Item Spawner | Design | Spawn patterns determine if the game feels fair or random | Prototype multiple spawn algorithms; test "fairness feel" |

---

## Progress Tracker

| Metric | Count |
|--------|-------|
| Total systems identified | 26 |
| Design docs started | 16 |
| Design docs reviewed | 0 |
| Design docs approved | 0 |
| MVP systems designed | 16/16 |
| Vertical Slice systems designed | 0/6 |

---

## Next Steps

- [ ] Design MVP-tier systems first (use `/design-system [system-name]`)
- [ ] Run `/design-review` on each completed GDD
- [ ] Prototype the core loop early (`/prototype coin-catch-loop`)
- [ ] Run `/gate-check pre-production` when MVP systems are designed
- [ ] Plan first sprint (`/sprint-plan new`)
