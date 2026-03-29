## Handles save/load of persistent player data.
## Uses Godot's user:// directory for cross-platform saves.
class_name SaveManager
extends Node

const SAVE_PATH := "user://vibe_money_save.json"

var _wallet: Node
var _cosmetics: Node


func bind_systems(wallet: Node, cosmetics: Node) -> void:
	_wallet = wallet
	_cosmetics = cosmetics


func save_game() -> void:
	var data := {
		"version": 1,
		"wallet": _wallet.to_dict() if _wallet else {},
		"cosmetics": _cosmetics.to_dict() if _cosmetics else {},
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var text := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(text) != OK:
		push_warning("[SaveManager] Failed to parse save file")
		return

	var data: Dictionary = json.data
	if _wallet and data.has("wallet"):
		_wallet.from_dict(data["wallet"])
	if _cosmetics and data.has("cosmetics"):
		_cosmetics.from_dict(data["cosmetics"])
