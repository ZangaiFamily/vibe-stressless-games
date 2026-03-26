# ADR-0001: Core Game Architecture — Signal Bus + Autoload Services

## Status
Accepted

## Date
2026-03-26

## Context

### Problem Statement
Vibe Money has 16 MVP systems that must communicate with each other: gameplay events (coin collected, hazard hit, streak milestone) need to flow from detection systems to scoring, audio, visual feedback, and UI systems. We need a clear architecture pattern that keeps systems decoupled, testable, and maintainable while being simple enough for a small-scope casual game.

### Constraints
- **Engine**: Godot 4.6 (GDScript primary)
- **Scope**: Small game — 16 MVP systems, ~2000-4000 lines total estimated
- **Team size**: Solo/small — architecture must be understandable without documentation deep-dives
- **Performance**: 60fps target, mobile support
- **Data-driven**: Gameplay values must live in external config (coding standard)

### Requirements
- Systems must communicate without hard references to each other
- Adding new item types or feedback effects must not require code changes in unrelated systems
- Each system must be independently testable
- The architecture must support Godot's scene tree model naturally

## Decision

Use a **Signal Bus + Autoload Services** architecture:

1. **Autoload singletons** for stateful service systems (always-available, scene-independent)
2. **Godot signals** for event communication between systems (decoupled, observable)
3. **Resource files (.tres)** for game data (data-driven, inspector-editable)
4. **Scene composition** for gameplay entities (items, player)

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                   AUTOLOAD LAYER                     │
│  (Always available, scene-independent singletons)    │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │  Audio    │ │  Item    │ │   GameEvents      │   │
│  │  Manager  │ │  Registry│ │   (Signal Bus)     │   │
│  └──────────┘ └──────────┘ └───────────────────┘   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                  SCENE TREE LAYER                     │
│  (Created/destroyed per run, managed by RunManager)  │
│                                                      │
│  ┌──────────┐   ┌───────────┐   ┌───────────────┐  │
│  │  Player   │   │   Item    │   │   Rain VFX    │  │
│  │Controller │   │  Spawner  │   │   System      │  │
│  │  + Input  │   │  + Items  │   │               │  │
│  └─────┬─────┘   └─────┬─────┘   └───────────────┘  │
│        │               │                             │
│        └───────┬───────┘                             │
│                ▼                                      │
│  ┌─────────────────────────┐                         │
│  │  Collection & Avoidance │                         │
│  │  (Area2D overlap logic) │                         │
│  └────────────┬────────────┘                         │
│               │ emits signals via GameEvents          │
│               ▼                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  Score   │ │  Lives   │ │  Streak  │            │
│  │  System  │ │  System  │ │ Multiplier│            │
│  └──────────┘ └──────────┘ └──────────┘            │
│               │                                      │
│               ▼                                      │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐            │
│  │  HUD     │ │Game Juice│ │  Run     │            │
│  │          │ │  System  │ │ Summary  │            │
│  └──────────┘ └──────────┘ └──────────┘            │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│                  DATA LAYER                           │
│  (Godot Resources — .tres files in assets/data/)     │
│                                                      │
│  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │
│  │ ItemDef  │ │ Difficulty│ │  Streak Threshold │   │
│  │ Resources│ │  Config  │ │     Config        │   │
│  └──────────┘ └──────────┘ └───────────────────┘   │
└─────────────────────────────────────────────────────┘
```

### Key Design Decisions

**1. Central Signal Bus (GameEvents autoload)**

A single autoload `GameEvents` declares all cross-system signals. Systems emit and connect through this bus rather than directly referencing each other.

```gdscript
# game_events.gd (Autoload)
extends Node

