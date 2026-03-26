# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends Node2D

@export var coin_scene: PackedScene
@export var hazard_scene: PackedScene

var screen_width: float
var spawn_timer: float = 0.0
var coin_timer: float = 0.0

# Spawn rates (items per second) — scale with difficulty
const BASE_COIN_RATE := 1.5
const MAX_COIN_RATE := 3.0
const BASE_HAZARD_RATE := 0.3
const MAX_HAZARD_RATE := 1.5

# Item fall speeds
const BASE_FALL_SPEED := 300.0
const MAX_FALL_SPEED := 550.0

# Coin types with weights and values
const COIN_TYPES := [
	{"type": "bronze", "value": 1, "weight": 70, "color": Color(0.85, 0.55, 0.2), "size": 1.0},
	{"type": "silver", "value": 3, "weight": 25, "color": Color(0.8, 0.8, 0.9), "size": 1.2},
	{"type": "gold", "value": 10, "weight": 5, "color": Color(1.0, 0.85, 0.0), "size": 1.4},
]

const HAZARD_TYPES := [
	{"type": "bomb", "weight": 50, "color": Color(0.2, 0.2, 0.2), "size": 1.3, "emoji": "💣"},
	{"type": "poop", "weight": 30, "color": Color(0.45, 0.3, 0.15), "size": 1.0, "emoji": "💩"},
	{"type": "spike", "weight": 20, "color": Color(0.6, 0.1, 0.1), "size": 1.1, "emoji": "⚡"},
]


func _ready() -> void:
	screen_width = get_viewport_rect().size.x


func _process(delta: float) -> void:
	if not GameManager.is_running:
		return

	var diff := GameManager.difficulty

	# Spawn coins
	var coin_rate := lerpf(BASE_COIN_RATE, MAX_COIN_RATE, diff)
	coin_timer += delta
	if coin_timer >= 1.0 / coin_rate:
		coin_timer = 0.0
		_spawn_coin(diff)

	# Spawn hazards — delayed start (no hazards first 3 seconds)
	if GameManager.run_time > 3.0:
		var hazard_rate := lerpf(BASE_HAZARD_RATE, MAX_HAZARD_RATE, diff)
		spawn_timer += delta
		if spawn_timer >= 1.0 / hazard_rate:
			spawn_timer = 0.0
			_spawn_hazard(diff)


func _spawn_coin(diff: float) -> void:
	var coin_data := _pick_weighted(COIN_TYPES, diff)
	var coin := _create_falling_item(coin_data, true)
	coin.set_meta("coin_data", {"value": coin_data.value, "type": coin_data.type})
	add_child(coin)


func _spawn_hazard(diff: float) -> void:
	var hazard_data := _pick_weighted(HAZARD_TYPES, diff)
	var hazard := _create_falling_item(hazard_data, false)
	hazard.set_meta("hazard_type", hazard_data.type)
	add_child(hazard)


func _create_falling_item(data: Dictionary, is_coin: bool) -> Area2D:
	var item := Area2D.new()
	item.add_to_group("coins" if is_coin else "hazards")

	# Visual — colored circle/square
	var visual := Sprite2D.new()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var center := Vector2(16, 16)
	var radius := 14.0

	if is_coin:
		# Draw circle for coins
		for x in range(32):
			for y in range(32):
				var dist := Vector2(x, y).distance_to(center)
				if dist <= radius:
					var c: Color = data.color
					# Add slight gradient for depth
					var brightness := 1.0 - (dist / radius) * 0.3
					img.set_pixel(x, y, Color(c.r * brightness, c.g * brightness, c.b * brightness, 1.0))
				elif dist <= radius + 1.0:
					img.set_pixel(x, y, Color(data.color.r * 0.5, data.color.g * 0.5, data.color.b * 0.5, 0.5))
	else:
		# Draw diamond/square for hazards
		for x in range(32):
			for y in range(32):
				var dx := absf(x - 16.0)
				var dy := absf(y - 16.0)
				if dx + dy <= 14.0:
					img.set_pixel(x, y, data.color)
				elif dx + dy <= 15.0:
					img.set_pixel(x, y, Color(data.color.r * 0.5, data.color.g * 0.5, data.color.b * 0.5, 0.5))

	var tex := ImageTexture.create_from_image(img)
	visual.texture = tex
	visual.scale = Vector2.ONE * data.size
	item.add_child(visual)

	# Label for hazards
	if not is_coin:
		var label := Label.new()
		label.text = data.get("emoji", "X")
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-12, -16)
		label.add_theme_font_size_override("font_size", 20)
		item.add_child(label)
	else:
		# Coin symbol
		var label := Label.new()
		match data.type:
			"gold":
				label.text = "G"
			"silver":
				label.text = "S"
			_:
				label.text = "C"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-6, -10)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		item.add_child(label)

	# Collision
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 16.0 * data.size
	collision.shape = shape
	item.add_child(collision)

	# Position — random X, above screen
	var margin := 50.0
	item.position = Vector2(
		randf_range(margin, screen_width - margin),
		-50.0
	)

	# Fall speed
	var fall_speed := lerpf(BASE_FALL_SPEED, MAX_FALL_SPEED, GameManager.difficulty)
	fall_speed *= randf_range(0.85, 1.15)  # slight variation

	# Add slight horizontal wobble for coins
	var wobble := 0.0
	if is_coin:
		wobble = randf_range(-30.0, 30.0)

	# Movement script via metadata
	item.set_meta("fall_speed", fall_speed)
	item.set_meta("wobble", wobble)
	item.set_meta("time", randf() * TAU)  # random phase for wobble
	item.set_script(_falling_item_script)

	return item


# Inline script for falling items
static var _falling_item_script: GDScript:
	get:
		if _falling_item_script == null:
			_falling_item_script = GDScript.new()
			_falling_item_script.source_code = """
extends Area2D

func _process(delta: float) -> void:
	var speed: float = get_meta("fall_speed", 300.0)
	var wobble: float = get_meta("wobble", 0.0)
	var t: float = get_meta("time", 0.0) + delta * 3.0
	set_meta("time", t)

	position.y += speed * delta
	position.x += sin(t) * wobble * delta

	# Slight rotation for visual interest
	if is_in_group("coins"):
		rotation = sin(t * 2.0) * 0.15
	else:
		rotation += delta * 2.0

	# Remove when off screen
	if position.y > 1400:
		queue_free()
"""
			_falling_item_script.reload()
		return _falling_item_script


func _pick_weighted(items: Array, _diff: float) -> Dictionary:
	var total_weight := 0
	for item: Dictionary in items:
		total_weight += item.weight

	var roll := randi() % total_weight
	var cumulative := 0
	for item: Dictionary in items:
		cumulative += item.weight
		if roll < cumulative:
			return item

	return items[0]
