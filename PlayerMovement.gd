extends CharacterBody2D

@export var speed := 120.0

func _physics_process(_delta):
	var dir := Vector2(
		Input.get_action_strength("player_right") - Input.get_action_strength("player_left"),
		Input.get_action_strength("player_down") - Input.get_action_strength("player_up")
	)

	if dir != Vector2.ZERO:
		dir = dir.normalized()

	velocity = dir * speed
	move_and_slide()

	# Pixel snap for clean rendering
	global_position = global_position.round()
