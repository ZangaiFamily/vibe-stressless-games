## Generates solvable hex loop puzzles using a spanning tree approach.
## 1. Build a random spanning tree over the grid (guarantees connectivity).
## 2. Add extra random connections for variety (creates loops).
## 3. Scramble by randomly rotating each tile.

const HexMathClass = preload("res://scripts/hex_math.gd")


## Generate a puzzle by populating connection masks on existing tiles.
static func generate(tiles: Dictionary, config: Resource) -> void:
	if tiles.is_empty():
		return

	# Reset all masks
	for tile in tiles.values():
		tile.connection_mask = 0

	# Build spanning tree + extra connections
	_build_connections(tiles, config.extra_connection_chance)

	# Scramble: rotate each tile a random number of times
	_scramble(tiles, config)


## Build connections using randomized DFS spanning tree + extra edges.
static func _build_connections(tiles: Dictionary, extra_chance: float) -> void:
	var coords: Array = tiles.keys()
	if coords.is_empty():
		return

	# Randomized DFS for spanning tree
	var visited: Dictionary = {}
	var stack: Array = []
	var start: Vector2i = coords[randi() % coords.size()]
	stack.append(start)
	visited[start] = true

	while not stack.is_empty():
		var current: Vector2i = stack.back()

		# Get unvisited neighbors
		var unvisited: Array = []
		for dir in range(6):
			var neighbor: Vector2i = HexMathClass.get_neighbor(current, dir)
			if neighbor in tiles and neighbor not in visited:
				unvisited.append(dir)

		if unvisited.is_empty():
			stack.pop_back()
			continue

		# Pick random unvisited neighbor
		var dir: int = unvisited[randi() % unvisited.size()]
		var neighbor: Vector2i = HexMathClass.get_neighbor(current, dir)

		# Set connection bits on both tiles
		_connect(tiles, current, neighbor, dir)

		visited[neighbor] = true
		stack.append(neighbor)

	# Add extra connections for loops
	for coord in coords:
		for dir in range(6):
			var neighbor: Vector2i = HexMathClass.get_neighbor(coord, dir)
			if neighbor not in tiles:
				continue

			var already_connected: bool = bool(tiles[coord].connection_mask & (1 << dir))
			if already_connected:
				continue

			if randf() < extra_chance:
				_connect(tiles, coord, neighbor, dir)


## Set connection bits on both tiles for a given direction.
static func _connect(tiles: Dictionary, from: Vector2i, to: Vector2i, dir: int) -> void:
	var opposite: int = HexMathClass.OPPOSITE_EDGE[dir]
	tiles[from].connection_mask |= (1 << dir)
	tiles[to].connection_mask |= (1 << opposite)


## Scramble all tiles by rotating each a random number of times.
static func _scramble(tiles: Dictionary, config: Resource) -> void:
	for tile in tiles.values():
		if tile.connection_mask == 0:
			continue
		var rotations: int = randi_range(config.min_scramble_steps, config.max_scramble_steps)
		tile.connection_mask = HexMathClass.rotate_mask(tile.connection_mask, rotations)
