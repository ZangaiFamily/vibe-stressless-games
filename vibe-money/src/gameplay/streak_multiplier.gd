## Tracks consecutive coin catches and provides score multiplier.
## See design/gdd/streak-multiplier.md for specification.
class_name StreakMultiplier
extends Node

var streak_count: int = 0

var _thresholds: Array[Dictionary] = [
	{"streak": 5, "multiplier": 1.5},
	{"streak": 10, "multiplier": 2.0},
	{"streak": 20, "multiplier": 3.0},
	{"streak": 50, "multiplier": 5.0},
]


func _ready() -> void:
	GameEvents.item_collected.connect(_on_item_collected)
	GameEvents.item_hit.connect(_on_item_hit)
	GameEvents.run_started.connect(_on_run_started)


func get_multiplier() -> float:
	for i in range(_thresholds.size() - 1, -1, -1):
		if streak_count >= _thresholds[i]["streak"]:
			return _thresholds[i]["multiplier"]
	return 1.0


func _on_item_collected(_item_def: Resource) -> void:
	var prev_multiplier := get_multiplier()
	streak_count += 1
	var new_multiplier := get_multiplier()

	GameEvents.streak_changed.emit(streak_count, new_multiplier)
	AudioManager.set_streak(streak_count)

	# Check for milestone crossing
	if new_multiplier > prev_multiplier:
		var tier := 0
		for i in _thresholds.size():
			if streak_count >= _thresholds[i]["streak"]:
				tier = i + 1
		GameEvents.streak_milestone.emit(tier, new_multiplier)


func _on_item_hit(_item_def: Resource) -> void:
	var prev_streak := streak_count
	if prev_streak > 0:
		streak_count = 0
		AudioManager.set_streak(0)
		GameEvents.streak_changed.emit(0, 1.0)
		GameEvents.streak_reset.emit(prev_streak)


func _on_run_started() -> void:
	streak_count = 0
	AudioManager.set_streak(0)
	GameEvents.streak_changed.emit(0, 1.0)
