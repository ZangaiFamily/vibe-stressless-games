## Central signal bus for cross-system communication.
## All gameplay events flow through here so systems stay decoupled.
## See ADR-0001 for architecture rationale.
extends Node

# --- Collection & Avoidance signals ---
signal item_collected(item_def: Resource)
signal item_hit(item_def: Resource)

# --- Streak signals ---
signal streak_changed(count: int, multiplier: float)
signal streak_milestone(tier: int, multiplier: float)
signal streak_reset(previous_streak: int)

# --- Score signals ---
signal score_changed(total: int, earned: int)

# --- Lives signals ---
signal life_lost(current_lives: int, damage: int)
signal lives_depleted

# --- Run lifecycle signals ---
signal run_started
signal run_ended(run_stats: Dictionary)

# --- Player signals ---
signal player_moved(velocity: Vector2)

# --- Navigation signals ---
signal return_to_menu
