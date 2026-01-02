extends Node2D

# Fixed world width band for a vertical-only game (your level never wider than 320)
@export var viewport_width := 320.0

# Cloud actor scene (Sprite2D root with your CloudSpriteCode.gd)
@export var cloud_scene: PackedScene

# Textures + rarity weights (same length; higher = more common)
@export var cloud_textures: Array[Texture2D] = []
@export var cloud_weights: Array[float] = []

# How many clouds active in this layer
@export var cloud_count := 6

# WORLD Y band (absolute world coordinates)
# Reminder: in Godot 2D, smaller Y = higher, larger Y = lower.
@export var y_top := 15.0
@export var y_bottom := 55.0

# Speed range (px/sec) - positive moves right
@export var speed_min := 4.0
@export var speed_max := 10.0

# Subtle bob
@export var bob_amp_min := 0.3
@export var bob_amp_max := 1.2
@export var bob_freq_min := 0.05
@export var bob_freq_max := 0.14

# Optional scale variation
@export var scale_min := 0.7
@export var scale_max := 1.05

# Offscreen margins (how far beyond the 320px band)
@export var spawn_margin_left := 60.0
@export var kill_margin_right := 80.0

# Minimum horizontal spacing between clouds (prevents clumps)
@export var min_spacing_x := 70.0

@onready var clouds_root := $"Clouds"

var total_weight := 0.0

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

func _compute_weights() -> void:
	total_weight = 0.0
	if cloud_weights.size() != cloud_textures.size():
		push_error("CloudSpawner: cloud_weights must match cloud_textures length.")
		return
	for w in cloud_weights:
		total_weight += max(w, 0.0)

func _spawn_initial() -> void:
	var left_edge = global_position.x
	var right_edge = global_position.x + viewport_width

	# Evenly distribute across the band with some jitter
	var xs: Array[float] = []
	var step = viewport_width / float(max(1, cloud_count))
	for i in cloud_count:
		var x = left_edge + (i + 0.5) * step + randf_range(-step * 0.35, step * 0.35)
		xs.append(clamp(x, left_edge + 4.0, right_edge - 4.0))

	# Enforce simple spacing
	xs.sort()
	for i in range(1, xs.size()):
		if xs[i] - xs[i - 1] < min_spacing_x:
			xs[i] = xs[i - 1] + min_spacing_x

	for x in xs:
		var c: Node = cloud_scene.instantiate()
		clouds_root.add_child(c)
		_apply_params(c, x)

func _wrap_to_left(c: Node, left_edge: float) -> void:
	# Respawn just offscreen left
	var x = left_edge - spawn_margin_left - randf_range(0.0, min_spacing_x)
	_apply_params(c, x)

func _apply_params(c: Node, x: float) -> void:
	if cloud_textures.is_empty():
		return

	var tex = _pick_weighted_texture()

	# World-anchored vertical band (order-safe even if you swap values)
	var y_low = min(y_top, y_bottom)
	var y_high = max(y_top, y_bottom)
	var y = randf_range(y_low, y_high)

	# Simple coupling: bigger clouds drift a bit faster + bob a bit more
	var s = randf_range(scale_min, scale_max)
	var size_t = inverse_lerp(scale_min, scale_max, s)
	var speed = lerp(speed_min, speed_max, size_t)

	var bob_amp = lerp(bob_amp_min, bob_amp_max, size_t)
	var bob_freq = randf_range(bob_freq_min, bob_freq_max)
	var phase = randf() * TAU

	c.call("setup", tex, Vector2(x, y), speed, bob_amp, bob_freq, phase, s)

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
