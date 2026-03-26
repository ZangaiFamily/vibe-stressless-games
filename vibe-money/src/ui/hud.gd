## Displays score, streak, and lives during gameplay.
## See design/gdd/hud.md for specification.
class_name HUD
extends CanvasLayer

@export var punch_scale: float = 0.2
@export var punch_duration: float = 0.15
@export var hud_margin: float = 16.0
@export var score_font_size: int = 32

var _score_label: Label
var _streak_label: Label
var _lives_container: HBoxContainer
var _life_icons: Array[TextureRect] = []
var _visible_state: bool = false


func _ready() -> void:
	layer = 10  # Above gameplay
	_build_ui()
	hide_hud()

	GameEvents.score_changed.connect(_on_score_changed)
	GameEvents.streak_changed.connect(_on_streak_changed)
	GameEvents.life_lost.connect(_on_life_lost)
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.run_ended.connect(_on_run_ended)


func show_hud() -> void:
	_visible_state = true
	_score_label.visible = true
	_streak_label.visible = true
	_lives_container.visible = true


func hide_hud() -> void:
	_visible_state = false
	_score_label.visible = false
	_streak_label.visible = false
	_lives_container.visible = false


func _build_ui() -> void:
	var margin_container := MarginContainer.new()
	margin_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin_container.add_theme_constant_override("margin_left", int(hud_margin))
	margin_container.add_theme_constant_override("margin_right", int(hud_margin))
	margin_container.add_theme_constant_override("margin_top", int(hud_margin))
	add_child(margin_container)

	var hbox := HBoxContainer.new()
	hbox.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	hbox.size.y = 60
	margin_container.add_child(hbox)

	# Score (left)
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", score_font_size)
	_score_label.add_theme_color_override("font_color", Color.WHITE)
	_score_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_score_label)

	# Streak (center)
	_streak_label = Label.new()
	_streak_label.text = "Streak: 0 (1.0x)"
	_streak_label.add_theme_font_size_override("font_size", 22)
	_streak_label.add_theme_color_override("font_color", Color.WHITE)
	_streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_streak_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_streak_label)

	# Lives (right)
	_lives_container = HBoxContainer.new()
	_lives_container.alignment = BoxContainer.ALIGNMENT_END
	_lives_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(_lives_container)

	_rebuild_lives(3)


func _rebuild_lives(count: int) -> void:
	for child in _lives_container.get_children():
		child.queue_free()
	_life_icons.clear()

	for i in count:
		var heart := TextureRect.new()
		heart.texture = _create_heart_texture(Color(1.0, 0.3, 0.3))
		heart.custom_minimum_size = Vector2(28, 28)
		heart.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_lives_container.add_child(heart)
		_life_icons.append(heart)


static func _create_heart_texture(color: Color) -> ImageTexture:
	var size := 28
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var cx := size * 0.5
	var cy := size * 0.5
	for x in size:
		for y in size:
			var nx := (x - cx) / cx  # -1 to 1
			var ny := (y - cy) / cy  # -1 to 1
			# Heart implicit equation: (x^2 + y^2 - 1)^3 - x^2 * y^3 < 0
			# Shift y up so heart is centered visually
			var sy := ny * 1.2 - 0.2
			var sx := nx * 1.1
			var a := sx * sx + sy * sy - 1.0
			var heart_val := a * a * a - sx * sx * sy * sy * sy
			if heart_val < 0.0:
				# Soft edge anti-alias
				var alpha := clampf(-heart_val * 40.0, 0.0, 1.0)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _on_score_changed(total: int, _earned: int) -> void:
	if not _score_label:
		return
	_score_label.text = str(total)

	# Punch animation
	var tween := create_tween()
	tween.tween_property(_score_label, "scale", Vector2.ONE * (1.0 + punch_scale), punch_duration * 0.3)
	tween.tween_property(_score_label, "scale", Vector2.ONE, punch_duration * 0.7)


func _on_streak_changed(count: int, multiplier: float) -> void:
	if not _streak_label:
		return
	_streak_label.text = "Streak: %d (%.1fx)" % [count, multiplier]

	# Color shift based on multiplier
	var t := clampf((multiplier - 1.0) / 4.0, 0.0, 1.0)
	_streak_label.add_theme_color_override("font_color", Color.WHITE.lerp(Color(1.0, 0.55, 0.0), t))


func _on_life_lost(current_lives: int, _damage: int) -> void:
	var children := _lives_container.get_children()
	# Gray out the lost heart
	if current_lives < children.size():
		var lost_heart := children[current_lives] as TextureRect
		if lost_heart:
			lost_heart.texture = _create_heart_texture(Color(0.3, 0.3, 0.3))
			# Shake remaining hearts
			for i in current_lives:
				var heart := children[i] as TextureRect
				if heart:
					var tween := create_tween()
					tween.tween_property(heart, "position:x", heart.position.x + 4, 0.05)
					tween.tween_property(heart, "position:x", heart.position.x - 4, 0.05)
					tween.tween_property(heart, "position:x", heart.position.x, 0.05)


func _on_run_started() -> void:
	_rebuild_lives(3)
	_score_label.text = "0"
	_streak_label.text = "Streak: 0 (1.0x)"
	_streak_label.add_theme_color_override("font_color", Color.WHITE)
	show_hud()


func _on_run_ended(_stats: Dictionary) -> void:
	hide_hud()
