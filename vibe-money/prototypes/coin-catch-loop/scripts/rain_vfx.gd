# PROTOTYPE - NOT FOR PRODUCTION
# Question: Is the coin-catching loop fun with rainy-day vibes?
# Date: 2026-03-26

extends CPUParticles2D

# Rain configuration — tuned for cozy lo-fi vibe


func _ready() -> void:
	emitting = true
	amount = 200
	lifetime = 1.2
	one_shot = false
	explosiveness = 0.0
	randomness = 0.3

	# Emit from top of screen, full width
	emission_shape = EMISSION_SHAPE_RECTANGLE
	emission_rect_extents = Vector2(400, 5)

	# Fall direction — slight angle for wind effect
	direction = Vector2(0.15, 1.0)
	spread = 3.0

	# Speed
	initial_velocity_min = 500.0
	initial_velocity_max = 700.0
	gravity = Vector2(20, 200)

	# Visuals — thin rain streaks
	scale_amount_min = 0.5
	scale_amount_max = 1.5

	# Subtle blue-white rain color
	color = Color(0.7, 0.75, 0.9, 0.25)

	# Position at top center of screen
	position = Vector2(360, -20)
