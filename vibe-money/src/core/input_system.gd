## Abstracts all player input into a single horizontal direction value.
## Outputs input_direction: float from -1.0 (left) to 1.0 (right).
## See design/gdd/input-system.md for full specification.
class_name InputSystem
extends Node

## Pixels of drag needed to reach full speed (touch/mouse).
@export var drag_sensitivity: float = 100.0
## Gamepad stick deadzone threshold.
@export var stick_deadzone: float = 0.15

## Current normalized input direction. Read this from Player Controller.
var input_direction: float = 0.0

var _enabled: bool = true
var _is_dragging: bool = false
var _drag_origin_x: float = 0.0


func enable() -> void:
	_enabled = true


func disable() -> void:
	_enabled = false
	input_direction = 0.0
	_is_dragging = false


func _unhandled_input(event: InputEvent) -> void:
	if not _enabled:
		return

	# Touch drag-to-slide
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed:
			_is_dragging = true
			_drag_origin_x = touch.position.x
		else:
			_is_dragging = false

	elif event is InputEventScreenDrag:
		if _is_dragging:
			var drag := event as InputEventScreenDrag
			input_direction = clampf((drag.position.x - _drag_origin_x) / drag_sensitivity, -1.0, 1.0)
			return

	# Mouse drag (PC playtesting)
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				_is_dragging = true
				_drag_origin_x = mb.position.x
			else:
				_is_dragging = false


func _physics_process(_delta: float) -> void:
	if not _enabled:
		input_direction = 0.0
		return

	# Mouse drag (continuous tracking)
	if _is_dragging and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var mouse_x := get_viewport().get_mouse_position().x
		input_direction = clampf((mouse_x - _drag_origin_x) / drag_sensitivity, -1.0, 1.0)
		return

	if not _is_dragging:
		# Keyboard input
		var kb_dir := Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		if kb_dir != 0.0:
			input_direction = kb_dir
			return

		# Gamepad (handled via action strengths with deadzone in project settings)
		# If no keyboard input, direction is 0
		input_direction = 0.0
