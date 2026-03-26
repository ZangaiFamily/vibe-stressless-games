# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends Node

signal coin_collected(coin_data: Dictionary)
signal hazard_hit(hazard_type: String)
signal streak_changed(streak: int)
signal score_changed(score: int)
signal lives_changed(lives: int)
signal run_ended(stats: Dictionary)
signal run_started

# Run state
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var lives: int = 3
var total_coins: int = 0
var run_time: float = 0.0
var is_running: bool = false

# Difficulty
var difficulty: float = 0.0  # 0.0 to 1.0 over the run
const DIFFICULTY_RAMP_TIME := 120.0  # seconds to reach max difficulty

# Streak multiplier thresholds
const STREAK_MULTIPLIERS := {
	0: 1.0,
	5: 1.5,
	10: 2.0,
	20: 3.0,
	50: 5.0,
}


func _process(delta: float) -> void:
	if is_running:
		run_time += delta
		difficulty = minf(run_time / DIFFICULTY_RAMP_TIME, 1.0)


func start_run() -> void:
	score = 0
	streak = 0
	best_streak = 0
	lives = 3
	total_coins = 0
	run_time = 0.0
	difficulty = 0.0
	is_running = true
	run_started.emit()
	lives_changed.emit(lives)
	score_changed.emit(score)
	streak_changed.emit(streak)


func collect_coin(coin_data: Dictionary) -> void:
	if not is_running:
		return

	streak += 1
	if streak > best_streak:
		best_streak = streak

	var base_value: int = coin_data.get("value", 1)
	var multiplier := _get_streak_multiplier()
	var points := int(base_value * multiplier)
	score += points
	total_coins += 1

	coin_collected.emit(coin_data)
	streak_changed.emit(streak)
	score_changed.emit(score)


func hit_hazard(hazard_type: String) -> void:
	if not is_running:
		return

	streak = 0
	lives -= 1

	hazard_hit.emit(hazard_type)
	streak_changed.emit(streak)
	lives_changed.emit(lives)

	if lives <= 0:
		end_run()


func end_run() -> void:
	is_running = false
	var stats := {
		"score": score,
		"best_streak": best_streak,
		"total_coins": total_coins,
		"run_time": run_time,
		"difficulty_reached": difficulty,
	}
	run_ended.emit(stats)


func _get_streak_multiplier() -> float:
	var mult := 1.0
	for threshold: int in STREAK_MULTIPLIERS:
		if streak >= threshold:
			mult = STREAK_MULTIPLIERS[threshold]
	return mult


func get_streak_multiplier_display() -> float:
	return _get_streak_multiplier()
