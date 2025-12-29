extends Camera2D

@export var target_path: NodePath
@export var lock_x := 160.0   # <-- horizontal offset

@onready var target := get_node_or_null(target_path) as Node2D

func _process(_delta):
	if target == null:
		return

	# Lock horizontal position with offset
	global_position.x = lock_x

	# Follow vertically
	global_position.y = round(target.global_position.y)
