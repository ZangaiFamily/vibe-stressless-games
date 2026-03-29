## Procedural parallax city background with glowing windows.
## Rainy night cityscape — silhouettes, warm window glow, atmospheric depth.
## See design/gdd/parallax-background.md for specification.
class_name ParallaxBG
extends CanvasLayer

@export var max_parallax_offset: float = 50.0
@export var far_parallax: float = 0.05
@export var mid_parallax: float = 0.15
@export var near_parallax: float = 0.30

## Window glow pulse parameters (from GDD)
const BASE_GLOW: float = 0.7
const GLOW_VARIANCE: float = 0.15

var _layers: Array[Control] = []
var _parallax_factors: Array[float] = []
var _player_x_ratio: float = 0.5
var _vp_size: Vector2
var _windows: Array[Dictionary] = []  # {node, cycle, offset}

# Star particles for sky
var _stars: Array[Dictionary] = []  # {node, cycle, offset, base_alpha}
var _shooting_star_timer: float = 0.0
var _shooting_star_interval: float = 8.0
var _sky_container: Control

const STAR_TEXTURES_BLUE: Array[String] = [
	"res://assets/art/puzzle/particles/particleBlue_1.png",
	"res://assets/art/puzzle/particles/particleBlue_2.png",
	"res://assets/art/puzzle/particles/particleBlue_3.png",
	"res://assets/art/puzzle/particles/particleBlue_4.png",
	"res://assets/art/puzzle/particles/particleBlue_6.png",
]
const STAR_TEXTURES_WHITE: Array[String] = [
	"res://assets/art/puzzle/particles/particleWhite_1.png",
	"res://assets/art/puzzle/particles/particleWhite_2.png",
	"res://assets/art/puzzle/particles/particleWhite_4.png",
	"res://assets/art/puzzle/particles/particleWhite_6.png",
]
const STAR_TEXTURES_YELLOW: Array[String] = [
	"res://assets/art/puzzle/particles/particleYellow_2.png",
	"res://assets/art/puzzle/particles/particleYellow_4.png",
	"res://assets/art/puzzle/particles/particleYellow_6.png",
]
const SHOOTING_STAR_TEXTURE: String = "res://assets/art/puzzle/particles/particleWhite_5.png"

# Subtle rooftop tile textures
var _roof_tiles: Array[Texture2D] = []
const ROOF_TILE_PATHS: Array[String] = [
	"res://assets/art/puzzle/tile_blue.png",
	"res://assets/art/puzzle/tile_grey.png",
]


func _ready() -> void:
	layer = -10
	_vp_size = Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 540),
		ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	)

	for path in ROOF_TILE_PATHS:
		var tex := load(path) as Texture2D
		if tex:
			_roof_tiles.append(tex)

	_create_sky()
	_create_stars()
	_create_building_layer("FarBuildings", Color(0.08, 0.08, 0.15), 0.3, far_parallax, 4, false)
	_create_building_layer("MidBuildings", Color(0.10, 0.10, 0.20), 0.5, mid_parallax, 6, true)
	_create_building_layer("NearBuildings", Color(0.12, 0.12, 0.25), 0.7, near_parallax, 5, true)
	_create_rooftop()

	GameEvents.player_moved.connect(_on_player_moved)


func _process(delta: float) -> void:
	# Parallax scrolling
	for i in _layers.size():
		var offset := (_player_x_ratio - 0.5) * _parallax_factors[i] * max_parallax_offset
		_layers[i].position.x = offset

	# Window glow pulse
	var time := Time.get_ticks_msec() / 1000.0
	for w in _windows:
		var glow: float = BASE_GLOW + sin((time + w.offset) * TAU / w.cycle) * GLOW_VARIANCE
		w.node.modulate.a = glow

	# Star twinkle
	for s in _stars:
		var twinkle: float = s.base_alpha + sin((time + s.offset) * TAU / s.cycle) * (s.base_alpha * 0.5)
		s.node.modulate.a = maxf(twinkle, 0.0)

	# Shooting star
	_shooting_star_timer -= delta
	if _shooting_star_timer <= 0.0:
		_shooting_star_timer = _shooting_star_interval + randf_range(-3.0, 5.0)
		_spawn_shooting_star()


