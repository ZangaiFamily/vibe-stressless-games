## Tracks score during a run. Listens for collections, applies streak multiplier.
## See design/gdd/score-system.md for specification.
class_name ScoreSystem
extends Node

var total_score: int = 0
var _streak_system: Node


func _ready() -> void:
	GameEvents.item_collected.connect(_on_item_collected)
	GameEvents.run_started.connect(_on_run_started)


func bind_streak(streak: Node) -> void:
	_streak_system = streak


func _on_item_collected(item_def: Resource) -> void:
	var multiplier: float = _streak_system.get_multiplier() if _streak_system else 1.0
	var earned := int(item_def.point_value * multiplier)
	total_score += earned
	GameEvents.score_changed.emit(total_score, earned)


func _on_run_started() -> void:
	total_score = 0
	GameEvents.score_changed.emit(0, 0)
