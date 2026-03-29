## Abstracts all player input into horizontal movement.
## Touch/mouse: direct follow (target_x). Keyboard: direction-based.
## See design/gdd/input-system.md for full specification.
class_name InputSystem
extends Node

## Gamepad stick deadzone threshold.
@export var stick_deadzone: float = 0.15

## Current normalized input direction for keyboard/gamepad.
var input_direction: float = 0.0
## Target X position in world space for direct follow (touch/mouse).
var target_x: float = -1.0
## True when touch/mouse is actively controlling position.
var is_direct_touch: bool = false

var _enabled: bool = true
var _is_touching: bool = false


func enable() -> void:
	_enabled = true


func disable() -> void:
	_enabled = false
	input_direction = 0.0
	is_direct_touch = false
	_is_touching = false
	target_x = -1.0


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	# Touch — direct follow
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_is_touching = true
			is_direct_touch = true
			target_x = touch.position.x
		else:
			_is_touching = false
			is_direct_touch = false

	elif event is InputEventScreenDrag:
		if _is_touching:
			var drag := event as InputEventScreenDrag
			target_x = drag.position.x

	# Mouse — direct follow (PC playtesting)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_touching = true
				is_direct_touch = true
				target_x = mb.position.x
			else:
				_is_touching = false
				is_direct_touch = false


func _physics_process(_delta: float) -> void:
	if not _enabled:
		input_direction = 0.0
		is_direct_touch = false
		return

	# Mouse continuous tracking for direct follow
	if _is_touching and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		target_x = get_viewport().get_mouse_position().x
		is_direct_touch = true
		return

	if not _is_touching:
		is_direct_touch = false
		# Keyboard input
		var kb_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		if kb_dir != 0.0:
			input_direction = kb_dir
			return

		# Gamepad / no input
		input_direction = 0.0
