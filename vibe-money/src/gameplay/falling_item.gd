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
	set_deferred("monitoring", true)
	set_deferred("monitorable", true)

	# Set visual — use Kenney puzzle-pack-2 texture from spawner cache
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite:
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		sprite.modulate = Color.WHITE
		var spawner := get_parent()
		if spawner and spawner.has_method("get_item_texture"):
			sprite.texture = spawner.get_item_texture(item_def.id)
		# Scale to uniform ~36px gameplay size regardless of source dimensions
		var target_px: float = 36.0 * item_def.visual_scale
		var tex_size: float = maxf(sprite.texture.get_width(), sprite.texture.get_height()) if sprite.texture else 128.0
		var uniform_scale: float = target_px / tex_size
		sprite.scale = Vector2.ONE * uniform_scale

	# Fit collision shape to match visual size
	var shape_node := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if shape_node and shape_node.shape is CircleShape2D:
		var col_radius: float = 16.0 * item_def.visual_scale
		(shape_node.shape as CircleShape2D).radius = col_radius


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
