extends CharacterBody2D

@export var max_speed := 140.0
@export var accel := 900.0
@export var drag := 650.0
@export var turn := 800.0

@onready var sprite: AnimatedSprite2D = $Sprite

func _ready() -> void:
	sprite.play("fly")

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("player_left", "player_right", "player_up", "player_down")
	var desired := input * max_speed

	if input != Vector2.ZERO:
		velocity = velocity.move_toward(desired, turn * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

	# FLIP FIXED: sprite now faces the correct direction
	if abs(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0

	move_and_slide()
