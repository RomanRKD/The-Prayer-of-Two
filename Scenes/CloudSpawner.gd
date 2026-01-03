extends Node2D

# -------------------------------------------------------------------
# CONFIG
# -------------------------------------------------------------------

# Fixed world width (vertical-only game)
@export var viewport_width := 320.0

# Cloud actor scene (Sprite2D root with CloudSpriteCode.gd)
@export var cloud_scene: PackedScene

# Textures + rarity weights (same length)
@export var cloud_textures: Array[Texture2D] = []
@export var cloud_weights: Array[float] = []

# Number of clouds
@export var cloud_count := 6

# WORLD Y band (absolute world coordinates)
# Smaller Y = higher on screen
@export var y_top := 15.0
@export var y_bottom := 55.0

# Horizontal speed (px/sec)
@export var speed_min := 4.0
@export var speed_max := 10.0

# Subtle vertical bob (pixel-safe)
@export var bob_amp_min := 0.3
@export var bob_amp_max := 1.2
@export var bob_freq_min := 0.05
@export var bob_freq_max := 0.14

# Offscreen margins
@export var spawn_margin_left := 60.0
@export var kill_margin_right := 80.0

# Minimum horizontal spacing between clouds
@export var min_spacing_x := 70.0

@onready var clouds_root := $"Clouds"

var total_weight := 0.0

# -------------------------------------------------------------------
# LIFECYCLE
# -------------------------------------------------------------------

func _ready() -> void:
	_compute_weights()
	_spawn_initial()

func _process(_delta: float) -> void:
	var left_edge  = global_position.x
	var right_edge = global_position.x + viewport_width
	var kill_x = right_edge + kill_margin_right

	for c in clouds_root.get_children():
		if c.global_position.x > kill_x:
			_wrap_to_left(c, left_edge)

# -------------------------------------------------------------------
# INITIAL SPAWN (VERTICAL SPREAD)
# -------------------------------------------------------------------

func _spawn_initial() -> void:
	var left_edge = global_position.x
	var right_edge = global_position.x + viewport_width

	# ---- X positions (even + jitter) ----
	var xs: Array[float] = []
	var step_x = viewport_width / float(max(1, cloud_count))

	for i in cloud_count:
		var x = left_edge + (i + 0.5) * step_x + randf_range(-step_x * 0.35, step_x * 0.35)
		xs.append(clamp(x, left_edge + 4.0, right_edge - 4.0))

	# Enforce spacing
	xs.sort()
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < min_spacing_x:
			xs[i] = xs[i - 1] + min_spacing_x

	# ---- Y positions (KEY: evenly distributed + jitter) ----
	var ys = _generate_spread_y_positions(cloud_count)

	# Spawn clouds
	for i in cloud_count:
		var c: Node = cloud_scene.instantiate()
		clouds_root.add_child(c)
		_apply_params(c, xs[i], ys[i])

# -------------------------------------------------------------------
# RECYCLE
# -------------------------------------------------------------------

func _wrap_to_left(c: Node, left_edge: float) -> void:
	var x = left_edge - spawn_margin_left - randf_range(0.0, min_spacing_x)
	_apply_params(c, x)

# -------------------------------------------------------------------
# PARAM ASSIGNMENT
# -------------------------------------------------------------------

func _apply_params(c: Node, x: float, y_override: float = NAN) -> void:
	if cloud_textures.is_empty():
		return

	var tex = _pick_weighted_texture()

	var y: float
	if is_nan(y_override):
		var y_low = min(y_top, y_bottom)
		var y_high = max(y_top, y_bottom)
		y = randf_range(y_low, y_high)
	else:
		y = y_override

	var speed = randf_range(speed_min, speed_max)
	var bob_amp = randf_range(bob_amp_min, bob_amp_max)
	var bob_freq = randf_range(bob_freq_min, bob_freq_max)
	var phase = randf() * TAU

	# Last parameter kept for compatibility; scale is forced to 1 in sprite
	c.call("setup", tex, Vector2(x, y), speed, bob_amp, bob_freq, phase, 1.0)

# -------------------------------------------------------------------
# HELPERS
# -------------------------------------------------------------------

func _generate_spread_y_positions(count: int) -> Array[float]:
	var ys: Array[float] = []

	var y_low = min(y_top, y_bottom)
	var y_high = max(y_top, y_bottom)
	var band = max(1.0, y_high - y_low)

	var step = band / float(max(1, count))
	for i in count:
		var base = y_low + (i + 0.5) * step
		var jitter = randf_range(-step * 0.35, step * 0.35)
		ys.append(clamp(base + jitter, y_low, y_high))

	ys.shuffle()
	return ys

func _compute_weights() -> void:
	total_weight = 0.0
	if cloud_weights.size() != cloud_textures.size():
		push_error("CloudSpawner: cloud_weights must match cloud_textures length.")
		return
	for w in cloud_weights:
		total_weight += max(w, 0.0)

func _pick_weighted_texture() -> Texture2D:
	if total_weight <= 0.0:
		return cloud_textures[randi() % cloud_textures.size()]

	var r = randf() * total_weight
	var acc = 0.0
	for i in cloud_textures.size():
		acc += max(cloud_weights[i], 0.0)
		if r <= acc:
			return cloud_textures[i]
	return cloud_textures.back()
