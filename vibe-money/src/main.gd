## Main scene — wires all systems together and starts the game.
## See docs/architecture/adr-0001-core-architecture.md for architecture.
extends Node2D

# Preload all scripts (avoids class_name cache dependency)
const PlayerControllerScript = preload("res://src/gameplay/player_controller.gd")
const InputSystemScript = preload("res://src/core/input_system.gd")
const ItemSpawnerScript = preload("res://src/gameplay/item_spawner.gd")
const CollectionSystemScript = preload("res://src/gameplay/collection_system.gd")
const DifficultyCurveScript = preload("res://src/gameplay/difficulty_curve.gd")
const ScoreSystemScript = preload("res://src/gameplay/score_system.gd")
const LivesSystemScript = preload("res://src/gameplay/lives_system.gd")
const StreakMultiplierScript = preload("res://src/gameplay/streak_multiplier.gd")
const RunManagerScript = preload("res://src/gameplay/run_manager.gd")
const RainVFXScript = preload("res://src/presentation/rain_vfx.gd")
const ParallaxBGScript = preload("res://src/presentation/parallax_bg.gd")
const GameJuiceScript = preload("res://src/presentation/game_juice.gd")
const HUDScript = preload("res://src/ui/hud.gd")
const RunSummaryScript = preload("res://src/ui/run_summary.gd")

# Gameplay systems
var _player: Node
var _spawner: Node
var _collection: Node
var _difficulty: Node
var _score: Node
var _lives: Node
var _streak: Node
var _run_manager: Node

# Presentation
var _rain: Node
var _bg: Node
var _juice: Node
var _camera: Camera2D

# UI
var _hud: Node
var _summary: Node


func _ready() -> void:
	_setup_camera()
	_setup_presentation()
	_setup_player()
	_setup_gameplay_systems()
	_setup_ui()
	_wire_systems()

	# Auto-start first run after a brief pause
	await get_tree().create_timer(0.5).timeout
	_run_manager.start_run()


func _process(_delta: float) -> void:
	if _player and _bg:
		_bg.update_player_position(_player.position.x, get_viewport_rect().size.x)


func _setup_camera() -> void:
	_camera = Camera2D.new()
	_camera.name = "Camera"
	var vp_size := get_viewport_rect().size
	_camera.position = vp_size * 0.5
	add_child(_camera)
	_camera.make_current()


func _setup_presentation() -> void:
	var bg_node := CanvasLayer.new()
	bg_node.set_script(ParallaxBGScript)
	bg_node.name = "ParallaxBG"
	_bg = bg_node
	add_child(_bg)

	var rain_node := Node2D.new()
	rain_node.set_script(RainVFXScript)
	rain_node.name = "RainVFX"
	_rain = rain_node
	add_child(_rain)


func _setup_player() -> void:
	var player_node := CharacterBody2D.new()
	player_node.set_script(PlayerControllerScript)
	player_node.name = "Player"
	_player = player_node

	var input := Node.new()
	input.set_script(InputSystemScript)
	input.name = "InputSystem"
	_player.add_child(input)

	var area := Area2D.new()
	area.name = "CollectionArea"
	area.collision_layer = 1
	area.collision_mask = 2
	_player.add_child(area)

	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = 16.0
	area.add_child(shape)

	var sprite := Sprite2D.new()
	sprite.name = "Sprite2D"
	sprite.texture = _create_player_texture()
	_player.add_child(sprite)

	add_child(_player)


func _setup_gameplay_systems() -> void:
	var spawner_node := Node2D.new()
	spawner_node.set_script(ItemSpawnerScript)
	spawner_node.name = "ItemSpawner"
	_spawner = spawner_node
	add_child(_spawner)

	_collection = _create_node(CollectionSystemScript, "CollectionSystem")
	add_child(_collection)

	_difficulty = _create_node(DifficultyCurveScript, "DifficultyCurve")
	add_child(_difficulty)

	_score = _create_node(ScoreSystemScript, "ScoreSystem")
	add_child(_score)

	_lives = _create_node(LivesSystemScript, "LivesSystem")
	add_child(_lives)

	_streak = _create_node(StreakMultiplierScript, "StreakMultiplier")
	add_child(_streak)

	_run_manager = _create_node(RunManagerScript, "RunManager")
	add_child(_run_manager)


func _setup_ui() -> void:
	_juice = _create_node(GameJuiceScript, "GameJuice")
	add_child(_juice)

	var hud_node := CanvasLayer.new()
	hud_node.set_script(HUDScript)
	hud_node.name = "HUD"
	_hud = hud_node
	add_child(_hud)

	var summary_node := CanvasLayer.new()
	summary_node.set_script(RunSummaryScript)
	summary_node.name = "RunSummary"
	_summary = summary_node
	add_child(_summary)


func _wire_systems() -> void:
	_collection.setup(_player.get_node("CollectionArea"))
	_score.bind_streak(_streak)
	_difficulty.bind_spawner(_spawner)
	_run_manager.bind_systems(_score, _spawner, _difficulty)
	_juice.bind_camera(_camera)
	_juice.bind_rain(_rain)
	_summary.bind_run_manager(_run_manager)


func _create_node(script: GDScript, node_name: String) -> Node:
	var node := Node.new()
	node.set_script(script)
	node.name = node_name
	return node


func _create_player_texture() -> ImageTexture:
	var size := 48
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(size * 0.5, size * 0.5)

	for x in size:
		for y in size:
			var dist := Vector2(x, y).distance_to(Vector2(center.x, center.y + 4))
			if y < size * 0.55 and dist < size * 0.4:
				var alpha := 1.0 - smoothstep(size * 0.38, size * 0.4, dist)
				img.set_pixel(x, y, Color(0.3, 0.5, 0.8, alpha))
			elif y >= size * 0.55 and absf(x - center.x) < 2:
				img.set_pixel(x, y, Color(0.4, 0.3, 0.2, 0.9))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)
