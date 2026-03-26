## Entry point for the Infinity Loop HEX game.
## Wires together the hex grid, puzzle generator, and UI.
extends Node2D

@onready var hex_grid: Node2D = $HexGrid
@onready var game_ui: Control = $CanvasLayer/GameUI
@onready var camera: Camera2D = $Camera2D

var config: Resource


func _ready() -> void:
	config = preload("res://resources/config/grid_config.tres").duplicate()
	hex_grid.puzzle_solved.connect(_on_puzzle_solved)
	hex_grid.progress_updated.connect(_on_progress_updated)
	game_ui.new_game_requested.connect(_on_new_game_requested)
	_start_new_game()


func _start_new_game() -> void:
	hex_grid.new_puzzle(config)
	_center_camera()
	AudioManager.play_new_game()


func _center_camera() -> void:
	camera.position = Vector2.ZERO
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var grid_extent: float = config.hex_size * (2.0 * config.grid_radius + 1) * 1.1
	var zoom_x: float = viewport_size.x / (grid_extent * 2.0)
	var zoom_y: float = viewport_size.y / (grid_extent * 2.0)
	var zoom_val: float = minf(zoom_x, zoom_y)
	camera.zoom = Vector2(zoom_val, zoom_val)


func _on_puzzle_solved() -> void:
	game_ui.show_win()


func _on_progress_updated(matched: int, total: int) -> void:
	game_ui.update_progress(matched, total)


func _on_new_game_requested(level_cfg: Dictionary) -> void:
	config.grid_radius = level_cfg["radius"]
	config.extra_connection_chance = level_cfg["extra_chance"]
	config.min_scramble_steps = level_cfg["min_scramble"]
	config.max_scramble_steps = level_cfg["max_scramble"]
	_start_new_game()
