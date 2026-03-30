## Spawns falling items at timed intervals with weighted random selection.
## See design/gdd/item-spawner.md for specification.
class_name ItemSpawner
extends Node2D

const FallingItemScript = preload("res://src/gameplay/falling_item.gd")

@export var base_spawn_interval: float = 0.6
@export var base_fall_speed: float = 200.0
@export var spawn_columns: int = 5
@export var column_jitter: float = 20.0
@export var max_active_items: int = 30
@export var safe_period: float = 5.0
@export var spawn_margin: float = 32.0

## Packed scene for falling items — assigned in editor or created at runtime
var falling_item_scene: PackedScene

var _spawn_timer: float = 0.0
var _elapsed_time: float = 0.0
var _active: bool = false
var _pool: Array = []
var _last_column: int = -1

## Difficulty multipliers (set by DifficultySystem)
var spawn_rate_multiplier: float = 1.0
var speed_multiplier: float = 1.0
var hazard_ratio_modifier: float = 0.3


func _ready() -> void:
	GameEvents.run_started.connect(_on_run_started)
	GameEvents.run_ended.connect(_on_run_ended)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	_elapsed_time += delta
	_spawn_timer += delta

	var effective_interval := base_spawn_interval / spawn_rate_multiplier
	if _spawn_timer >= effective_interval:
		_spawn_timer -= effective_interval
		_spawn_item()


func start() -> void:
	_active = true
	_elapsed_time = 0.0
	_spawn_timer = -0.8  # Brief delay before first spawn
	_last_column = -1


func stop() -> void:
	_active = false
	# Deactivate all items
	for item in _pool:
		if item.visible:
			item.deactivate()


func _spawn_item() -> void:
	var item_def := _select_item()
	if not item_def:
		return

	var falling_item := _get_pooled_item()
	if not falling_item:
		return

	var spawn_pos := _calculate_spawn_position()
	var fall_speed: float = base_fall_speed * item_def.fall_speed_modifier * speed_multiplier

	falling_item.activate(item_def, spawn_pos, fall_speed)


func _select_item() -> Resource:
	var in_safe_period := _elapsed_time < safe_period

	var spawn_table: Array
	if in_safe_period:
		spawn_table = ItemRegistry.get_items_by_category(0)  # 0 = ItemDef.Category.COIN
	else:
		spawn_table = ItemRegistry.get_spawn_table()

	if spawn_table.is_empty():
		return null

	# Build adjusted weights
	var weights: Array = []
	var total_weight := 0.0

	for item in spawn_table:
		var w: float = item.rarity_weight
		if not in_safe_period:
			if item.category == 1:  # 1 = ItemDef.Category.HAZARD
				w *= hazard_ratio_modifier / 0.5  # Normalize around 0.5 base
			else:
				w *= (1.0 - hazard_ratio_modifier) / 0.5
		total_weight += w
		weights.append(w)

	if total_weight <= 0.0:
		return null

	# Weighted random selection
	var roll := randf() * total_weight
	var cumulative := 0.0
	for i in spawn_table.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return spawn_table[i]

	return spawn_table[-1]


func _calculate_spawn_position() -> Vector2:
	var vp_width := get_viewport_rect().size.x
	var usable_width := vp_width - spawn_margin * 2.0
	var col_width := usable_width / spawn_columns

	# Pick column, avoiding previous
	var col := randi_range(0, spawn_columns - 1)
	if spawn_columns > 1 and col == _last_column:
		col = (col + randi_range(1, spawn_columns - 1)) % spawn_columns
	_last_column = col

	var col_center := spawn_margin + (col + 0.5) * col_width
	var x := clampf(
		col_center + randf_range(-column_jitter, column_jitter),
		spawn_margin,
		vp_width - spawn_margin
	)

	return Vector2(x, -30.0)


func _get_pooled_item() -> Node:
	# Find inactive item in pool
	for item in _pool:
		if not item.visible:
			return item

	# Pool not full — create new
	if _pool.size() < max_active_items:
		var item := _create_falling_item()
		_pool.append(item)
		add_child(item)
		return item

	return null


func _create_falling_item() -> Node:
	if falling_item_scene:
		return falling_item_scene.instantiate()

	# Fallback: create programmatically
	var item := Area2D.new()
	item.set_script(FallingItemScript)
	item.name = "FallingItem_%d" % _pool.size()
	item.collision_layer = 2
	item.collision_mask = 1

	var collision := CollisionShape2D.new()
	collision.name = "CollisionShape2D"
	collision.shape = CircleShape2D.new()
	item.add_child(collision)

	# Placeholder sprite (circle)
	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = _create_circle_texture()
	item.add_child(sprite)

	# Set initial state directly (don't call deactivate() here — its
	# set_deferred would overwrite activate()'s immediate monitoring=true)
	item.visible = false
	item.monitoring = false
	item.monitorable = false
	item.position = Vector2(-100, -100)
	return item


func _create_circle_texture() -> ImageTexture:
	var size := 32
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)
	var radius := size * 0.4
	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha := 1.0 - smoothstep(radius - 2.0, radius, dist)
				img.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _on_run_started() -> void:
	start()


func _on_run_ended(_stats: Dictionary) -> void:
	stop()
