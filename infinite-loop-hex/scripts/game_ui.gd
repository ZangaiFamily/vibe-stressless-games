## UI overlay with level-based difficulty progression and progress tracking.
extends Control

signal new_game_requested(level_config: Dictionary)

@onready var new_game_button: Button = %NewGameButton
@onready var size_selector: OptionButton = %SizeSelector
@onready var win_label: Label = %WinLabel
@onready var progress_label: Label = %ProgressLabel

var _levels: Array[Dictionary] = [
	{"label": "Level 1",  "radius": 1, "extra_chance": 0.0, "min_scramble": 1, "max_scramble": 1},
	{"label": "Level 2",  "radius": 1, "extra_chance": 0.0, "min_scramble": 1, "max_scramble": 2},
	{"label": "Level 3",  "radius": 1, "extra_chance": 0.0, "min_scramble": 1, "max_scramble": 3},
	{"label": "Level 4",  "radius": 2, "extra_chance": 0.0, "min_scramble": 1, "max_scramble": 3},
	{"label": "Level 5",  "radius": 2, "extra_chance": 0.1, "min_scramble": 1, "max_scramble": 4},
	{"label": "Level 6",  "radius": 2, "extra_chance": 0.2, "min_scramble": 2, "max_scramble": 4},
	{"label": "Level 7",  "radius": 3, "extra_chance": 0.2, "min_scramble": 2, "max_scramble": 5},
	{"label": "Level 8",  "radius": 3, "extra_chance": 0.3, "min_scramble": 2, "max_scramble": 5},
	{"label": "Level 9",  "radius": 4, "extra_chance": 0.3, "min_scramble": 1, "max_scramble": 5},
	{"label": "Level 10", "radius": 4, "extra_chance": 0.4, "min_scramble": 1, "max_scramble": 5},
	{"label": "Expert",   "radius": 5, "extra_chance": 0.5, "min_scramble": 1, "max_scramble": 5},
]


func _ready() -> void:
	for i in range(_levels.size()):
		size_selector.add_item(_levels[i]["label"], i)
	size_selector.selected = 0  # Default: Level 1 for new players

	new_game_button.pressed.connect(_on_new_game)
	win_label.visible = false
	progress_label.visible = true


func _on_new_game() -> void:
	var idx: int = size_selector.selected
	new_game_requested.emit(_levels[idx])
	win_label.visible = false


func show_win() -> void:
	win_label.visible = true
	win_label.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(win_label, "modulate:a", 1.0, 0.5)

	# Auto-advance to next level after a short delay
	var idx: int = size_selector.selected
	if idx < _levels.size() - 1:
		var advance_tween: Tween = create_tween()
		advance_tween.tween_interval(1.5)
		advance_tween.tween_callback(_advance_level)


func _advance_level() -> void:
	var idx: int = size_selector.selected
	if idx < _levels.size() - 1:
		size_selector.selected = idx + 1
		_on_new_game()


func update_progress(matched: int, total: int) -> void:
	progress_label.text = "%d / %d" % [matched, total]
