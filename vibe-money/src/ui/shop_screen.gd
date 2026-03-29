## Shop screen for buying and equipping cosmetics.
class_name ShopScreen
extends CanvasLayer

signal back_pressed

var _wallet: Node
var _cosmetics: Node
var _bg: ColorRect
var _container: VBoxContainer
var _items_container: VBoxContainer
var _coins_label: Label
var _tab_characters: Button
var _tab_umbrellas: Button
var _back_button: Button
var _current_tab: int = 0  # 0 = characters, 1 = umbrellas


func _ready() -> void:
	layer = 20
	_build_ui()
	hide_shop()


func bind_systems(wallet: Node, cosmetics: Node) -> void:
	_wallet = wallet
	_cosmetics = cosmetics
	if _wallet:
		_wallet.coins_changed.connect(func(_c: int, _d: int): _update_coins_display())
	if _cosmetics:
		_cosmetics.cosmetic_unlocked.connect(func(_id: String): _refresh_items())
		_cosmetics.cosmetic_equipped.connect(func(_id: String, _t: int): _refresh_items())


func show_shop() -> void:
	_bg.visible = true
	_container.visible = true
	_current_tab = 0
	_refresh_items()
	_update_coins_display()


func hide_shop() -> void:
	_bg.visible = false
	_container.visible = false


func _build_ui() -> void:
	_bg = ColorRect.new()
	_bg.color = Color(0.05, 0.08, 0.15, 0.95)
	_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_bg)

	_container = VBoxContainer.new()
	_container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_container.add_theme_constant_override("separation", 10)
	add_child(_container)

	# Header
	var header := HBoxContainer.new()
	header.custom_minimum_size = Vector2(0, 60)
	header.add_theme_constant_override("separation", 20)
	_container.add_child(header)

	var title := Label.new()
	title.text = "SHOP"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	_coins_label = Label.new()
	_coins_label.add_theme_font_size_override("font_size", 24)
	_coins_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.9))
	header.add_child(_coins_label)

	# Tabs
	var tab_row := HBoxContainer.new()
	tab_row.add_theme_constant_override("separation", 8)
	_container.add_child(tab_row)

	_tab_characters = Button.new()
	_tab_characters.text = "Characters"
	_tab_characters.add_theme_font_size_override("font_size", 20)
	_tab_characters.pressed.connect(func(): _current_tab = 0; _refresh_items())
	tab_row.add_child(_tab_characters)

	_tab_umbrellas = Button.new()
	_tab_umbrellas.text = "Umbrellas"
	_tab_umbrellas.add_theme_font_size_override("font_size", 20)
	_tab_umbrellas.pressed.connect(func(): _current_tab = 1; _refresh_items())
	tab_row.add_child(_tab_umbrellas)

	# Scrollable items list
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_container.add_child(scroll)

	_items_container = VBoxContainer.new()
	_items_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_items_container.add_theme_constant_override("separation", 8)
	scroll.add_child(_items_container)

	# Back button
	_back_button = Button.new()
	_back_button.text = "BACK"
	_back_button.custom_minimum_size = Vector2(0, 50)
	_back_button.add_theme_font_size_override("font_size", 24)
	_back_button.pressed.connect(func(): back_pressed.emit())
	_container.add_child(_back_button)


func _refresh_items() -> void:
	if not _cosmetics:
		return

	# Clear existing items
	for child in _items_container.get_children():
		child.queue_free()

	var type: int = _current_tab  # 0=CHARACTER, 1=UMBRELLA
	var items: Array[Dictionary] = _cosmetics.get_by_type(type)
	var equipped: Dictionary = _cosmetics.get_equipped(type)
	var equipped_id: String = equipped.get("id", "") if not equipped.is_empty() else ""

	for item in items:
		var row := _create_item_row(item, item["id"] == equipped_id)
		_items_container.add_child(row)


func _create_item_row(item: Dictionary, is_equipped: bool) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 60)
	row.add_theme_constant_override("separation", 12)

	# Color swatch
	var swatch := ColorRect.new()
	swatch.color = item["color"]
	swatch.custom_minimum_size = Vector2(40, 40)
	row.add_child(swatch)

	# Name
	var name_label := Label.new()
	name_label.text = item["name"]
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	# Action button
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(120, 40)
	btn.add_theme_font_size_override("font_size", 18)

	if is_equipped:
		btn.text = "EQUIPPED"
		btn.disabled = true
	elif item["unlocked"]:
		btn.text = "EQUIP"
		var item_id: String = item["id"]
		btn.pressed.connect(func(): _on_equip(item_id))
	else:
		btn.text = "%d" % item["cost"]
		var item_id: String = item["id"]
		var cost: int = item["cost"]
		btn.pressed.connect(func(): _on_buy(item_id, cost))
		if _wallet and not _wallet.can_afford(item["cost"]):
			btn.disabled = true

	row.add_child(btn)
	return row


func _on_buy(cosmetic_id: String, cost: int) -> void:
	if not _wallet or not _cosmetics:
		return
	if _wallet.spend_coins(cost):
		_cosmetics.unlock(cosmetic_id)
		_cosmetics.equip(cosmetic_id)
		_refresh_items()


func _on_equip(cosmetic_id: String) -> void:
	if not _cosmetics:
		return
	_cosmetics.equip(cosmetic_id)
	_refresh_items()


func _update_coins_display() -> void:
	if _coins_label and _wallet:
		_coins_label.text = "%d coins" % _wallet.coins
