# Game Concept: Vibe Money

*Created: 2026-03-26*
*Status: Draft*

---

## Elevator Pitch

> It's a chill collection game where you catch coins falling from a rainy sky
> while dodging hazards like bombs and junk — a zen, one-thumb experience
> wrapped in gorgeous lo-fi rainy-day aesthetics.

---

## Core Identity

| Aspect | Detail |
| ---- | ---- |
| **Genre** | Casual arcade / collection-avoidance |
| **Platform** | Cross-platform (PC, Mobile, Web, Console) |
| **Target Audience** | Casual players seeking relaxation, ages 16-35 |
| **Player Count** | Single-player |
| **Session Length** | 3-10 minutes |
| **Monetization** | Free-to-play (cosmetics, no pay-to-win) |
| **Estimated Scope** | Small (days to weeks) |
| **Comparable Titles** | Downwell (falling items), Alto's Odyssey (zen vibe), Ketchapp casual games |

---

## Core Fantasy

You're standing in a magical rain where money falls from the sky. The world
is soft, warm, and gentle — rain patters on your umbrella, coins clink as
you catch them, and the city glows behind you in muted neon. It's the
fantasy of effortless abundance — just stand in the right place and wealth
flows to you. But the sky isn't all generous — dodge the junk, keep your
streak, and watch your collection grow.

---

## Unique Hook

It's like a classic "catch the falling items" game, AND ALSO wrapped in a
lo-fi rainy-day aesthetic with tactile audio feedback that makes every coin
feel like ASMR. The vibe IS the game — the collecting is just an excuse to
stay in this world.

---

## Player Experience Analysis (MDA Framework)

### Target Aesthetics (What the player FEELS)

| Aesthetic | Priority | How We Deliver It |
| ---- | ---- | ---- |
| **Sensation** (sensory pleasure) | 1 | Rain sounds, coin clinks, smooth animations, satisfying screen-shake on catches |
| **Submission** (relaxation, comfort zone) | 2 | Low-stress pacing, forgiving gameplay, ambient rain soundtrack |
| **Challenge** (obstacle course, mastery) | 3 | Increasing hazard frequency, streak multipliers, leaderboards |
| **Expression** (self-expression, creativity) | 4 | Unlockable characters, umbrellas, rain effects, backgrounds |
| **Fantasy** (make-believe, role-playing) | 5 | "Money rain" power fantasy, cozy world |
| **Discovery** (exploration, secrets) | 6 | Rare coin types, hidden item events, seasonal themes |
| **Narrative** | N/A | — |
| **Fellowship** | N/A | — |

### Key Dynamics (Emergent player behaviors)

- Players develop a rhythm of movement — weaving between hazards while
  scooping coin clusters, creating a flow state
- Players chase streaks (consecutive catches without hitting hazards),
  creating self-imposed challenge in a low-stakes environment
- Players linger in sessions longer than intended because the ambience
  is pleasant — "just one more round"

### Core Mechanics (Systems we build)

1. **Horizontal movement** — Player slides left/right to position under falling items
2. **Item spawning system** — Coins and hazards spawn from the top with varying patterns
3. **Collection/avoidance** — Coins are caught, hazards must be dodged
4. **Streak multiplier** — Consecutive catches boost score; hitting a hazard resets it
5. **Progression/unlocks** — Coins earned unlock cosmetics and new environments

---

## Player Motivation Profile

### Primary Psychological Needs Served

| Need | How This Game Satisfies It | Strength |
| ---- | ---- | ---- |
| **Autonomy** | Player chooses when to risk grabbing a coin near a hazard vs. playing safe | Supporting |
| **Competence** | Streak multipliers and high scores show growing skill; patterns become readable | Core |
| **Relatedness** | Leaderboards, sharing high scores / rare catches | Minimal |

### Player Type Appeal (Bartle Taxonomy)

- [x] **Achievers** — High scores, coin totals, unlock completion percentage
- [ ] **Explorers** — Rare items and seasonal events provide some discovery
- [ ] **Socializers** — Minimal; leaderboard sharing only
- [ ] **Killers/Competitors** — Not a competitive game

### Flow State Design

