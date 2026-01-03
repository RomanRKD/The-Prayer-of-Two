extends PointLight2D

@export var min_energy := 0.8
@export var max_energy := 1.4

# "Size" of the light = texture_scale
@export var min_size := 0.90
@export var max_size := 1.10

@export var pulse_time := 0.08

var _pulse_tween: Tween

func _ready() -> void:
	# If the light is a child of the player, keep it centered
	position = Vector2.ZERO
	start_pulse()

func start_pulse() -> void:
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	_pulse_tween = create_tween()
	_pulse_tween.set_loops()

	# STEP 1: Up (energy up + size up together)
	_pulse_tween.tween_property(self, "energy", max_energy, pulse_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	_pulse_tween.parallel().tween_property(self, "texture_scale", max_size, pulse_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)

	# STEP 2: Down (energy down + size down together)
	_pulse_tween.tween_property(self, "energy", min_energy, pulse_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)

	_pulse_tween.parallel().tween_property(self, "texture_scale", min_size, pulse_time)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_IN)
