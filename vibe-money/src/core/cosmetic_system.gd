## Manages cosmetic items: unlocking, equipping, and catalog.
## Umbrellas and character skins are the first cosmetic categories.
class_name CosmeticSystem
extends Node

enum CosmeticType { CHARACTER, UMBRELLA }

## Each cosmetic: {id, type, name, cost, color, unlocked}
var _catalog: Array[Dictionary] = []
var _equipped: Dictionary = {}  # CosmeticType -> id

signal cosmetic_unlocked(cosmetic_id: String)
signal cosmetic_equipped(cosmetic_id: String, cosmetic_type: int)


func _ready() -> void:
	_build_catalog()
	# Equip defaults
	_equipped[CosmeticType.CHARACTER] = "char_default"
	_equipped[CosmeticType.UMBRELLA] = "umbrella_blue"


func _build_catalog() -> void:
	_catalog = [
		# Characters
		{"id": "char_default", "type": CosmeticType.CHARACTER, "name": "Classic", "cost": 0, "color": Color(0.3, 0.5, 0.8), "unlocked": true},
		{"id": "char_golden", "type": CosmeticType.CHARACTER, "name": "Golden", "cost": 500, "color": Color(1.0, 0.85, 0.2), "unlocked": false},
		{"id": "char_emerald", "type": CosmeticType.CHARACTER, "name": "Emerald", "cost": 750, "color": Color(0.2, 0.8, 0.4), "unlocked": false},
		{"id": "char_ruby", "type": CosmeticType.CHARACTER, "name": "Ruby", "cost": 1000, "color": Color(0.9, 0.2, 0.3), "unlocked": false},
		{"id": "char_shadow", "type": CosmeticType.CHARACTER, "name": "Shadow", "cost": 2000, "color": Color(0.15, 0.1, 0.2), "unlocked": false},
		# Umbrellas
		{"id": "umbrella_blue", "type": CosmeticType.UMBRELLA, "name": "Blue Sky", "cost": 0, "color": Color(0.3, 0.5, 0.8), "unlocked": true},
		{"id": "umbrella_sunset", "type": CosmeticType.UMBRELLA, "name": "Sunset", "cost": 300, "color": Color(1.0, 0.5, 0.2), "unlocked": false},
		{"id": "umbrella_cherry", "type": CosmeticType.UMBRELLA, "name": "Cherry Blossom", "cost": 600, "color": Color(1.0, 0.6, 0.7), "unlocked": false},
		{"id": "umbrella_neon", "type": CosmeticType.UMBRELLA, "name": "Neon", "cost": 900, "color": Color(0.3, 1.0, 0.8), "unlocked": false},
		{"id": "umbrella_galaxy", "type": CosmeticType.UMBRELLA, "name": "Galaxy", "cost": 1500, "color": Color(0.4, 0.2, 0.8), "unlocked": false},
	]


func get_catalog() -> Array[Dictionary]:
	return _catalog


func get_by_type(type: CosmeticType) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in _catalog:
		if item["type"] == type:
			result.append(item)
	return result


func get_equipped(type: CosmeticType) -> Dictionary:
	var id: String = _equipped.get(type, "")
	for item in _catalog:
		if item["id"] == id:
			return item
	return {}


func get_equipped_color(type: CosmeticType) -> Color:
	var item := get_equipped(type)
	if item.is_empty():
		return Color.WHITE
	return item["color"]


func unlock(cosmetic_id: String) -> bool:
	for item in _catalog:
		if item["id"] == cosmetic_id:
			item["unlocked"] = true
			cosmetic_unlocked.emit(cosmetic_id)
			return true
	return false


func equip(cosmetic_id: String) -> bool:
	for item in _catalog:
		if item["id"] == cosmetic_id and item["unlocked"]:
			_equipped[item["type"]] = cosmetic_id
			cosmetic_equipped.emit(cosmetic_id, item["type"])
			return true
	return false


func is_unlocked(cosmetic_id: String) -> bool:
	for item in _catalog:
		if item["id"] == cosmetic_id:
			return item["unlocked"]
	return false


func to_dict() -> Dictionary:
	var unlocked_ids: Array[String] = []
	for item in _catalog:
		if item["unlocked"]:
			unlocked_ids.append(item["id"])
	return {
		"unlocked": unlocked_ids,
		"equipped": {
			"character": _equipped.get(CosmeticType.CHARACTER, "char_default"),
			"umbrella": _equipped.get(CosmeticType.UMBRELLA, "umbrella_blue"),
		}
	}


func from_dict(data: Dictionary) -> void:
	var unlocked_ids: Array = data.get("unlocked", [])
	for item in _catalog:
		item["unlocked"] = item["id"] in unlocked_ids or item["cost"] == 0
	var equipped_data: Dictionary = data.get("equipped", {})
	_equipped[CosmeticType.CHARACTER] = equipped_data.get("character", "char_default")
	_equipped[CosmeticType.UMBRELLA] = equipped_data.get("umbrella", "umbrella_blue")
