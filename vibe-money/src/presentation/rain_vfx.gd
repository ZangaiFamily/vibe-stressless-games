## Continuous particle rain effect with two depth layers.
## See design/gdd/rain-vfx-system.md for specification.
class_name RainVFX
extends Node2D

@export var base_particle_count: int = 500
@export var min_rain_speed: float = 300.0
@export var max_rain_speed: float = 800.0
@export var base_rain_angle: float = 10.0
@export var wind_cycle_seconds: float = 8.0
@export var max_wind_angle: float = 5.0

var _intensity: float = 1.0
var _bg_particles: GPUParticles2D
var _fg_particles: GPUParticles2D


func _ready() -> void:
	_bg_particles = _create_rain_layer("BackgroundRain", 0.5, min_rain_speed, 0.3)
	_fg_particles = _create_rain_layer("ForegroundRain", 1.0, max_rain_speed, 0.5)
	add_child(_bg_particles)
	add_child(_fg_particles)


func _process(_delta: float) -> void:
	var wind_offset := sin(Time.get_ticks_msec() / 1000.0 / wind_cycle_seconds * TAU) * max_wind_angle
	var angle := deg_to_rad(90.0 + base_rain_angle + wind_offset)

	_update_direction(_bg_particles, angle)
	_update_direction(_fg_particles, angle)


func set_intensity(value: float) -> void:
	_intensity = value
	if _bg_particles:
		_bg_particles.amount = int(base_particle_count * 0.5 * _intensity)
	if _fg_particles:
		_fg_particles.amount = int(base_particle_count * _intensity)


func _create_rain_layer(layer_name: String, scale_mult: float, speed: float, opacity: float) -> GPUParticles2D:
	var particles := GPUParticles2D.new()
	particles.name = layer_name
	particles.amount = int(base_particle_count * scale_mult * _intensity)
	particles.lifetime = get_viewport_rect().size.y / speed + 0.5
	particles.preprocess = particles.lifetime

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(sin(deg_to_rad(base_rain_angle)), 1.0, 0.0).normalized()
	mat.spread = 5.0
	mat.initial_velocity_min = speed * 0.8
	mat.initial_velocity_max = speed * 1.2
	mat.gravity = Vector3.ZERO
	mat.scale_min = 0.5 * scale_mult
	mat.scale_max = 1.5 * scale_mult
	mat.color = Color(0.7, 0.8, 1.0, opacity)

	# Emission: full width of screen, above viewport
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	var vp_size := get_viewport_rect().size
	mat.emission_box_extents = Vector3(vp_size.x * 0.6, 10.0, 0.0)

	particles.process_material = mat
	particles.position = Vector2(vp_size.x * 0.5, -20.0)

	return particles


func _update_direction(particles: GPUParticles2D, angle: float) -> void:
	var mat := particles.process_material as ParticleProcessMaterial
	if mat:
		mat.direction = Vector3(cos(angle), sin(angle), 0.0).normalized()