- **Onboarding curve**: First 30 seconds are coins only — pure catching, no hazards. Hazards fade in gently over the first minute.
- **Difficulty scaling**: Hazard frequency and speed increase over time within a run. Early runs are very forgiving.
- **Feedback clarity**: Score counter, streak counter, coin sound escalation (pitch rises with streak), screen glow intensifies.
- **Recovery from failure**: Hitting a hazard resets streak but does NOT end the run. Run ends only after 3 hits (lives system) or a timer. Failure is a gentle "aww" not a harsh punishment.

---

## Core Loop

### Moment-to-Moment (30 seconds)
Slide left and right. Coins fall — catch them. Hazards fall — dodge them.
Every catch makes a satisfying *clink* that rises in pitch with your streak.
The rain keeps falling. You keep moving. It's meditative.

### Short-Term (5-15 minutes)
A single run lasts 2-5 minutes. Difficulty ramps smoothly — more hazards,
faster drops, but also rarer high-value coins appear. Each run ends with a
satisfying summary: coins earned, longest streak, rare finds. "One more run"
is easy because runs are short.

### Session-Level (30-120 minutes)
Across multiple runs, players accumulate coins toward their next unlock
(new umbrella, new character skin, new background scene). Each session
feels like progress. Natural stopping points after unlocking something new.

### Long-Term Progression
- Unlock new characters (different hitbox sizes, visual style)
- Unlock new environments (city rooftop, countryside, beach, neon alley)
- Unlock umbrella skins and rain effects (golden rain, cherry blossom rain)
- Seasonal events with limited-time items
- Lifetime coin counter and achievement milestones

### Retention Hooks
- **Curiosity**: "What does the next environment look like?" Unlockable backgrounds keep things fresh
- **Investment**: Lifetime coin counter, collection completion percentage
- **Social**: Share screenshots of rare catches or beautiful scenes
- **Mastery**: Beat your own high score and longest streak

---

## Game Pillars

### Pillar 1: Vibe First
Every design decision must serve the mood. If a feature is fun but breaks the
chill atmosphere, it gets cut or redesigned.

*Design test*: "If we're debating between a flashy combo system and a subtle
screen glow, this pillar says we choose the glow."

### Pillar 2: Effortless to Play
One input (horizontal movement), zero tutorials needed, pick up and play in
2 seconds. Complexity comes from mastery, not from controls.

*Design test*: "If a feature requires a tutorial popup to explain, it's too
complex. Redesign it until it's self-evident."

### Pillar 3: Juicy Feedback
Every action the player takes should feel satisfying through sound, animation,
and visual feedback. Catching a coin should FEEL good — not just increment a
number.

*Design test*: "If we're debating between adding a new feature or polishing
the feel of catching coins, this pillar says we polish the feel."

### Pillar 4: Respect the Player's Time
Short sessions, clear progress, no predatory monetization, no forced ads.
The player should leave feeling good, not manipulated.

*Design test*: "If a retention mechanic feels manipulative rather than
genuinely rewarding, cut it."

### Anti-Pillars (What This Game Is NOT)

- **NOT competitive/stressful**: No PvP, no time pressure that creates anxiety, no fail states that feel punishing. Stress kills the vibe.
- **NOT content-heavy**: Not a game with 500 levels, story modes, or dialogue trees. Content is environmental and cosmetic.
- **NOT skill-gated**: A player with zero gaming experience should be able to enjoy this. High skill is rewarded but not required.

---

## Inspiration and References

| Reference | What We Take From It | What We Do Differently | Why It Matters |
| ---- | ---- | ---- | ---- |
| Alto's Odyssey | Zen atmosphere, gorgeous visuals, simple controls | Our game is vertical (falling items) not horizontal (endless runner) | Proves "vibe games" have a real audience |
| Downwell | Falling-object mechanics, black/white/red aesthetic clarity | We're chill not intense; collecting not shooting | Validates the "things fall, you react" loop |
| Neko Atsume | Passive collection, cozy aesthetic, low-stress progression | Our game has active gameplay, not idle waiting | Shows casual audiences love collectible progression |

**Non-game inspirations**: Lo-fi hip-hop streams (aesthetic, mood), rainy window videos on YouTube (ambient visual inspiration), Japanese vending machine alleyways at night (visual mood board).

---

## Target Player Profile

| Attribute | Detail |
| ---- | ---- |
| **Age range** | 16-35 |
| **Gaming experience** | Casual to mid-core |
| **Time availability** | 5-15 minute sessions during commutes, breaks, or before bed |
| **Platform preference** | Mobile primary, but would play on PC/web too |
| **Current games they play** | Alto's Odyssey, Monument Valley, casual puzzle games, lo-fi background games |
| **What they're looking for** | A beautiful, stress-free experience that feels good to interact with |
| **What would turn them away** | Aggressive ads, pay-to-win, high difficulty, cluttered UI |

