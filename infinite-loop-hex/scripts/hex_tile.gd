## A single hexagonal tile with connection lines.
## Stores state as a 6-bit connection mask and renders via _draw().
extends Node2D

const HexMathClass = preload("res://scripts/hex_math.gd")

signal rotated

## The 6-bit connection mask. Bit i set = connection on edge i.
var connection_mask: int = 0
## The hex size used for drawing.
var hex_size: float = 50.0
## Reference to the grid config for colors/widths.
var config: Resource
## Whether all of this tile's connections currently match their neighbors.
var is_matched: bool = false
## Whether the entire puzzle is solved.
var is_won: bool = false
## Whether a rotation animation is in progress.
var is_animating: bool = false
## Whether the mouse is hovering over this tile.
var is_hovered: bool = false
## Current visual rotation angle during animation (radians).
var _visual_rotation: float = 0.0
## Whether current animation is clockwise.
var _rotating_cw: bool = true
## Cached hex corners for hit detection.
var _corners: PackedVector2Array


func _ready() -> void:
	_corners = HexMathClass.get_hex_corners(hex_size)


func setup(p_mask: int, p_size: float, p_config: Resource) -> void:
	connection_mask = p_mask
	hex_size = p_size
	config = p_config
	_corners = HexMathClass.get_hex_corners(hex_size)
	queue_redraw()


func _draw() -> void:
	if not config:
		return

	# Draw hex fill on hover
	if is_hovered and not is_won:
		draw_colored_polygon(_corners, Color(1, 1, 1, 0.08))

	# Draw hex outline
	var outline_points := PackedVector2Array(_corners)
	outline_points.append(_corners[0])  # Close the polygon
	draw_polyline(outline_points, config.hex_outline_color, config.outline_width, true)

	# Determine line color
	var line_color: Color
	if is_won:
		line_color = config.line_color_won
	elif is_matched:
		line_color = config.line_color_solved
	else:
		line_color = config.line_color_unsolved

	# Draw connection lines from center to edge midpoints
	for edge in range(6):
		if connection_mask & (1 << edge):
			var midpoint: Vector2 = HexMathClass.get_edge_midpoint(hex_size, edge)
			# Apply visual rotation during animation
			if _visual_rotation != 0.0:
				midpoint = midpoint.rotated(_visual_rotation)
			draw_line(Vector2.ZERO, midpoint, line_color, config.line_width, true)
			# Draw dot at endpoint
			draw_circle(midpoint, config.dot_radius, line_color)

	# Draw center dot if tile has any connections
	if connection_mask > 0:
		draw_circle(Vector2.ZERO, config.dot_radius, line_color)


## Rotate the tile 60 degrees. Clockwise if cw is true, counterclockwise otherwise.
func rotate_tile(cw: bool = true) -> void:
	if is_animating:
		return

	is_animating = true
	_rotating_cw = cw
	AudioManager.play_rotate(cw)
	var target_angle: float = TAU / 6.0 if cw else -TAU / 6.0
	var tween: Tween = create_tween()
	tween.tween_property(self, "_visual_rotation", target_angle, config.rotation_duration)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_callback(_finish_rotation)


func _finish_rotation() -> void:
	_visual_rotation = 0.0
	if _rotating_cw:
		connection_mask = HexMathClass.rotate_mask_cw(connection_mask)
	else:
		# CCW = 5 steps CW
		connection_mask = HexMathClass.rotate_mask(connection_mask, 5)
	is_animating = false
	queue_redraw()
	rotated.emit()


func _process(_delta: float) -> void:
	if is_animating:
		queue_redraw()


## Check if a local point is inside this hex tile.
func is_point_inside(local_point: Vector2) -> bool:
	return Geometry2D.is_point_in_polygon(local_point, _corners)


func set_hovered(hovered: bool) -> void:
	if is_hovered != hovered:
		is_hovered = hovered
		if hovered:
			AudioManager.play_hover()
		queue_redraw()


func set_matched(matched: bool) -> void:
	if is_matched != matched:
		is_matched = matched
		queue_redraw()


func set_won(won: bool) -> void:
	if is_won != won:
		is_won = won
		queue_redraw()
