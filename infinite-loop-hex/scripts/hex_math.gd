## Static utility class for hexagonal grid math.
## Uses axial coordinates (q, r) with flat-top hexagons.
## Edge numbering: 0=E, 1=SE, 2=SW, 3=W, 4=NW, 5=NE (clockwise from right).


## Axial direction offsets for each of the 6 edges (flat-top hex).
const DIRECTIONS: Array[Vector2i] = [
	Vector2i(1, 0),   # 0: E
	Vector2i(0, 1),   # 1: SE
	Vector2i(-1, 1),  # 2: SW
	Vector2i(-1, 0),  # 3: W
	Vector2i(0, -1),  # 4: NW
	Vector2i(1, -1),  # 5: NE
]

## Maps each edge index to the opposite edge on the neighboring tile.
const OPPOSITE_EDGE: Array[int] = [3, 4, 5, 0, 1, 2]


## Convert axial (q, r) to pixel position for flat-top hexagons.
static func hex_to_pixel(coord: Vector2i, size: float) -> Vector2:
	var x: float = size * (3.0 / 2.0 * coord.x)
	var y: float = size * (sqrt(3.0) / 2.0 * coord.x + sqrt(3.0) * coord.y)
	return Vector2(x, y)


## Convert pixel position to the nearest axial coordinate.
static func pixel_to_hex(pos: Vector2, size: float) -> Vector2i:
	# Convert to fractional axial
	var q: float = (2.0 / 3.0 * pos.x) / size
	var r: float = (-1.0 / 3.0 * pos.x + sqrt(3.0) / 3.0 * pos.y) / size
	return axial_round(q, r)


## Round fractional axial coordinates to the nearest hex.
static func axial_round(fq: float, fr: float) -> Vector2i:
	var fs: float = -fq - fr
	var q: int = roundi(fq)
	var r: int = roundi(fr)
	var s: int = roundi(fs)

	var q_diff: float = absf(q - fq)
	var r_diff: float = absf(r - fr)
	var s_diff: float = absf(s - fs)

	if q_diff > r_diff and q_diff > s_diff:
		q = -r - s
	elif r_diff > s_diff:
		r = -q - s
	# else: s = -q - r (not needed, we only use q, r)

	return Vector2i(q, r)


## Get the neighbor coordinate in the given direction.
static func get_neighbor(coord: Vector2i, direction: int) -> Vector2i:
	return coord + DIRECTIONS[direction]


## Get the 6 corner offsets of a flat-top hex centered at origin.
static func get_hex_corners(size: float) -> PackedVector2Array:
	var corners := PackedVector2Array()
	for i in range(6):
		var angle_deg: float = 60.0 * i
		var angle_rad: float = deg_to_rad(angle_deg)
		corners.append(Vector2(size * cos(angle_rad), size * sin(angle_rad)))
	return corners


## Get the midpoint of a specific edge (between corner[i] and corner[(i+1)%6]).
static func get_edge_midpoint(size: float, edge: int) -> Vector2:
	var angle_deg: float = 60.0 * edge + 30.0
	var angle_rad: float = deg_to_rad(angle_deg)
	var dist: float = size * sqrt(3.0) / 2.0
	return Vector2(dist * cos(angle_rad), dist * sin(angle_rad))


## Generate all axial coordinates within a hexagonal grid of given radius.
## Radius 0 = just center, radius 1 = 7 cells, radius 2 = 19 cells, etc.
static func get_hex_ring(radius: int) -> Array[Vector2i]:
	var coords: Array[Vector2i] = []
	for q in range(-radius, radius + 1):
		for r in range(-radius, radius + 1):
			var s: int = -q - r
			if absi(s) <= radius:
				coords.append(Vector2i(q, r))
	return coords


## Rotate a 6-bit connection mask clockwise by 1 step (60 degrees).
static func rotate_mask_cw(mask: int) -> int:
	var bit0: int = mask & 1
	return ((mask >> 1) | (bit0 << 5)) & 0x3F


## Rotate a 6-bit connection mask by N steps clockwise.
static func rotate_mask(mask: int, steps: int) -> int:
	var result: int = mask
	for i in range(steps % 6):
		result = rotate_mask_cw(result)
	return result
