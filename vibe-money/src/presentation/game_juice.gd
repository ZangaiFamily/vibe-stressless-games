## Feedback orchestrator — triggers visual/audio responses to gameplay events.
## See design/gdd/game-juice-system.md for specification.
class_name GameJuice
extends Node

@export var popup_duration: float = 0.8
@export var popup_rise_speed: float = 60.0
@export var max_shake_intensity: float = 6.0
@export var coin_particle_count: int = 8
@export var hit_flash_duration: float = 0.1

var _camera: Camera2D
var _shake_intensity: float = 0.0
var _rain_vfx: Node
var _popup_container: CanvasLayer


func _ready() -> void:
	GameEvents.item_collected.connect(_on_item_collected)
	GameEvents.item_hit.connect(_on_item_hit)
	GameEvents.streak_milestone.connect(_on_streak_milestone)
	GameEvents.life_lost.connect(_on_life_lost)

	_popup_container = CanvasLayer.new()
	_popup_container.layer = 5
	add_child(_popup_container)


func bind_camera(camera: Camera2D) -> void:
	_camera = camera


func bind_rain(rain: Node) -> void:
	_rain_vfx = rain


func _process(delta: float) -> void:
	# Decay screen shake
	if _shake_intensity > 0.0 and _camera:
		_camera.offset = Vector2(
			randf_range(-_shake_intensity, _shake_intensity),
			randf_range(-_shake_intensity, _shake_intensity)
		)
		_shake_intensity = move_toward(_shake_intensity, 0.0, delta * max_shake_intensity * 5.0)
		if _shake_intensity <= 0.1:
			_shake_intensity = 0.0
			_camera.offset = Vector2.ZERO


func _on_item_collected(item_def: Resource) -> void:
	# Play SFX
	AudioManager.play_sfx(item_def.feedback_tag)

	# Score popup (we don't know the exact position, so place near bottom-center)
	var points: int = item_def.point_value
	_spawn_score_popup(points, item_def)

	# Screen shake for gold
	if item_def.id == &"coin_gold":
		_apply_shake(2.0, 0.1)
		if _rain_vfx:
			_brief_rain_spike(1.2)


func _on_item_hit(item_def: Resource) -> void:
	AudioManager.play_sfx(item_def.feedback_tag)
	_apply_shake(4.0, 0.15)


func _on_streak_milestone(tier: int, _multiplier: float) -> void:
	AudioManager.play_sfx(&"streak_milestone")
	if _rain_vfx:
		_brief_rain_spike(1.5)


func _on_life_lost(current_lives: int, _damage: int) -> void:
	AudioManager.play_sfx(&"life_lost")
	_apply_shake(max_shake_intensity, 0.2)
	if _rain_vfx:
		_brief_rain_spike(0.5)  # Calmer rain


func _apply_shake(intensity: float, _duration: float) -> void:
	_shake_intensity = maxf(_shake_intensity, intensity)


func _brief_rain_spike(target_intensity: float) -> void:
	if not _rain_vfx:
		return
	_rain_vfx.set_intensity(target_intensity)
	var tween := create_tween()
	tween.tween_interval(0.3)
	tween.tween_callback(_rain_vfx.set_intensity.bind(1.0))


func _spawn_score_popup(points: int, item_def: Resource) -> void:
	var label := Label.new()
	label.text = "+%d" % points
	label.add_theme_font_size_override("font_size", 24 if points < 100 else 36)

	var color := Color.WHITE
	match item_def.id:
		&"coin_bronze": color = Color(0.8, 0.6, 0.3)
		&"coin_silver": color = Color(0.85, 0.85, 0.95)
		&"coin_gold": color = Color(1.0, 0.85, 0.2)
	label.add_theme_color_override("font_color", color)

	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 540)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	label.position = Vector2(vp_w * 0.5 + randf_range(-50, 50), vp_h * 0.7)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_popup_container.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - popup_rise_speed * popup_duration, popup_duration)
	tween.tween_property(label, "modulate:a", 0.0, popup_duration)
	tween.chain().tween_callback(label.queue_free)
