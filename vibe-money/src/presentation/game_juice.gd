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
var _flash_overlay: ColorRect
var _vignette_overlay: ColorRect

## Particle textures for coin collection bursts
const PARTICLE_TEXTURES: Dictionary = {
	&"coin_bronze": "res://assets/art/puzzle/particles/particleYellow_4.png",
	&"coin_silver": "res://assets/art/puzzle/particles/particleWhite_4.png",
	&"coin_gold": "res://assets/art/puzzle/particles/particleYellow_2.png",
	&"coin_emerald": "res://assets/art/puzzle/particles/particleBlue_4.png",
	&"coin_diamond": "res://assets/art/puzzle/particles/particleWhite_2.png",
}
const MILESTONE_PARTICLE: String = "res://assets/art/puzzle/particles/particleYellow_6.png"


func _ready() -> void:
	GameEvents.item_collected.connect(_on_item_collected)
	GameEvents.item_hit.connect(_on_item_hit)
	GameEvents.streak_milestone.connect(_on_streak_milestone)
	GameEvents.streak_reset.connect(_on_streak_reset)
	GameEvents.life_lost.connect(_on_life_lost)

	_popup_container = CanvasLayer.new()
	_popup_container.layer = 5
	add_child(_popup_container)

	# Red flash overlay for hazard hits
	var flash_layer := CanvasLayer.new()
	flash_layer.layer = 8
	add_child(flash_layer)
	_flash_overlay = ColorRect.new()
	_flash_overlay.color = Color(1.0, 0.1, 0.1, 0.0)
	_flash_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_flash_overlay)

	# Red vignette overlay for life_lost (darker, longer)
	_vignette_overlay = ColorRect.new()
	_vignette_overlay.color = Color(0.6, 0.0, 0.0, 0.0)
	_vignette_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash_layer.add_child(_vignette_overlay)


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
	AudioManager.play_sfx(item_def.feedback_tag)

	var points: int = item_def.point_value
	_spawn_score_popup(points, item_def)

	# Particle burst per GDD
	_spawn_coin_particles(item_def)

	# Screen shake for high-value coins
	if item_def.id == &"coin_gold":
		_apply_shake(2.0, 0.1)
		if _rain_vfx:
			_brief_rain_spike(1.2)
	elif item_def.id == &"coin_diamond":
		_apply_shake(3.0, 0.15)
		if _rain_vfx:
			_brief_rain_spike(1.5)


func _on_item_hit(item_def: Resource) -> void:
	AudioManager.play_sfx(item_def.feedback_tag)
	_apply_shake(5.0, 0.2)
	_flash_red(0.3)


func _on_streak_milestone(tier: int, multiplier: float) -> void:
	AudioManager.play_sfx(&"streak_milestone")
	_spawn_milestone_popup(multiplier)
	_spawn_milestone_particles()
	if _rain_vfx:
		_brief_rain_spike(1.5)


func _on_life_lost(current_lives: int, _damage: int) -> void:
	AudioManager.play_sfx(&"life_lost")
	_apply_shake(max_shake_intensity, 0.2)
	_flash_vignette(0.35)  # Red vignette per GDD
	if _rain_vfx:
		_brief_rain_spike(0.5)  # Calmer rain


func _on_streak_reset(previous_streak: int) -> void:
	if previous_streak >= 5:
		_spawn_streak_broken_popup(previous_streak)


func _flash_red(alpha: float) -> void:
	if not _flash_overlay:
		return
	_flash_overlay.color.a = alpha
	var tween := create_tween()
	tween.tween_property(_flash_overlay, "color:a", 0.0, 0.25)


func _spawn_streak_broken_popup(streak: int) -> void:
	var label := Label.new()
	label.text = "Streak %d broken!" % streak
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3))
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 540)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	label.position = Vector2(vp_w * 0.5 - 80, vp_h * 0.4)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_container.add_child(label)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 40, 1.0)
	tween.tween_property(label, "modulate:a", 0.0, 1.0).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)


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
		&"coin_emerald": color = Color(0.2, 0.9, 0.4)
		&"coin_diamond": color = Color(0.7, 0.9, 1.0)
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