signal item_collected(item_def: ItemDef)
signal item_hit(item_def: ItemDef)
signal streak_changed(count: int, multiplier: float)
signal streak_milestone(tier: int, multiplier: float)
signal streak_reset(previous_streak: int)
signal score_changed(total: int, earned: int)
signal life_lost(current_lives: int, damage: int)
signal lives_depleted
signal run_started
signal run_ended(run_stats: Dictionary)
```

**Why a bus instead of direct signals?** In a 16-system game, direct signal wiring creates a spider web. The bus provides a single connection point. Any system can emit or listen without knowing who's on the other end.

**2. Autoload Services (3 singletons)**

| Autoload | Responsibility | Why Autoload? |
|----------|---------------|---------------|
| `GameEvents` | Signal bus | Must survive scene changes, all systems connect to it |
| `AudioManager` | Music, ambience, SFX | Music/rain must play continuously across all scenes |
| `ItemRegistry` | Item data lookup | Data loaded once at startup, queried by many systems |

**Everything else lives in the scene tree** — Player, Spawner, Score, Lives, Streak, HUD, etc. are nodes created and destroyed per run by the RunManager (which is a scene-tree node, not an autoload).

**3. Data Layer (Godot Resources)**

All tuning values and game data use custom `Resource` classes saved as `.tres` files:
- `ItemDef` — per-item properties (point value, rarity, speed, hitbox, feedback tag)
- `DifficultyConfig` — ramp duration, ease curve, multiplier ranges
- `StreakConfig` — threshold/multiplier pairs

Resources are loaded by `ItemRegistry` at startup or preloaded by individual systems.

### Key Interfaces

**GameEvents signal contracts** (defined above) — these are the primary system boundaries.

**ItemRegistry API:**
```gdscript
func get_item(id: StringName) -> ItemDef
func get_items_by_category(category: ItemDef.Category) -> Array[ItemDef]
func get_spawn_table() -> Array[ItemDef]
```

**AudioManager API:**
```gdscript
func play_sfx(tag: StringName) -> void
func set_streak(count: int) -> void
func set_state(state: AudioState) -> void
```

## Alternatives Considered

### Alternative 1: Direct Signal Wiring (No Bus)
- **Description**: Each system declares its own signals. Consumers connect directly: `collection_system.item_collected.connect(score_system._on_item_collected)`.
- **Pros**: No central singleton. Godot-native pattern. Signals are type-safe per-node.
- **Cons**: Every consumer needs a reference to the emitter. Wiring logic scattered across `_ready()` functions. Adding a new listener requires modifying the emitter's scene or a parent's wiring code. With 16 systems, this becomes a maintenance burden.
- **Rejection Reason**: Too much coupling for the number of systems. Works well for 3-4 systems, doesn't scale to 16.

### Alternative 2: Full ECS / DOTS-style Architecture
- **Description**: Separate data (components) from behavior (systems). Use arrays of structs for items, process them in batch.
- **Pros**: Maximum performance for large entity counts. Clean data/logic separation.
- **Cons**: Overkill for a game with <50 active entities. Fights Godot's scene/node model. Requires custom framework code. GDScript is not optimized for data-oriented patterns.
- **Rejection Reason**: Vibe Money is a simple game. Node/scene architecture is more maintainable and performant enough.

### Alternative 3: State Machine Architecture
- **Description**: A hierarchical state machine drives the entire game flow. Each state owns a set of active systems.
- **Pros**: Very explicit about what's active when. Good for complex multi-mode games.
- **Cons**: Only 3 real states (Menu, Gameplay, Summary). The overhead of a formal HSM is not justified. Individual systems already have their own simple state management.
- **Rejection Reason**: The RunManager already handles the 3 states adequately. A formal HSM adds complexity without benefit.

## Consequences

### Positive
- **Decoupled systems**: Any system can be removed, added, or modified without touching others. Just connect/disconnect from GameEvents.
- **Testable**: Each system can be tested in isolation by emitting fake signals on GameEvents.
- **Data-driven**: Adding new item types requires only a new `.tres` file — no code changes.
- **Godot-native**: Uses Godot's built-in patterns (signals, autoloads, resources, scenes). No custom framework.
- **Simple mental model**: "Autoloads are services. Signals flow through the bus. Data lives in resources."

### Negative
- **Signal bus is a god object**: `GameEvents` knows about every event in the game. In a larger project this would be a code smell. Acceptable for 16 systems.
- **No compile-time wiring checks**: If a system connects to a signal that's been renamed, it fails at runtime. Mitigated by GDScript's static typing and consistent signal naming.
- **3 autoloads add to startup**: Negligible for this game's scale (<10ms total).

### Risks
- **Signal ordering**: If two systems both listen to `item_collected` and one depends on the other's state change, signal processing order matters. **Mitigation**: Document expected order in GDDs. For the Score→Streak dependency, Score reads the multiplier synchronously during its handler — no ordering issue.
- **Memory leaks from forgotten disconnects**: If a scene-tree system is freed without disconnecting from GameEvents. **Mitigation**: Use `connect(..., CONNECT_ONE_SHOT)` where appropriate, or disconnect in `_exit_tree()`.

## Performance Implications
- **CPU**: Negligible. Signal dispatch is O(n) where n = connected listeners (max ~5 per signal). Total per-frame signal processing estimated <0.1ms.
- **Memory**: 3 autoload singletons + signal connections. Estimated <1KB overhead.
- **Load Time**: ItemRegistry loads 6 `.tres` files at startup. Estimated <10ms.
- **Network**: N/A (single-player game).

## Migration Plan
No existing production code — this is a greenfield architecture. The prototype in `prototypes/coin-catch-loop/` used inline scripts and hardcoded values. Production code will be built fresh following this architecture.

## Validation Criteria
1. Any system can be disabled (node removed from scene tree) without crashing other systems
2. Adding a new item type requires only a new `.tres` file and no code changes to unrelated systems
3. Unit tests can emit signals on GameEvents and verify system responses without instantiating the full scene tree
4. Total autoload initialization completes in <50ms
5. Signal processing overhead stays under 0.2ms per frame at peak event density

## Related Decisions
- All 16 MVP system GDDs in `design/gdd/` define their signal interfaces and dependencies
- `design/gdd/item-database.md` — defines the ItemDef Resource schema
- `design/gdd/audio-manager.md` — defines the AudioManager autoload API
- `design/gdd/collection-avoidance.md` — primary signal emitter for gameplay events
