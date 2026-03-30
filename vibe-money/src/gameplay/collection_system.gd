## Detects item-player overlaps and emits collection/hit signals.
## See design/gdd/collection-avoidance.md for specification.
class_name CollectionSystem
extends Node

@export var invincibility_duration: float = 1.0
@export var start_grace_period: float = 1.5  # Invincibility at run start

var _invincible: bool = false
var _invincibility_timer: float = 0.0
var _enabled: bool = false
var _player_area: Area2D


func _ready() -> void:
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.run_ended.connect(_on_run_ended)


func setup(player_area: Area2D) -> void:
	_player_area = player_area
	_player_area.area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	if _invincible:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			_invincible = false
			# Stop flashing
			if _player_area:
				_player_area.get_parent().modulate.a = 1.0


func _on_area_entered(area: Area2D) -> void:
	if not _enabled:
		return

	if not area.has_method("deactivate"):
		return
	var falling_item = area
	if not falling_item.item_def:
		return

	var item_def = falling_item.item_def

	if item_def.category == 0:  # 0 = ItemDef.Category.COIN
		GameEvents.item_collected.emit(item_def)
		falling_item.deactivate()

	elif item_def.category == 1:  # 1 = ItemDef.Category.HAZARD
		if _invincible:
			return  # Pass through during i-frames

		GameEvents.item_hit.emit(item_def)
		falling_item.deactivate()

		# Start invincibility
		_invincible = true
		_invincibility_timer = invincibility_duration
		_start_flash()


func _start_flash() -> void:
	if not _player_area:
		return
	var player_node := _player_area.get_parent()
	var tween := create_tween()
	tween.set_loops(int(invincibility_duration / 0.15))
	tween.tween_property(player_node, "modulate:a", 0.3, 0.075)
	tween.tween_property(player_node, "modulate:a", 1.0, 0.075)


func _on_run_started() -> void:
	_enabled = true
	# Grace period: player is invincible for the first moments of a run
	_invincible = true
	_invincibility_timer = start_grace_period


func _on_run_ended(_stats: Dictionary) -> void:
	_enabled = false
	_invincible = false
