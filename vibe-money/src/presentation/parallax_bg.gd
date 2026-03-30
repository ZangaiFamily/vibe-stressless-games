## Procedural parallax city background with glowing windows.
## See design/gdd/parallax-background.md for specification.
class_name ParallaxBG
extends CanvasLayer

@export var max_parallax_offset: float = 50.0
@export var far_parallax: float = 0.05
@export var mid_parallax: float = 0.15
@export var near_parallax: float = 0.30

var _layers: Array[Control] = []
var _parallax_factors: Array[float] = []
var _player_x_ratio: float = 0.5



func _ready() -> void:
	layer = -10  # Behind everything
	_create_sky()
	_create_building_layer("FarBuildings", Color(0.08, 0.08, 0.15), 0.3, far_parallax, 4)
	_create_building_layer("MidBuildings", Color(0.1, 0.1, 0.2), 0.5, mid_parallax, 6)
	_create_building_layer("NearBuildings", Color(0.12, 0.12, 0.25), 0.7, near_parallax, 5)
	_create_rooftop()

	GameEvents.player_moved.connect(_on_player_moved)


func _process(delta: float) -> void:
	for i in _layers.size():
		var offset := (_player_x_ratio - 0.5) * _parallax_factors[i] * max_parallax_offset
		_layers[i].position.x = offset


func _on_player_moved(_velocity: Vector2) -> void:
	# We can't easily get the player position from velocity, so we use a different approach
	pass


func update_player_position(player_x: float, viewport_width: float) -> void:
	_player_x_ratio = player_x / viewport_width if viewport_width > 0 else 0.5


func _create_rooftop() -> void:
	var vp_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 540),
		ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	)
	var rooftop_y := vp_size.y * 0.88  # Just below the player (player is at 0.85)
	var container := Control.new()
	container.name = "Rooftop"
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	# Rooftop surface — a wide dark rectangle spanning the bottom
	var surface := ColorRect.new()
	surface.position = Vector2(-20, rooftop_y)
	surface.size = Vector2(vp_size.x + 40, 6)
	surface.color = Color(0.2, 0.18, 0.25)
	container.add_child(surface)

	# Rooftop edge highlight
	var edge := ColorRect.new()
	edge.position = Vector2(-20, rooftop_y)
	edge.size = Vector2(vp_size.x + 40, 2)
	edge.color = Color(0.35, 0.3, 0.4)
	container.add_child(edge)

	# Building body below the rooftop (the building the player stands on)
	var body := ColorRect.new()
	body.position = Vector2(-20, rooftop_y + 6)
	body.size = Vector2(vp_size.x + 40, vp_size.y - rooftop_y)
	body.color = Color(0.1, 0.09, 0.16)
	container.add_child(body)

	# Some windows on the player's building
	var win_cols := 12
	var win_rows := 3
	var win_size := Vector2(10, 14)
	var win_spacing_x := (vp_size.x) / win_cols
	var win_spacing_y := 28.0
	for row in win_rows:
		for col in win_cols:
			if randf() > 0.5:
				continue
			var wx := 20.0 + col * win_spacing_x + randf_range(-5, 5)
			var wy := rooftop_y + 20.0 + row * win_spacing_y
			var win := ColorRect.new()
			win.position = Vector2(wx, wy)
			win.size = win_size
			win.color = Color(1.0, 0.85, 0.4, randf_range(0.2, 0.5))
			container.add_child(win)


func _create_sky() -> void:
	var sky := ColorRect.new()
	sky.name = "Sky"
	sky.color = Color(0.05, 0.03, 0.12)
	sky.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(sky)

	# Gradient overlay
	var gradient_rect := ColorRect.new()
	gradient_rect.name = "SkyGradient"
	gradient_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gradient_rect.color = Color(0.1, 0.05, 0.2, 0.3)
	add_child(gradient_rect)


func _create_building_layer(layer_name: String, base_color: Color, height_ratio: float,
		parallax_factor: float, building_count: int) -> void:
	var container := Control.new()
	container.name = layer_name
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)

	_layers.append(container)
	_parallax_factors.append(parallax_factor)

	var vp_size := Vector2(
		ProjectSettings.get_setting("display/window/size/viewport_width", 540),
		ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	)

	# Generate buildings procedurally
	var x := -50.0
	for i in building_count:
		var bw := randf_range(80, 200)
		var bh := randf_range(vp_size.y * 0.2, vp_size.y * height_ratio)

		var building := ColorRect.new()
		building.position = Vector2(x, vp_size.y - bh)
		building.size = Vector2(bw, bh)
		building.color = base_color
		container.add_child(building)

		# Windows
		_add_windows(building, bw, bh)

		x += bw + randf_range(10, 60)


func _add_windows(building: ColorRect, bw: float, bh: float) -> void:
	var win_size := Vector2(8, 12)
	var margin := 15.0
	var cols := int((bw - margin * 2) / (win_size.x + margin))
	var rows := int((bh - margin * 2) / (win_size.y + margin))

	for row in rows:
		for col in cols:
			if randf() > 0.6:  # 40% of windows are lit
				continue
			var wx := margin + col * (win_size.x + margin)
			var wy := margin + row * (win_size.y + margin)
			var win := ColorRect.new()
			win.position = Vector2(wx, wy)
			win.size = win_size
			win.color = Color(1.0, 0.85, 0.4, randf_range(0.3, 0.7))
			building.add_child(win)


