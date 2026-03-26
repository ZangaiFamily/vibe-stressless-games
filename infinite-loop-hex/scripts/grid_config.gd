## Data-driven configuration for the hex grid game.
## All visual and gameplay tuning values live here.
extends Resource

@export_group("Grid")
@export var grid_radius: int = 3
@export var hex_size: float = 50.0

@export_group("Colors")
@export var bg_color: Color = Color("1a1a2e")
@export var hex_outline_color: Color = Color("263054")
@export var line_color_unsolved: Color = Color("4a4a6a")
@export var line_color_solved: Color = Color("00d2ff")
@export var line_color_won: Color = Color("00ff88")

@export_group("Line Widths")
@export var line_width: float = 4.0
@export var outline_width: float = 1.5
@export var dot_radius: float = 5.0

@export_group("Animation")
@export var rotation_duration: float = 0.15

@export_group("Puzzle")
## Probability of adding extra connections beyond the spanning tree.
@export_range(0.0, 1.0) var extra_connection_chance: float = 0.3
## Minimum number of rotation steps when scrambling tiles.
@export_range(0, 5) var min_scramble_steps: int = 1
## Maximum number of rotation steps when scrambling tiles.
@export_range(1, 5) var max_scramble_steps: int = 5
