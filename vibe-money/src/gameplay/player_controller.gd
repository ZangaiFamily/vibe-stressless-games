## Converts input direction into physical character movement.
## See design/gdd/player-controller.md for specification.
class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 400.0
@export var acceleration: float = 2000.0
@export var deceleration: float = 1800.0
@export var collision_radius: float = 16.0
@export var player_y_percent: float = 0.85
@export var screen_margin: float = 8.0

var _enabled: bool = false
var _input_system: Node


func _ready() -> void:
	# Find children added programmatically by main scene
	_input_system = _find_child_of_type("InputSystem")
	_position_at_start()
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.run_ended.connect(_on_run_ended)


func _physics_process(delta: float) -> void:
	if not _enabled or not _input_system:
		return

	var input_dir: float = _input_system.input_direction
	var target_velocity_x: float = input_dir * move_speed

	if input_dir != 0.0:
		velocity.x = move_toward(velocity.x, target_velocity_x, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, deceleration * delta)

	move_and_slide()

	# Clamp to screen boundaries
	var vp_width := get_viewport_rect().size.x
	var left_bound := screen_margin + collision_radius
	var right_bound := vp_width - screen_margin - collision_radius
	position.x = clampf(position.x, left_bound, right_bound)

	# Zero velocity if clamped at edge
	if position.x <= left_bound or position.x >= right_bound:
		if signf(velocity.x) == signf(position.x - vp_width * 0.5):
			velocity.x = 0.0

	GameEvents.player_moved.emit(velocity)


func enable() -> void:
	_enabled = true
	if _input_system:
		_input_system.enable()


func disable() -> void:
	_enabled = false
	velocity = Vector2.ZERO
	if _input_system:
		_input_system.disable()


func reset_position() -> void:
	var vp_size := get_viewport_rect().size
	position = Vector2(vp_size.x * 0.5, vp_size.y * player_y_percent)
	velocity = Vector2.ZERO


func _position_at_start() -> void:
	reset_position()


func _find_child_of_type(type_name: String) -> Node:
	for child in get_children():
		if child.name == type_name:
			return child
	return null


func _on_run_started() -> void:
	reset_position()
	enable()


func _on_run_ended(_stats: Dictionary) -> void:
	disable()
