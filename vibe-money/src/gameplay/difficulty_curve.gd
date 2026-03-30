## Controls how difficulty ramps over a single run.
## Feeds multipliers into ItemSpawner.
## See design/gdd/difficulty-curve.md for specification.
class_name DifficultyCurve
extends Node

@export var ramp_duration: float = 120.0
@export var ease_curve: float = 2.0
@export var max_spawn_rate_mult: float = 2.5
@export var max_speed_mult: float = 1.8
@export var min_hazard_ratio: float = 0.3
@export var max_hazard_ratio: float = 0.7
@export var score_speed_bonus_max: float = 0.6  # Extra speed from scoring
@export var score_speed_cap: float = 800.0  # Score at which bonus maxes out

var spawn_rate_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var hazard_ratio_modifier: float = 0.3

var _elapsed: float = 0.0
var _active: bool = false
var _current_score: int = 0

## Reference to spawner — set by RunManager or parent scene
var _spawner: Node


func _ready() -> void:
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.run_ended.connect(_on_run_ended)
	GameEvents.score_changed.connect(_on_score_changed)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	_elapsed += delta

	var raw_t := clampf(_elapsed / ramp_duration, 0.0, 1.0)
	var t := ease(raw_t, ease_curve)

	spawn_rate_multiplier = lerpf(1.0, max_spawn_rate_mult, t)
	var base_speed := lerpf(1.0, max_speed_mult, t)
	# Score-based speed bonus on top of time ramp
	var score_t := clampf(float(_current_score) / score_speed_cap, 0.0, 1.0)
	speed_multiplier = base_speed + score_speed_bonus_max * score_t
	hazard_ratio_modifier = lerpf(min_hazard_ratio, max_hazard_ratio, t)

	# Push to spawner
	if _spawner:
		_spawner.spawn_rate_multiplier = spawn_rate_multiplier
		_spawner.speed_multiplier = speed_multiplier
		_spawner.hazard_ratio_modifier = hazard_ratio_modifier


func bind_spawner(spawner: Node) -> void:
	_spawner = spawner


func _on_score_changed(total: int, _earned: int) -> void:
	_current_score = total


func _on_run_started() -> void:
	_active = true
	_elapsed = 0.0
	_current_score = 0
	spawn_rate_multiplier = 1.0
	speed_multiplier = 1.0
	hazard_ratio_modifier = min_hazard_ratio


func _on_run_ended(_stats: Dictionary) -> void:
	_active = false