func _flash_vignette(alpha: float) -> void:
	if not _vignette_overlay:
		return
	_vignette_overlay.color.a = alpha
	var tween := create_tween()
	tween.tween_property(_vignette_overlay, "color:a", 0.0, 0.3)


func _spawn_coin_particles(item_def: Resource) -> void:
	var tex_path: String = PARTICLE_TEXTURES.get(item_def.id, "")
	if tex_path.is_empty():
		return
	var tex := load(tex_path) as Texture2D
	if not tex:
		return

	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 540)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	var origin := Vector2(vp_w * 0.5 + randf_range(-40, 40), vp_h * 0.75)

	var count: int = coin_particle_count
	if item_def.id == &"coin_gold" or item_def.id == &"coin_diamond":
		count = int(count * 1.5)

	var color := Color.WHITE
	match item_def.id:
		&"coin_bronze": color = Color(0.9, 0.7, 0.35)
		&"coin_silver": color = Color(0.9, 0.9, 1.0)
		&"coin_gold": color = Color(1.0, 0.9, 0.3)
		&"coin_emerald": color = Color(0.3, 1.0, 0.5)
		&"coin_diamond": color = Color(0.7, 0.95, 1.0)

	for i in count:
		var sprite := TextureRect.new()
		sprite.texture = tex
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		# Match falling coin size (~36px)
		var sz := randf_range(24, 36)
		sprite.size = Vector2(sz, sz)
		sprite.position = origin
		sprite.modulate = color
		sprite.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
		sprite.rotation = randf_range(0, TAU)
		_popup_container.add_child(sprite)

		var dir := Vector2(randf_range(-1, 1), randf_range(-1.5, -0.3)).normalized()
		var dist := randf_range(20, 50)
		var target := origin + dir * dist

		var tween := create_tween().set_parallel(true)
		tween.tween_property(sprite, "position", target, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.4).set_delay(0.1)
		tween.tween_property(sprite, "size", Vector2(1, 1), 0.5)
		tween.chain().tween_callback(sprite.queue_free)


func _spawn_milestone_popup(multiplier: float) -> void:
	var label := Label.new()
	label.text = "%.1fx!" % multiplier
	label.add_theme_font_size_override("font_size", 42)
	label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 540)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	label.position = Vector2(vp_w * 0.5 - 40, vp_h * 0.35)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_popup_container.add_child(label)

	var tween := create_tween()
	tween.tween_property(label, "scale", Vector2(1.3, 1.3), 0.1)
	tween.tween_property(label, "scale", Vector2.ONE, 0.15)
	tween.tween_interval(0.4)
	tween.tween_property(label, "modulate:a", 0.0, 0.3)
	tween.tween_callback(label.queue_free)


func _spawn_milestone_particles() -> void:
	var tex := load(MILESTONE_PARTICLE) as Texture2D
	if not tex:
		return
	var vp_w: float = ProjectSettings.get_setting("display/window/size/viewport_width", 540)
	var vp_h: float = ProjectSettings.get_setting("display/window/size/viewport_height", 960)
	var center := Vector2(vp_w * 0.5, vp_h * 0.4)

	for i in 12:
		var sprite := TextureRect.new()
		sprite.texture = tex
		sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		sprite.stretch_mode = TextureRect.STRETCH_SCALE
		var sz := randf_range(20, 36)
		sprite.size = Vector2(sz, sz)
		sprite.position = center
		sprite.modulate = Color(1.0, 0.9, 0.3, 0.8)
		sprite.pivot_offset = Vector2(sz * 0.5, sz * 0.5)
		sprite.rotation = randf_range(0, TAU)
		_popup_container.add_child(sprite)

		var angle := (TAU / 12.0) * i + randf_range(-0.2, 0.2)
		var dist := randf_range(40, 80)
		var target := center + Vector2(cos(angle), sin(angle)) * dist

		var tween := create_tween().set_parallel(true)
		tween.tween_property(sprite, "position", target, 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5).set_delay(0.15)
		tween.chain().tween_callback(sprite.queue_free)
