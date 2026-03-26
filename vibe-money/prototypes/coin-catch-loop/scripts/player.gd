# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends CharacterBody2D

const SPEED := 600.0
const SMOOTH_FACTOR := 12.0

var screen_width: float
var target_x: float
var is_touch_active := false
var touch_index := -1

@onready var sprite: Sprite2D = $Sprite2D
@onready var collect_area: Area2D = $CollectArea
@onready var anim_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null


func _ready() -> void:
	screen_width = get_viewport_rect().size.x
	target_x = position.x
	collect_area.area_entered.connect(_on_area_entered)


func _physics_process(delta: float) -> void:
	# Keyboard input
	var input_dir := Input.get_axis("move_left", "move_right")
	if input_dir != 0.0:
		target_x = position.x + input_dir * SPEED * delta * 3.0

	# Touch input — follow finger X
	if is_touch_active:
		pass  # target_x set in _input

	# Smooth movement toward target
	var new_x := lerpf(position.x, target_x, SMOOTH_FACTOR * delta)
	new_x = clampf(new_x, 40.0, screen_width - 40.0)
	velocity.x = (new_x - position.x) / delta
	velocity.y = 0.0
	move_and_slide()

	# Slight tilt based on movement
	if sprite:
		sprite.rotation = velocity.x * 0.00008


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_active = true
			touch_index = event.index
			target_x = event.position.x
		elif event.index == touch_index:
			is_touch_active = false
			touch_index = -1

	elif event is InputEventScreenDrag:
		if event.index == touch_index:
			target_x = event.position.x

	# Mouse fallback for desktop testing
	elif event is InputEventMouseButton:
		if event.pressed:
			is_touch_active = true
			target_x = event.position.x
		else:
			is_touch_active = false

	elif event is InputEventMouseMotion:
		if is_touch_active:
			target_x = event.position.x


func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("coins"):
		_collect_coin(area)
	elif area.is_in_group("hazards"):
		_hit_hazard(area)


func _collect_coin(coin: Area2D) -> void:
	var coin_data: Dictionary = coin.get_meta("coin_data", {"value": 1, "type": "bronze"})
	GameManager.collect_coin(coin_data)
	_spawn_collect_particles(coin.global_position, coin_data.type)
	coin.queue_free()


func _hit_hazard(hazard: Area2D) -> void:
	var hazard_type: String = hazard.get_meta("hazard_type", "bomb")
	GameManager.hit_hazard(hazard_type)
	_spawn_hit_particles(hazard.global_position)
	hazard.queue_free()
	_do_hit_feedback()


func _do_hit_feedback() -> void:
	# Screen shake via camera
	var tween := create_tween()
	var original_pos := position
	tween.tween_property(self, "position:x", position.x + 15, 0.05)
	tween.tween_property(self, "position:x", position.x - 15, 0.05)
	tween.tween_property(self, "position:x", position.x, 0.05)
	# Flash red
	if sprite:
		sprite.modulate = Color(1.0, 0.3, 0.3)
		var flash_tween := create_tween()
		flash_tween.tween_property(sprite, "modulate", Color.WHITE, 0.3)


func _spawn_collect_particles(pos: Vector2, type: String) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 12
	particles.lifetime = 0.5
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 60.0
	particles.initial_velocity_min = 100.0
	particles.initial_velocity_max = 200.0
	particles.gravity = Vector2(0, 300)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 4.0

	match type:
		"gold":
			particles.color = Color(1.0, 0.85, 0.0)
		"silver":
			particles.color = Color(0.8, 0.8, 0.9)
		_:
			particles.color = Color(0.85, 0.55, 0.2)

	particles.global_position = pos
	get_tree().current_scene.add_child(particles)
	# Auto cleanup
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)


func _spawn_hit_particles(pos: Vector2) -> void:
	var particles := CPUParticles2D.new()
	particles.emitting = true
	particles.one_shot = true
	particles.amount = 20
	particles.lifetime = 0.4
	particles.explosiveness = 1.0
	particles.direction = Vector2(0, -1)
	particles.spread = 180.0
	particles.initial_velocity_min = 80.0
	particles.initial_velocity_max = 160.0
	particles.gravity = Vector2(0, 400)
	particles.scale_amount_min = 2.0
	particles.scale_amount_max = 5.0
	particles.color = Color(1.0, 0.2, 0.2)
	particles.global_position = pos
	get_tree().current_scene.add_child(particles)
	var timer := get_tree().create_timer(1.0)
	timer.timeout.connect(particles.queue_free)
