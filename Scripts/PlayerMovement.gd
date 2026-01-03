extends CharacterBody2D

@export var max_speed := 140.0
@export var drag := 650.0
@export var turn := 800.0

# DASH SETTINGS
@export var dash_speed := 320.0
@export var dash_duration := 0.12
@export var dash_cooldown := 0.35
@export var dash_brake := 2200.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var dash_burst: GPUParticles2D = $DashBurst

var _is_dashing := false
var _dash_time_left := 0.0
var _cooldown_left := 0.0
var _dash_dir := Vector2.RIGHT
var _last_move_dir := Vector2.RIGHT

func _ready() -> void:
	sprite.play("fly")
	# Safety: ensure burst is off until used
	dash_burst.emitting = false

func _physics_process(delta: float) -> void:
	var input := Input.get_vector("player_left", "player_right", "player_up", "player_down")

	# Track last movement direction (used if player dashes with no input)
	if input != Vector2.ZERO:
		_last_move_dir = input.normalized()

	# Cooldown timer
	if _cooldown_left > 0.0:
		_cooldown_left = maxf(0.0, _cooldown_left - delta)

	# Start dash
	if Input.is_action_just_pressed("dash") and not _is_dashing and _cooldown_left <= 0.0:
		_is_dashing = true
		_dash_time_left = dash_duration
		_dash_dir = input.normalized() if input != Vector2.ZERO else _last_move_dir

		# Trigger burst EXACTLY where the player is right now (and keep it behind)
		_trigger_dash_burst()

		# Apply dash velocity
		velocity = _dash_dir * dash_speed

	# Dash timer
	if _is_dashing:
		_dash_time_left -= delta
		if _dash_time_left <= 0.0:
			_is_dashing = false
			_cooldown_left = dash_cooldown

	# Normal movement when not dashing
	if not _is_dashing:
		var desired := input * max_speed

		if input != Vector2.ZERO:
			velocity = velocity.move_toward(desired, turn * delta)
		else:
			velocity = velocity.move_toward(Vector2.ZERO, drag * delta)

		# Bleed off any extra speed after dash
		if velocity.length() > max_speed:
			velocity = velocity.move_toward(velocity.normalized() * max_speed, dash_brake * delta)

	# Sprite flip
	if abs(velocity.x) > 1.0:
		sprite.flip_h = velocity.x > 0.0

	move_and_slide()

func _trigger_dash_burst() -> void:
	# Put the burst in WORLD space so it stays behind:
	# Reparent to the current scene temporarily (or just set global_position with local_coords OFF)
	# Easiest: with Local Coords OFF, setting global_position is enough.
	dash_burst.global_position = global_position.round()

	# If you want it slightly behind the dash direction:
	# dash_burst.global_position = (global_position - _dash_dir * 6.0).round()

	# Restart the one-shot emission cleanly
	dash_burst.emitting = false
	dash_burst.restart()
	dash_burst.emitting = true
