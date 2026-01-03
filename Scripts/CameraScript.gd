extends Camera2D

@export var target_path: NodePath
@export var lock_x := 160.0

@export var screen_height := 192.0
@export var intro_screen_top_y := 0.0

# Pull feel
@export var pull_duration := 0.30

@onready var target := get_node_or_null(target_path) as Node2D

var frozen := true
var _pulling := false
var _pull_time := 0.0
var _pull_start_y := 0.0
var _pull_end_y := 0.0

func _ready() -> void:
	top_level = true
	position_smoothing_enabled = false

	# Start locked to intro screen center (pixel-safe)
	global_position.x = lock_x
	global_position.y = round(intro_screen_top_y + screen_height * 0.5)

func _process(delta: float) -> void:
	if target == null:
		return

	# Lock X always
	global_position.x = lock_x

	# Pull animation
	if _pulling:
		_update_pull(delta)
		return

	# Intro/menu lock
	if frozen:
		return

	# -------------------------
	# GAMEPLAY FOLLOW (UP + DOWN) WITH CEILING CLAMP
	# -------------------------
	var half_screen: float = screen_height * 0.5

	# Ceiling clamp: never show anything above the intro screen's bottom.
	var intro_bottom_y: float = intro_screen_top_y + screen_height
	var min_center_y: float = intro_bottom_y + half_screen

	# Center on player (pixel-safe)
	var desired_center_y: float = round(target.global_position.y)

	# Clamp so we can follow up, but not past the ceiling
	global_position.y = max(desired_center_y, round(min_center_y))

func snap_to_gameplay_and_unfreeze() -> void:
	if _pulling or not frozen:
		return

	_pulling = true
	_pull_time = 0.0

	_pull_start_y = round(global_position.y)
	_pull_end_y = round(_pull_start_y + screen_height)

func _update_pull(delta: float) -> void:
	_pull_time += delta

	var t: float = _pull_time / max(pull_duration, 0.001)
	if t >= 1.0:
		t = 1.0

	# Strong quick pull (ease-out quad)
	var eased: float = 1.0 - pow(1.0 - t, 2.0)

	var y: float = lerp(_pull_start_y, _pull_end_y, eased)
	global_position.y = round(y)

	if t >= 1.0:
		_pulling = false
		frozen = false
