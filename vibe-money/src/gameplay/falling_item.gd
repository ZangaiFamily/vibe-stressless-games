## A single falling item (coin or hazard) in the game world.
## Spawned and pooled by ItemSpawner. Collision handled by CollectionSystem.
class_name FallingItem
extends Area2D

var item_def: Resource
var fall_speed: float = 200.0
var _active: bool = false


func activate(p_item_def: Resource, p_position: Vector2, p_fall_speed: float) -> void:
	item_def = p_item_def
	fall_speed = p_fall_speed
	position = p_position
	_active = true
	visible = true
	monitoring = true
	monitorable = true

	# Set collision shape from item def
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		(shape_node.shape as CircleShape2D).radius = item_def.hitbox_radius

	# Set visual
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.scale = Vector2.ONE * item_def.visual_scale
		match item_def.id:
			&"coin_bronze": sprite.modulate = Color(0.8, 0.6, 0.3)
			&"coin_silver": sprite.modulate = Color(0.8, 0.8, 0.9)
			&"coin_gold": sprite.modulate = Color(1.0, 0.85, 0.2)
			&"hazard_bomb": sprite.modulate = Color(0.3, 0.3, 0.3)
			&"hazard_poop": sprite.modulate = Color(0.5, 0.35, 0.2)
			&"hazard_spike": sprite.modulate = Color(0.7, 0.1, 0.1)


func deactivate() -> void:
	_active = false
	visible = false
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	position = Vector2(-100, -100)


func _physics_process(delta: float) -> void:
	if not _active:
		return

	position.y += fall_speed * delta

	# Remove when off-screen
	if position.y > get_viewport_rect().size.y + 50.0:
		deactivate()
