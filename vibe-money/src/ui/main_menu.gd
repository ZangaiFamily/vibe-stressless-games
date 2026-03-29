## Main menu screen — entry point with play button and shop access.
class_name MainMenu
extends CanvasLayer

signal play_pressed
signal shop_pressed

var _bg: ColorRect
var _container: VBoxContainer
var _title_label: Label
var _coins_label: Label
var _play_button: Button
var _shop_button: Button
var _wallet: Node


func _ready() -> void:
	layer = 20
	_build_ui()
	hide_menu()


func bind_wallet(wallet: Node) -> void:
	_wallet = wallet
	if _wallet:
		_wallet.coins_changed.connect(_on_coins_changed)
		_update_coins_display()


func show_menu() -> void:
	_bg.visible = true
	_container.visible = true
	_update_coins_display()


func hide_menu() -> void:
	_bg.visible = false
	_container.visible = false


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.08, 0.15, 0.95)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_container = VBoxContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_container.size = Vector2(400, 500)
	_container.position = Vector2(-200, -250)
	_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_container.add_theme_constant_override("separation", 30)
	add_child(_container)

	# Title
	_title_label = Label.new()
	_title_label.text = "Vibe Money"
	_title_label.add_theme_font_size_override("font_size", 52)
	_title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(_title_label)

	# Coins display
	_coins_label = Label.new()
	_coins_label.text = "0"
	_coins_label.add_theme_font_size_override("font_size", 28)
	_coins_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	_coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_container.add_child(_coins_label)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	_container.add_child(spacer)

	# Play button
	_play_button = _create_button("PLAY", Color(0.2, 0.7, 0.4))
	_play_button.pressed.connect(func(): play_pressed.emit())
	_container.add_child(_play_button)

	# Shop button
	_shop_button = _create_button("SHOP", Color(0.3, 0.5, 0.8))
	_shop_button.pressed.connect(func(): shop_pressed.emit())
	_container.add_child(_shop_button)


func _create_button(text: String, bg_color: Color) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(220, 60)
	btn.add_theme_font_size_override("font_size", 28)

	var style := StyleBoxFlat.new()
	style.bg_color = bg_color
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)

	return btn


func _update_coins_display() -> void:
	if _coins_label and _wallet:
		_coins_label.text = "%d coins" % _wallet.coins


func _on_coins_changed(_current: int, _delta: int) -> void:
	_update_coins_display()
