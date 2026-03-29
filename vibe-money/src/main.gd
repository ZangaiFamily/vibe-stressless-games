## Main scene — wires all systems together and manages game flow.
## Flow: Main Menu -> Gameplay -> Run Summary -> Menu/Retry
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
const MainMenuScript = preload("res://src/ui/main_menu.gd")
const ShopScreenScript = preload("res://src/ui/shop_screen.gd")
const WalletScript = preload("res://src/core/wallet.gd")
const CosmeticSystemScript = preload("res://src/core/cosmetic_system.gd")
const SaveManagerScript = preload("res://src/core/save_manager.gd")

# Gameplay systems
var _player: Node
var _spawner: Node
var _collection: Node
var _difficulty: Node
var _score: Node
var _lives: Node
var _streak: Node
var _run_manager: Node

# Core systems
var _wallet: Node
var _cosmetics: Node
var _save_manager: Node

# Presentation
var _rain: Node
var _bg: Node
var _juice: Node
var _camera: Camera2D

# UI
var _hud: Node
var _summary: Node
var _main_menu: Node
var _shop: Node

# Player visual reference
var _player_sprite: Sprite2D


func _ready() -> void:
	_setup_core_systems()
	_setup_camera()
	_setup_presentation()
	_setup_player()
	_setup_gameplay_systems()
	_setup_ui()
	_wire_systems()
	_load_save()

	# Show main menu on start
	_main_menu.show_menu()


func _process(_delta: float) -> void:
	if _player and _bg:
		_bg.update_player_position(_player.position.x, get_viewport_rect().size.x)


func _setup_core_systems() -> void:
	_wallet = _create_node(WalletScript, "Wallet")
	add_child(_wallet)

	_cosmetics = _create_node(CosmeticSystemScript, "CosmeticSystem")
	add_child(_cosmetics)

	_save_manager = _create_node(SaveManagerScript, "SaveManager")
	add_child(_save_manager)


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
	var rect_shape := RectangleShape2D.new()
	# Match paddle visual: 500*0.16=80 wide, 120*0.16=19 tall
	rect_shape.size = Vector2(80.0, 19.0)
	shape.shape = rect_shape
	area.add_child(shape)

	_player_sprite = Sprite2D.new()
	_player_sprite.name = "Sprite2D"
	_player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	_player_sprite.texture = load("res://assets/art/puzzle/player_paddle.png")
	# Paddle is 500x120 — scale to ~80px wide, preserving aspect ratio
	_player_sprite.scale = Vector2(0.16, 0.16)
	_player.add_child(_player_sprite)

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

	# Main menu
	var menu_node := CanvasLayer.new()
	menu_node.set_script(MainMenuScript)
	menu_node.name = "MainMenu"
	_main_menu = menu_node
	add_child(_main_menu)

	# Shop
	var shop_node := CanvasLayer.new()
	shop_node.set_script(ShopScreenScript)
	shop_node.name = "ShopScreen"
	_shop = shop_node
	add_child(_shop)


func _wire_systems() -> void:
	_collection.setup(_player.get_node("CollectionArea"))
	_score.bind_streak(_streak)
	_difficulty.bind_spawner(_spawner)
	_run_manager.bind_systems(_score, _spawner, _difficulty)
	_juice.bind_camera(_camera)
	_juice.bind_rain(_rain)
	_summary.bind_run_manager(_run_manager)
	_summary.bind_wallet(_wallet)
	_save_manager.bind_systems(_wallet, _cosmetics)

	# Main menu signals
	_main_menu.bind_wallet(_wallet)
	_main_menu.play_pressed.connect(_on_play_pressed)
	_main_menu.shop_pressed.connect(_on_shop_pressed)

	# Shop signals
	_shop.bind_systems(_wallet, _cosmetics)
	_shop.back_pressed.connect(_on_shop_back)

	# Navigation
	GameEvents.return_to_menu.connect(_on_return_to_menu)

	# Auto-save after each run
	GameEvents.run_ended.connect(_on_run_ended_save)

	# Update player color when cosmetic changes
	if _cosmetics:
		_cosmetics.cosmetic_equipped.connect(_on_cosmetic_equipped)


func _on_play_pressed() -> void:
	_main_menu.hide_menu()
	_apply_cosmetics()
	await get_tree().create_timer(0.2).timeout
	_run_manager.start_run()


func _on_shop_pressed() -> void:
	_main_menu.hide_menu()
	_shop.show_shop()


func _on_shop_back() -> void:
	_shop.hide_shop()
	_main_menu.show_menu()


func _on_return_to_menu() -> void:
	_main_menu.show_menu()


func _on_run_ended_save(_stats: Dictionary) -> void:
	_save_manager.save_game()


func _on_cosmetic_equipped(_id: String, _type: int) -> void:
	_apply_cosmetics()


func _apply_cosmetics() -> void:
	if _player_sprite and _cosmetics:
		_player_sprite.modulate = _get_player_color().lerp(Color.WHITE, 0.5)


func _get_player_color() -> Color:
	if _cosmetics:
		return _cosmetics.get_equipped_color(0)  # CHARACTER type
	return Color(0.3, 0.5, 0.8)


func _load_save() -> void:
	_save_manager.load_game()


func _create_node(script: GDScript, node_name: String) -> Node:
	var node := Node.new()
	node.set_script(script)
	node.name = node_name
	return node
