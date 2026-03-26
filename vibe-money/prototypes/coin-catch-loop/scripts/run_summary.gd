# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends CanvasLayer

@onready var panel: PanelContainer = $Panel
@onready var score_value: Label = $Panel/VBox/ScoreRow/Value
@onready var streak_value: Label = $Panel/VBox/StreakRow/Value
@onready var coins_value: Label = $Panel/VBox/CoinsRow/Value
@onready var time_value: Label = $Panel/VBox/TimeRow/Value
@onready var retry_button: Button = $Panel/VBox/RetryButton
@onready var title_label: Label = $Panel/VBox/Title


func _ready() -> void:
	GameManager.run_ended.connect(_on_run_ended)
	retry_button.pressed.connect(_on_retry)
	panel.visible = false


func _on_run_ended(stats: Dictionary) -> void:
	panel.visible = true

	# Animate in
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT)

	# Fill stats
	score_value.text = str(stats.score)
	streak_value.text = str(stats.best_streak)
	coins_value.text = str(stats.total_coins)

	var minutes := int(stats.run_time) / 60
	var seconds := int(stats.run_time) % 60
	time_value.text = "%d:%02d" % [minutes, seconds]

	# Title based on performance
	if stats.score >= 500:
		title_label.text = "Amazing Run!"
	elif stats.score >= 200:
		title_label.text = "Great Run!"
	elif stats.score >= 50:
		title_label.text = "Good Try!"
	else:
		title_label.text = "Run Over"

	retry_button.grab_focus()


func _on_retry() -> void:
	panel.visible = false
	GameManager.start_run()