---

## Technical Considerations

| Consideration | Assessment |
| ---- | ---- |
| **Recommended Engine** | Godot 4.6 — lightweight, 2D-native, open source, perfect for small-scope casual games, good mobile export |
| **Key Technical Challenges** | Achieving buttery-smooth 60fps with particle rain effects on mobile; audio system for responsive layered sound design |
| **Art Style** | 2D illustrated, soft color palette, parallax backgrounds, particle rain |
| **Art Pipeline Complexity** | Medium (custom 2D illustrations, particle effects, UI polish) |
| **Audio Needs** | Music-heavy — ambient lo-fi soundtrack, layered rain sounds, per-item SFX with pitch variation |
| **Networking** | None (local leaderboard; online leaderboard as stretch goal) |
| **Content Volume** | 5-8 environments, 10-15 character/umbrella skins, 8-12 hazard types, 5-6 coin types |
| **Procedural Systems** | Procedural item spawning patterns with difficulty curves |

---

## Risks and Open Questions

### Design Risks
- Core loop may feel repetitive after 15-20 minutes — mitigate with environment variety and escalating hazard patterns
- "Catch coins avoid hazards" is a well-trodden genre — the vibe/polish must be genuinely exceptional to stand out

### Technical Risks
- Particle-heavy rain effects on low-end mobile devices — need to profile early and have a "lite rain" fallback
- Audio layering (rain + music + SFX) may require careful mixing to avoid muddiness

### Market Risks
- Casual mobile market is saturated — discoverability is the biggest challenge
- Free-to-play cosmetics-only model may not generate enough revenue without a large player base

### Scope Risks
- Art polish is critical to the concept — if art quality isn't high enough, the "vibe" pillar fails
- Scope creep into "just one more skin" cosmetic content could delay launch

### Open Questions
- How many hits before run ends? (3 lives? Timer-based? Infinite with score penalty?) — prototype all three
- Should there be power-ups (magnet, shield, slow-mo)? — prototype with and without
- Touch controls: tap-to-move, drag-to-slide, or tilt? — user test all three on mobile

---

## MVP Definition

**Core hypothesis**: Players find the coin-catching loop satisfying and relaxing
for 5+ minute sessions, driven primarily by the audiovisual feedback and rainy-day
atmosphere.

**Required for MVP**:
1. Player horizontal movement (touch/keyboard)
2. Falling coins (3 types: bronze, silver, gold) with collection feedback
3. Falling hazards (3 types: bomb, poop, spike) with avoidance/hit feedback
4. One complete environment with rain particle effect
5. Score display, streak counter, and run-end summary screen
6. Lo-fi ambient soundtrack + rain audio + coin/hazard SFX
7. Basic difficulty ramping (hazard frequency increases over time)

**Explicitly NOT in MVP** (defer to later):
- Multiple environments/backgrounds
- Cosmetic unlocks and shop
- Leaderboards
- Power-ups
- Achievements
- Seasonal events

### Scope Tiers (if budget/time shrinks)

| Tier | Content | Features | Timeline |
| ---- | ---- | ---- | ---- |
| **MVP** | 1 environment, 3 coin types, 3 hazards | Core loop + scoring | 2-3 days |
| **Vertical Slice** | 1 polished environment, 5 coin types, 6 hazards | Core + unlockable cosmetics + power-ups | 1 week |
| **Alpha** | 3 environments, all items | All features, rough UI | 1.5-2 weeks |
| **Full Vision** | 5-8 environments, all cosmetics, events | Full polish, store, leaderboards | 3-4 weeks |

---

## Next Steps

- [ ] Get concept approval from creative-director
- [ ] Configure Godot 4.6 as the engine (`/setup-engine godot 4.6`)
- [ ] Validate this document (`/design-review design/gdd/game-concept.md`)
- [ ] Decompose into systems (`/map-systems`)
- [ ] Author per-system GDDs (`/design-system`)
- [ ] Prototype core loop (`/prototype coin-catch-loop`)
- [ ] Playtest the prototype (`/playtest-report`)
- [ ] Plan first sprint (`/sprint-plan new`)