func _on_player_moved(_velocity: Vector2) -> void:
	pass


func update_player_position(player_x: float, viewport_width: float) -> void:
	_player_x_ratio = player_x / viewport_width if viewport_width > 0 else 0.5


func _create_sky() -> void:
	# Deep purple-to-dark-blue base
	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.color = Color(0.05, 0.03, 0.12)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	# Subtle purple gradient overlay
	var gradient := ColorRect.new()
	gradient.name = "SkyGradient"
	gradient.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gradient.color = Color(0.08, 0.04, 0.18, 0.3)
	add_child(gradient)


func _create_stars() -> void:
	_sky_container = Control.new()
	_sky_container.name = "Stars"
	_sky_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sky_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_sky_container)

	var rng := RandomNumberGenerator.new()
	rng.seed = 7777

	var sky_height := _vp_size.y * 0.75  # Stars only in upper portion

	# Small ambient blue/white stars (many, tiny, subtle)
	for i in 35:
		var tex_path: String
		var base_alpha: float
		var star_scale: float
		var roll := rng.randf()

		if roll < 0.50:
			# Blue star — most common
			tex_path = STAR_TEXTURES_BLUE[rng.randi() % STAR_TEXTURES_BLUE.size()]
			base_alpha = rng.randf_range(0.08, 0.20)
			star_scale = rng.randf_range(0.04, 0.09)
		elif roll < 0.85:
			# White star — medium frequency
			tex_path = STAR_TEXTURES_WHITE[rng.randi() % STAR_TEXTURES_WHITE.size()]
			base_alpha = rng.randf_range(0.10, 0.25)
			star_scale = rng.randf_range(0.03, 0.07)
		else:
			# Yellow accent star — rare, slightly brighter
			tex_path = STAR_TEXTURES_YELLOW[rng.randi() % STAR_TEXTURES_YELLOW.size()]
			base_alpha = rng.randf_range(0.15, 0.30)
			star_scale = rng.randf_range(0.05, 0.10)

		var tex := load(tex_path) as Texture2D
		if not tex:
			continue

		var sprite := TextureRect.new()
		sprite.texture = tex
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		# Size relative to falling items (~36px) — stars are similar scale
		var star_px := 36.0 * star_scale / 0.06  # normalize around mid-range
		sprite.size = Vector2(star_px, star_px)
		sprite.position = Vector2(
			rng.randf_range(0, _vp_size.x - star_px),
			rng.randf_range(10, sky_height)
		)
		sprite.modulate.a = base_alpha
		_sky_container.add_child(sprite)

		_stars.append({
			"node": sprite,
			"cycle": rng.randf_range(2.5, 7.0),
			"offset": rng.randf_range(0.0, 10.0),
			"base_alpha": base_alpha,
		})


func _spawn_shooting_star() -> void:
	if not _sky_container:
		return
	var tex := load(SHOOTING_STAR_TEXTURE) as Texture2D
	if not tex:
		return

	var sprite := TextureRect.new()
	sprite.texture = tex
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_SCALE
	sprite.size = Vector2(8, 35)
	sprite.rotation = deg_to_rad(randf_range(25.0, 50.0))
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.0)

	var start_x := randf_range(50, _vp_size.x - 50)
	var start_y := randf_range(20, _vp_size.y * 0.4)
	sprite.position = Vector2(start_x, start_y)
	_sky_container.add_child(sprite)

	var travel := Vector2(randf_range(80, 160), randf_range(60, 120))
	var tween := create_tween()
	tween.tween_property(sprite, "modulate:a", 0.6, 0.15)
	tween.parallel().tween_property(sprite, "position", sprite.position + travel, 0.8).set_ease(Tween.EASE_OUT)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
	tween.tween_callback(sprite.queue_free)


func _create_building_layer(layer_name: String, base_color: Color, height_ratio: float,
		parallax_factor: float, building_count: int, has_windows: bool) -> void:
	var container := Control.new()
	container.name = layer_name
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	_layers.append(container)
	_parallax_factors.append(parallax_factor)

	# Use seeded RNG for consistent layout
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(layer_name)

	var x := -50.0
	for i in building_count:
		var bw := rng.randf_range(80, 200)
		var bh := rng.randf_range(_vp_size.y * 0.2, _vp_size.y * height_ratio)

		var building := ColorRect.new()
		building.position = Vector2(x, _vp_size.y - bh)
		building.size = Vector2(bw, bh)
		building.color = base_color
		container.add_child(building)

		if has_windows:
			_add_windows(building, bw, bh, rng)

		x += bw + rng.randf_range(10, 60)


