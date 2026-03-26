## Loads all ItemDef resources at startup and provides lookup.
## See design/gdd/item-database.md for schema and roster.
extends Node

const ITEMS_PATH := "res://assets/data/items/"

var _items: Dictionary = {}  # StringName -> Resource (ItemDef)


func _ready() -> void:
	_load_all_items()
	print("[ItemRegistry] Loaded %d items" % _items.size())


func get_item(id: StringName) -> Resource:
	if not _items.has(id):
		push_warning("[ItemRegistry] Unknown item ID: %s" % id)
		return null
	return _items[id]


func get_items_by_category(category: int) -> Array:
	var result: Array = []
	for item in _items.values():
		if item.category == category:
			result.append(item)
	return result


func get_spawn_table() -> Array:
	var result: Array = []
	for item in _items.values():
		if item.rarity_weight > 0.0:
			result.append(item)
	return result


func _load_all_items() -> void:
	var dir := DirAccess.open(ITEMS_PATH)
	if not dir:
		push_error("[ItemRegistry] Cannot open items directory: %s" % ITEMS_PATH)
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var item := load(ITEMS_PATH + file_name)
			if item:
				if _items.has(item.id):
					push_error("[ItemRegistry] Duplicate item ID: %s in %s" % [item.id, file_name])
				else:
					_items[item.id] = item
		file_name = dir.get_next()
	dir.list_dir_end()
