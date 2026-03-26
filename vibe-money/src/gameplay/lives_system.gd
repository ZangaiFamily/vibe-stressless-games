## Tracks remaining lives. Emits lives_depleted on game over.
## See design/gdd/lives-system.md for specification.
class_name LivesSystem
extends Node

@export var max_lives: int = 3

var current_lives: int = 3


func _ready() -> void:
	GameEvents.item_hit.connect(_on_item_hit)
	GameEvents.run_started.connect(_on_run_started)


func _on_item_hit(item_def: Resource) -> void:
	if item_def.damage <= 0:
		return

	current_lives = maxi(current_lives - item_def.damage, 0)
	GameEvents.life_lost.emit(current_lives, item_def.damage)

	if current_lives <= 0:
		GameEvents.lives_depleted.emit()


func _on_run_started() -> void:
	current_lives = max_lives