func _add_windows(building: ColorRect, bw: float, bh: float, rng: RandomNumberGenerator) -> void:
	var win_size := Vector2(8, 12)
	var margin := 15.0
	var cols := int((bw - margin * 2) / (win_size.x + margin))
	var rows := int((bh - margin * 2) / (win_size.y + margin))

	for row in rows:
		for col in cols:
			if rng.randf() > 0.5:
				continue
			var wx := margin + col * (win_size.x + margin)
			var wy := margin + row * (win_size.y + margin)
			var win := ColorRect.new()
			win.position = Vector2(wx, wy)
			win.size = win_size
			# Warm yellow/orange glow — muted neon
			var warmth := rng.randf_range(0.75, 1.0)
			win.color = Color(warmth, warmth * 0.82, 0.35, 1.0)

			building.add_child(win)

			# Register for glow pulse with randomized cycle (3-6 sec per GDD)
			_windows.append({
				"node": win,
				"cycle": rng.randf_range(3.0, 6.0),
				"offset": rng.randf_range(0.0, 10.0),
			})


func _create_rooftop() -> void:
	var rooftop_y := _vp_size.y * 0.88
	var container := Control.new()
	container.name = "Rooftop"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	# Rooftop edge highlight — subtle warm line
	var edge := ColorRect.new()
	edge.position = Vector2(-20, rooftop_y)
	edge.size = Vector2(_vp_size.x + 40, 2)
	edge.color = Color(0.35, 0.30, 0.42)
	container.add_child(edge)

	# Rooftop surface
	var surface := ColorRect.new()
	surface.position = Vector2(-20, rooftop_y + 2)
	surface.size = Vector2(_vp_size.x + 40, 5)
	surface.color = Color(0.18, 0.16, 0.24)
	container.add_child(surface)

	# Building body below rooftop
	var body := ColorRect.new()
	body.position = Vector2(-20, rooftop_y + 7)
	body.size = Vector2(_vp_size.x + 40, _vp_size.y - rooftop_y)
	body.color = Color(0.09, 0.08, 0.15)
	container.add_child(body)

	# Subtle tile texture on rooftop building — very dark, desaturated
	if not _roof_tiles.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 42
		var tile_sz := 24
		var tile_cols := ceili(_vp_size.x / tile_sz) + 1
		var tile_rows := 4
		for row in tile_rows:
			for col in tile_cols:
				if rng.randf() < 0.5:
					continue
				var sprite := TextureRect.new()
				sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
				sprite.texture = _roof_tiles[rng.randi() % _roof_tiles.size()]
				sprite.position = Vector2(col * tile_sz, rooftop_y + 10 + row * tile_sz)
				sprite.size = Vector2(tile_sz, tile_sz)
				sprite.stretch_mode = TextureRect.STRETCH_SCALE
				# Nearly invisible — just adds subtle texture
				sprite.modulate = Color(0.12, 0.10, 0.18, 0.3)
				container.add_child(sprite)

	# Windows on the player's building
	var rng2 := RandomNumberGenerator.new()
	rng2.seed = 99
	var win_cols := 11
	var win_rows := 3
	var win_size := Vector2(10, 14)
	var win_spacing_x := _vp_size.x / win_cols
	var win_spacing_y := 26.0
	for row in win_rows:
		for col in win_cols:
			if rng2.randf() > 0.45:
				continue
			var wx := 15.0 + col * win_spacing_x + rng2.randf_range(-4, 4)
			var wy := rooftop_y + 18.0 + row * win_spacing_y
			var win := ColorRect.new()
			win.position = Vector2(wx, wy)
			win.size = win_size
			var warmth := rng2.randf_range(0.7, 1.0)
			win.color = Color(warmth, warmth * 0.8, 0.3, 1.0)
			container.add_child(win)

			_windows.append({
				"node": win,
				"cycle": rng2.randf_range(3.0, 6.0),
				"offset": rng2.randf_range(0.0, 10.0),
			})
