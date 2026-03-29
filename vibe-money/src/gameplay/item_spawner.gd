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
	_spawn_timer = 0.0
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

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	item.add_child(sprite)

	# Set initial inactive state directly — do NOT call deactivate() here,
	# because its set_deferred("monitoring", false) would override activate()
	# if the item is used in the same frame.
	item.visible = false
	item.monitoring = false
	item.monitorable = false
	item.position = Vector2(-100, -100)
	return item


## Kenney puzzle-pack-2 textures (128x128 each)
const KENNEY_TEXTURES: Dictionary = {
	&"coin_bronze": "res://assets/art/puzzle/coin_bronze.png",
	&"coin_silver": "res://assets/art/puzzle/coin_silver.png",
	&"coin_gold": "res://assets/art/puzzle/coin_gold.png",
	&"coin_emerald": "res://assets/art/puzzle/coin_emerald.png",
	&"coin_diamond": "res://assets/art/puzzle/coin_diamond.png",
	&"hazard_bomb": "res://assets/art/puzzle/hazard_bomb.png",
	&"hazard_poop": "res://assets/art/puzzle/hazard_poop.png",
	&"hazard_spike": "res://assets/art/puzzle/hazard_spike.png",
	&"hazard_lightning": "res://assets/art/puzzle/hazard_lightning.png",
	&"hazard_trash": "res://assets/art/puzzle/hazard_trash.png",
	&"hazard_ice": "res://assets/art/puzzle/hazard_ice.png",
}

## Texture cache — loaded on first use per item ID.
var _texture_cache: Dictionary = {}  # StringName -> Texture2D


func get_item_texture(item_id: StringName) -> Texture2D:
	if _texture_cache.has(item_id):
		return _texture_cache[item_id]
	var tex := _load_item_texture(item_id)
	_texture_cache[item_id] = tex
	return tex


func _load_item_texture(item_id: StringName) -> Texture2D:
	if KENNEY_TEXTURES.has(item_id):
		var path: String = KENNEY_TEXTURES[item_id]
		var tex := load(path) as Texture2D
		if tex:
			return tex
		push_warning("[ItemSpawner] Failed to load texture: %s" % path)
	# Fallback — white circle
	return _create_fallback_texture()


func _create_fallback_texture() -> ImageTexture:
	var size := 18
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size * 0.5, size * 0.5)
	var r := size * 0.45
	for x in size:
		for y in size:
			var d := Vector2(x, y).distance_to(c)
			if d <= r:
				img.set_pixel(x, y, Color.WHITE)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(img)


func _on_run_started() -> void:
	start()


func _on_run_ended(_stats: Dictionary) -> void:
	stop()
