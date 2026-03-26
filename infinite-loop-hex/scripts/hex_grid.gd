## Manages the hexagonal grid of tiles.
## Handles tile creation, positioning, input, and win condition checking.
extends Node2D

const HexMathClass = preload("res://scripts/hex_math.gd")
const PuzzleGeneratorClass = preload("res://scripts/puzzle_generator.gd")

signal puzzle_solved
signal progress_updated(matched: int, total: int)

var config: Resource
## Maps Vector2i(q, r) -> tile node.
var tiles: Dictionary = {}
var _hex_tile_scene: PackedScene
var _game_won: bool = false


func _ready() -> void:
	_hex_tile_scene = preload("res://scenes/hex_tile.tscn")


## Generate a new puzzle with the given config.
func new_puzzle(p_config: Resource) -> void:
	config = p_config
	_game_won = false
	_clear_tiles()

	# Create tile nodes for each hex coordinate
	var coords: Array = HexMathClass.get_hex_ring(config.grid_radius)
	for coord in coords:
		var tile = _hex_tile_scene.instantiate()
		tile.setup(0, config.hex_size, config)
		tile.position = HexMathClass.hex_to_pixel(coord, config.hex_size)
		tile.rotated.connect(_on_tile_rotated)
		add_child(tile)
		tiles[coord] = tile

	# Generate and apply puzzle
	PuzzleGeneratorClass.generate(tiles, config)

	# Update visual state
	_update_all_matched()


func _clear_tiles() -> void:
	for tile in tiles.values():
		tile.queue_free()
	tiles.clear()


func _unhandled_input(event: InputEvent) -> void:
	if _game_won:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			var local_pos: Vector2 = to_local(get_global_mouse_position())
			var hex_coord: Vector2i = HexMathClass.pixel_to_hex(local_pos, config.hex_size)
			if hex_coord in tiles:
				var tile = tiles[hex_coord]
				if tile.is_point_inside(local_pos - tile.position):
					if event.button_index == MOUSE_BUTTON_LEFT:
						tile.rotate_tile(true)
					elif event.button_index == MOUSE_BUTTON_RIGHT:
						tile.rotate_tile(false)

	# Note: hover is handled in _process() to avoid stale state when UI consumes mouse events


func _process(_delta: float) -> void:
	if tiles.is_empty() or _game_won:
		return
	var world_pos: Vector2 = get_global_mouse_position()
	var local_pos: Vector2 = to_local(world_pos)
	var hex_coord: Vector2i = HexMathClass.pixel_to_hex(local_pos, config.hex_size)
	for coord in tiles:
		var tile = tiles[coord]
		var is_over: bool = coord == hex_coord and tile.is_point_inside(local_pos - tile.position)
		tile.set_hovered(is_over)


func _on_tile_rotated() -> void:
	var old_matched: int = _count_matched()
	_update_all_matched()
	var new_matched: int = _count_matched()
	if new_matched > old_matched:
		AudioManager.play_match()
	elif new_matched < old_matched:
		AudioManager.play_unmatch()
	if _check_win_condition():
		_game_won = true
		for tile in tiles.values():
			tile.set_won(true)
		AudioManager.play_win()
		puzzle_solved.emit()


func _count_matched() -> int:
	var count: int = 0
	for coord in tiles:
		if _is_tile_matched(coord):
			count += 1
	return count


## Update the matched state of every tile based on current connections.
func _update_all_matched() -> void:
	var matched_count: int = 0
	var total_count: int = tiles.size()
	for coord in tiles:
		var tile = tiles[coord]
		var matched: bool = _is_tile_matched(coord)
		tile.set_matched(matched)
		if matched:
			matched_count += 1
	progress_updated.emit(matched_count, total_count)


## Check if all of a single tile's connections match their neighbors.
func _is_tile_matched(coord: Vector2i) -> bool:
	var tile = tiles[coord]
	if tile.connection_mask == 0:
		return true  # Empty tiles are always matched

	for edge in range(6):
		if tile.connection_mask & (1 << edge):
			var neighbor_coord: Vector2i = HexMathClass.get_neighbor(coord, edge)
			if neighbor_coord not in tiles:
				return false  # Connection points outside the grid
			var neighbor = tiles[neighbor_coord]
			var opposite: int = HexMathClass.OPPOSITE_EDGE[edge]
			if not (neighbor.connection_mask & (1 << opposite)):
				return false  # Neighbor doesn't have matching connection
	return true


## Check if the entire puzzle is solved (all tiles matched).
func _check_win_condition() -> bool:
	for coord in tiles:
		if not _is_tile_matched(coord):
			return false
	return true
