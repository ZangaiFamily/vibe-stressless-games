## Continuous particle rain effect using Kenney particle textures.
## See design/gdd/rain-vfx-system.md for specification.
class_name RainVFX
extends Node2D

## Matches old sky particle parameters from parallax_bg.gd
@export var base_particle_count: int = 40
@export var min_rain_speed: float = 8.0
@export var max_rain_speed: float = 30.0
@export var drift_x_range: float = 5.0
@export var sky_coverage: float = 0.85

## Size range 12-28px from ~220px atlas regions.
const SCALE_MIN: float = 0.054  # 12.0 / 220.0
const SCALE_MAX: float = 0.127  # 28.0 / 220.0

## Spritesheet containing all particle textures.
const SPRITESHEET_PATH := "res://assets/art/puzzle/particles/spritesheet_particles.png"

## Atlas regions from spritesheet XML — [name, x, y, width, height].
const ATLAS_REGIONS: Array = [
	[&"particleBlue_1", 230, 224, 224, 222],
	[&"particleBlue_3", 681, 0, 192, 183],
	[&"particleBlue_6", 0, 0, 228, 226],
	[&"particleWhite_1", 230, 0, 224, 222],
	[&"particleWhite_3", 678, 857, 192, 183],
	[&"particleYellow_1", 452, 672, 224, 222],
	[&"particleYellow_3", 678, 672, 192, 183],
	[&"particleYellow_6", 0, 456, 228, 226],
]

var _intensity: float = 1.0
var _layers: Array[GPUParticles2D] = []


func _ready() -> void:
	# Load PNG directly — bypasses Godot import system
	var sheet_img := Image.new()
	var err := sheet_img.load(SPRITESHEET_PATH)
	if err != OK:
		push_warning("[RainVFX] Failed to load spritesheet: %s" % error_string(err))
		var layer := _create_rain_layer("FallbackRain", null, 1.0, max_rain_speed, 0.5)
		add_child(layer)
		_layers.append(layer)
		return

	# Cut individual particle images from the spritesheet
	var textures: Array[Texture2D] = []
	for region_data in ATLAS_REGIONS:
		var region := Rect2i(region_data[1], region_data[2], region_data[3], region_data[4])
		var sub_img := sheet_img.get_region(region)
		textures.append(ImageTexture.create_from_image(sub_img))

	# Use 3 layers (fewer draw calls) with shuffled textures
	var layer_count := 3
	var per_layer := maxi(base_particle_count / layer_count, 5)
	for i in layer_count:
		var tex := textures[i % textures.size()]
		var speed := lerpf(min_rain_speed, max_rain_speed, float(i) / (layer_count - 1))
		var opacity := lerpf(0.15, 0.5, float(i) / (layer_count - 1))
		var layer := _create_rain_layer(
			"SkyParticles_%d" % i, tex, per_layer, speed, opacity
		)
		add_child(layer)
		_layers.append(layer)


func set_intensity(value: float) -> void:
	_intensity = value
	for layer in _layers:
		layer.amount = maxi(int(base_particle_count / maxi(_layers.size(), 1) * _intensity), 1)


func _create_rain_layer(layer_name: String, tex: Texture2D, amount: int, speed: float, opacity: float) -> GPUParticles2D:
	var vp_size := get_viewport_rect().size
	var fall_height := vp_size.y * sky_coverage

	var particles := GPUParticles2D.new()
	particles.name = layer_name
	particles.amount = maxi(amount, 1)
	particles.lifetime = fall_height / speed
	particles.preprocess = minf(particles.lifetime, 3.0)  # Cap to avoid startup freeze

	if tex:
		particles.texture = tex

	var mat := ParticleProcessMaterial.new()
	# Slow downward drift with slight horizontal wander
	mat.direction = Vector3(0.0, 1.0, 0.0)
	mat.spread = 0.0
	mat.initial_velocity_min = speed * 0.8
	mat.initial_velocity_max = speed * 1.2
	mat.gravity = Vector3.ZERO

	# Horizontal drift (matches old drift_x of -5 to 5)
	mat.velocity_limit_curve = null
	mat.direction = Vector3(randf_range(-drift_x_range, drift_x_range) / speed, 1.0, 0.0).normalized()

	# Scale to match old 12-28px size range
	mat.scale_min = SCALE_MIN
	mat.scale_max = SCALE_MAX
	mat.color = Color(1.0, 1.0, 1.0, opacity)

	# Emission: full width, spread across sky area (not just top edge)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(vp_size.x * 0.5, fall_height * 0.5, 0.0)

	particles.process_material = mat
	# Center emission box over the sky area
	particles.position = Vector2(vp_size.x * 0.5, fall_height * 0.5)

	return particles
