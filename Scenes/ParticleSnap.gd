extends GPUParticles2D

@export var player_path: NodePath
@onready var player := get_node(player_path) as Node2D

func _process(_delta: float) -> void:
	if player == null:
		return

	# Follow player, but spawn from integer pixel coords
	global_position = player.global_position.round()
