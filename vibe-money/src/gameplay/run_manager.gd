## Orchestrates the lifecycle of a single gameplay run.
## See design/gdd/run-manager.md for specification.
class_name RunManager
extends Node

@export var summary_delay: float = 0.5
@export var retry_cooldown: float = 0.3

var _is_running: bool = false
var _run_start_time: float = 0.0
var _longest_streak: int = 0
var _coins_collected: int = 0
var _session_best: int = 0

## System references — set by main scene
var _score_system: Node
var _spawner: Node
var _difficulty: Node


func _ready() -> void:
	GameEvents.lives_depleted.connect(_on_lives_depleted)
	GameEvents.streak_changed.connect(_on_streak_changed)
	GameEvents.item_collected.connect(_on_item_collected)


func bind_systems(score: Node, spawner: Node, difficulty: Node) -> void:
	_score_system = score
	_spawner = spawner
	_difficulty = difficulty


func start_run() -> void:
	if _is_running:
		return

	_is_running = true
	_run_start_time = Time.get_ticks_msec() / 1000.0
	_longest_streak = 0
	_coins_collected = 0

	GameEvents.run_started.emit()
	AudioManager.set_state(AudioManager.AudioState.GAMEPLAY)


func end_run() -> void:
	if not _is_running:
		return

	_is_running = false

	var run_duration := Time.get_ticks_msec() / 1000.0 - _run_start_time
	var final_score: int = _score_system.total_score if _score_system else 0
	var is_high_score: bool = final_score > _session_best

	if is_high_score:
		_session_best = final_score

	var run_stats := {
		"final_score": final_score,
		"longest_streak": _longest_streak,
		"coins_collected": _coins_collected,
		"run_duration": run_duration,
		"is_high_score": is_high_score,
	}

	# Delay before showing summary
	await get_tree().create_timer(summary_delay).timeout

	AudioManager.set_state(AudioManager.AudioState.SUMMARY)
	GameEvents.run_ended.emit(run_stats)


func _on_lives_depleted() -> void:
	end_run()


func _on_streak_changed(count: int, _multiplier: float) -> void:
	if count > _longest_streak:
		_longest_streak = count


func _on_item_collected(_item_def: Resource) -> void:
	_coins_collected += 1
