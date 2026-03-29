## End-of-run stats display with retry/menu buttons.
## See design/gdd/run-summary-screen.md for specification.
class_name RunSummary
extends CanvasLayer

@export var count_up_duration: float = 1.0
@export var appear_duration: float = 0.3
@export var overlay_opacity: float = 0.6

var _panel: PanelContainer
var _overlay: ColorRect
var _score_label: Label
var _streak_label: Label
var _coins_label: Label
var _earned_label: Label
var _duration_label: Label
var _high_score_label: Label
var _retry_button: Button
var _menu_button: Button
var _run_manager: Node
var _wallet: Node
var _is_visible: bool = false


func _ready() -> void:
	layer = 20  # Above HUD
	_build_ui()
	_hide()

	GameEvents.run_ended.connect(_on_run_ended)


func bind_run_manager(rm: Node) -> void:
	_run_manager = rm


func bind_wallet(wallet: Node) -> void:
	_wallet = wallet


func _build_ui() -> void:
	# Dark overlay
	_overlay = ColorRect.new()
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0, 0, 0, overlay_opacity)
	add_child(_overlay)

	# Center panel
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(500, 600)
	center.add_child(_panel)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 24)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Run Complete"
	title.add_theme_font_size_override("font_size", 40)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	# Score
	_score_label = Label.new()
	_score_label.text = "0"
	_score_label.add_theme_font_size_override("font_size", 56)
	_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_score_label)

	# High score banner
	_high_score_label = Label.new()
	_high_score_label.text = "NEW HIGH SCORE!"
	_high_score_label.add_theme_font_size_override("font_size", 24)
	_high_score_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_high_score_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_high_score_label.visible = false
	vbox.add_child(_high_score_label)

	# Stats
	_streak_label = _create_stat_label(vbox, "Best Streak: 0")
	_coins_label = _create_stat_label(vbox, "Coins: 0")
	_earned_label = _create_stat_label(vbox, "")
	_earned_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_duration_label = _create_stat_label(vbox, "Time: 0:00")

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 20
	vbox.add_child(spacer)

	# Retry button
	_retry_button = _create_styled_button("RETRY", Color(0.2, 0.65, 0.35))
	_retry_button.pressed.connect(_on_retry)
	vbox.add_child(_retry_button)

	# Menu button
	_menu_button = _create_styled_button("MENU", Color(0.35, 0.35, 0.45))
	_menu_button.pressed.connect(_on_menu)
	vbox.add_child(_menu_button)


func _create_styled_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(280, 56)
	btn.add_theme_font_size_override("font_size", 22)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.9, 0.9, 0.9))

	# Styled background
	var normal := StyleBoxFlat.new()
	normal.bg_color = bg_color
	normal.corner_radius_top_left = 12
	normal.corner_radius_top_right = 12
	normal.corner_radius_bottom_left = 12
	normal.corner_radius_bottom_right = 12
	normal.content_margin_top = 12
	normal.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = bg_color.lerp(Color.WHITE, 0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = bg_color.lerp(Color.BLACK, 0.2)
	btn.add_theme_stylebox_override("pressed", pressed)

	return btn


func _create_stat_label(parent: VBoxContainer, text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", 22)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	return label


func _on_run_ended(run_stats: Dictionary) -> void:
	_show(run_stats)


func _show(stats: Dictionary) -> void:
	_is_visible = true
	_overlay.visible = true
	_panel.visible = true

	var final_score: int = stats.get("final_score", 0)
	var longest_streak: int = stats.get("longest_streak", 0)
	var coins: int = stats.get("coins_collected", 0)
	var duration: float = stats.get("run_duration", 0.0)
	var is_high: bool = stats.get("is_high_score", false)

	_streak_label.text = "Best Streak: %d" % longest_streak
	_coins_label.text = "Coins: %d" % coins
	_duration_label.text = "Time: %d:%02d" % [int(duration) / 60, int(duration) % 60]
	_high_score_label.visible = is_high

	# Award currency based on score (1 coin per 10 points)
	var earned: int = final_score / 10
	if _wallet and earned > 0:
		_wallet.add_coins(earned)
		_earned_label.text = "+%d coins earned!" % earned
	else:
		_earned_label.text = ""

	# Count-up animation
	_score_label.text = "0"
	var tween := create_tween()
	tween.tween_method(_update_score_display.bind(final_score), 0.0, 1.0, count_up_duration).set_ease(Tween.EASE_OUT)

	# Appear animation
	_overlay.modulate.a = 0.0
	_panel.modulate.a = 0.0
	_panel.position.y = 50
	var appear := create_tween().set_parallel(true)
	appear.tween_property(_overlay, "modulate:a", 1.0, appear_duration)
	appear.tween_property(_panel, "modulate:a", 1.0, appear_duration)
	appear.tween_property(_panel, "position:y", 0.0, appear_duration)


func _hide() -> void:
	_is_visible = false
	_overlay.visible = false
	_panel.visible = false


func _update_score_display(t: float, final_score: int) -> void:
	_score_label.text = str(int(t * final_score))


func _on_retry() -> void:
	_hide()
	if _run_manager:
		_run_manager.start_run()


func _on_menu() -> void:
	_hide()
	GameEvents.return_to_menu.emit()
