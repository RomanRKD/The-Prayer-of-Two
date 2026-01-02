extends Sprite2D

var speed_px_s := 10.0
var bob_amp_px := 1.0
var bob_freq_hz := 0.12
var base_y := 0.0
var phase := 0.0

func setup(tex: Texture2D, start_pos: Vector2, speed: float, bob_amp: float, bob_freq: float, ph: float, s: float) -> void:
	texture = tex
	position = start_pos
	speed_px_s = speed
	bob_amp_px = bob_amp
	bob_freq_hz = bob_freq
	base_y = start_pos.y
	phase = ph
	scale = Vector2.ONE * s

func _process(delta: float) -> void:
	position.x += speed_px_s * delta
	position.y = base_y + sin(Time.get_ticks_msec() * 0.001 * TAU * bob_freq_hz + phase) * bob_amp_px
