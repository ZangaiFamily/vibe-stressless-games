# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends Node2D

@onready var player: CharacterBody2D = $Player


func _ready() -> void:
	# Set up player sprite — draw a simple character with umbrella
	_setup_player_visual()

	# Set up collision shapes
	_setup_collision_shapes()

	# Set up fonts/theme
	_setup_theme()

	# Auto-start first run
	GameManager.start_run()


func _setup_player_visual() -> void:
	var sprite: Sprite2D = player.get_node("Sprite2D")

	# Create a simple character texture — circle body + umbrella
	var img := Image.create(48, 48, false, Image.FORMAT_RGBA8)

	# Umbrella (top half) — soft purple-blue
	var umbrella_color := Color(0.45, 0.35, 0.7, 1.0)
	var umbrella_rim := Color(0.55, 0.45, 0.8, 1.0)
	for x in range(48):
		for y in range(0, 24):
			var dx := x - 24.0
			var dy := y - 22.0
			var dist := sqrt(dx * dx + (dy * dy) * 1.5)
			if dist <= 20.0:
				img.set_pixel(x, y, umbrella_color)
			elif dist <= 21.0:
				img.set_pixel(x, y, umbrella_rim)

	# Umbrella handle — thin line
	var handle_color := Color(0.35, 0.25, 0.5)
	for y in range(22, 38):
		img.set_pixel(24, y, handle_color)

	# Body (small circle at bottom)
	var body_color := Color(0.9, 0.85, 0.7)
	for x in range(48):
		for y in range(32, 48):
			var dist := Vector2(x, y).distance_to(Vector2(24, 40))
			if dist <= 7.0:
				img.set_pixel(x, y, body_color)
			elif dist <= 8.0:
				img.set_pixel(x, y, Color(body_color.r * 0.7, body_color.g * 0.7, body_color.b * 0.7))

	var tex := ImageTexture.create_from_image(img)
	sprite.texture = tex


func _setup_collision_shapes() -> void:
	# Player physics collision
	var player_collision: CollisionShape2D = player.get_node("PlayerCollision")
	var player_shape := CapsuleShape2D.new()
	player_shape.radius = 20.0
	player_shape.height = 60.0
	player_collision.shape = player_shape

	# Collection area — slightly larger than visual
	var collect_collision: CollisionShape2D = player.get_node("CollectArea/CollectShape")
	var collect_shape := CircleShape2D.new()
	collect_shape.radius = 45.0
	collect_collision.shape = collect_shape


func _setup_theme() -> void:
	# Make score label big and readable
	var hud := $HUD
	var score_label: Label = hud.get_node("ScoreLabel")
	score_label.add_theme_font_size_override("font_size", 48)
	score_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 0.9))

	var streak_label: Label = hud.get_node("StreakLabel")
	streak_label.add_theme_font_size_override("font_size", 24)
	streak_label.add_theme_color_override("font_color", Color(0.7, 0.8, 1.0, 0.8))

	var mult_label: Label = hud.get_node("MultiplierLabel")
	mult_label.add_theme_font_size_override("font_size", 20)

	var combo: Label = hud.get_node("ComboPopup")
	combo.add_theme_font_size_override("font_size", 36)
	combo.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))

	# Hearts
	for heart: Label in hud.get_node("LivesContainer").get_children():
		heart.add_theme_font_size_override("font_size", 28)

	# Run summary styling
	var summary_panel := $RunSummary/Panel/VBox
	var title: Label = summary_panel.get_node("Title")
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))

	for row_name: String in ["ScoreRow", "StreakRow", "CoinsRow", "TimeRow"]:
		var row := summary_panel.get_node(row_name)
		for child: Node in row.get_children():
			if child is Label:
				child.add_theme_font_size_override("font_size", 22)

	var retry_btn: Button = summary_panel.get_node("RetryButton")
	retry_btn.add_theme_font_size_override("font_size", 24)


func _unhandled_input(event: InputEvent) -> void:
	# Quick restart with R key
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		if not GameManager.is_running:
			GameManager.start_run()
