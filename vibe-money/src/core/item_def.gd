## Data definition for a single item type (coin or hazard).
## Saved as .tres resources in assets/data/items/.
## See design/gdd/item-database.md for full schema documentation.
class_name ItemDef
extends Resource

enum Category { COIN, HAZARD }

@export var id: StringName = &""
@export var display_name: String = ""
@export var category: Category = Category.COIN
@export var point_value: int = 0
@export var currency_value: int = 0
@export var rarity_weight: float = 1.0
@export var fall_speed_modifier: float = 1.0
@export var hitbox_radius: float = 16.0
@export var visual_scale: float = 1.0
@export var feedback_tag: StringName = &""
@export var damage: int = 0
