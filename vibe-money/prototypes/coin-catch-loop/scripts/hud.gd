# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends CanvasLayer

@onready var score_label: Label = $ScoreLabel
@onready var streak_label: Label = $StreakLabel
@onready var lives_container: HBoxContainer = $LivesContainer
@onready var multiplier_label: Label = $MultiplierLabel
@onready var combo_popup: Label = $ComboPopup


func _ready() -> void:
	GameManager.score_changed.connect(_on_score_changed)
	GameManager.streak_changed.connect(_on_streak_changed)
	GameManager.lives_changed.connect(_on_lives_changed)
	GameManager.coin_collected.connect(_on_coin_collected)
	GameManager.hazard_hit.connect(_on_hazard_hit)
	combo_popup.modulate.a = 0.0


func _on_score_changed(score: int) -> void:
	score_label.text = str(score)
	# Punch scale on score change
	var tween := create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.3, 1.3), 0.05)
	tween.tween_property(score_label, "scale", Vector2.ONE, 0.15)


func _on_streak_changed(streak: int) -> void:
	if streak == 0:
		streak_label.text = ""
		multiplier_label.text = ""
		return

	streak_label.text = "x" + str(streak)

	var mult := GameManager.get_streak_multiplier_display()
	if mult > 1.0:
		multiplier_label.text = "%.1fx" % mult
		multiplier_label.modulate = Color(1.0, 0.9, 0.3) if mult >= 3.0 else Color(0.8, 0.9, 1.0)
	else:
		multiplier_label.text = ""

	# Streak milestone popups
	if streak in [5, 10, 20, 50, 100]:
		_show_combo_popup(streak)


func _on_lives_changed(lives: int) -> void:
	# Update heart display
	for i in range(lives_container.get_child_count()):
		var heart: Label = lives_container.get_child(i)
		heart.modulate.a = 1.0 if i < lives else 0.2


func _on_coin_collected(_coin_data: Dictionary) -> void:
	pass  # Could add per-coin popup here


func _on_hazard_hit(_hazard_type: String) -> void:
	# Flash screen red briefly
	var flash := ColorRect.new()
	flash.color = Color(1.0, 0.0, 0.0, 0.15)
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(flash)
	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.0, 0.3)
	tween.tween_callback(flash.queue_free)


func _show_combo_popup(streak: int) -> void:
	combo_popup.text = "STREAK x%d!" % streak
	combo_popup.modulate.a = 1.0
	combo_popup.scale = Vector2(0.5, 0.5)
	var tween := create_tween()
	tween.tween_property(combo_popup, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_popup, "scale", Vector2.ONE, 0.1)
	tween.tween_interval(0.8)
	tween.tween_property(combo_popup, "modulate:a", 0.0, 0.3)
