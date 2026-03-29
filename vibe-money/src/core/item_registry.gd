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


## Explicit item paths — DirAccess fails in web exports (.pck).
const ITEM_PATHS: Array[String] = [
	"res://assets/data/items/coin_bronze.tres",
	"res://assets/data/items/coin_silver.tres",
	"res://assets/data/items/coin_gold.tres",
	"res://assets/data/items/coin_emerald.tres",
	"res://assets/data/items/coin_diamond.tres",
	"res://assets/data/items/hazard_bomb.tres",
	"res://assets/data/items/hazard_poop.tres",
	"res://assets/data/items/hazard_spike.tres",
	"res://assets/data/items/hazard_lightning.tres",
	"res://assets/data/items/hazard_trash.tres",
	"res://assets/data/items/hazard_ice.tres",
]


func _load_all_items() -> void:
	for path in ITEM_PATHS:
		var item := load(path)
		if item:
			if _items.has(item.id):
				push_error("[ItemRegistry] Duplicate item ID: %s in %s" % [item.id, path])
			else:
				_items[item.id] = item
		else:
			push_error("[ItemRegistry] Failed to load item: %s" % path)
