extends Area2D

@export var camera: Node

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	print("[NextScreenTrigger] ready. monitoring=", monitoring)

func _on_body_entered(body: Node) -> void:
	print("[NextScreenTrigger] body_entered:", body.name, " type=", body.get_class())

	# No group requirement while debugging
	if camera == null:
		print("[NextScreenTrigger] ERROR: camera not assigned in inspector")
		return

	print("[NextScreenTrigger] camera node =", camera.name, " type=", camera.get_class())

	if camera.has_method("snap_to_gameplay_and_unfreeze"):
		camera.call("snap_to_gameplay_and_unfreeze")
		print("[NextScreenTrigger] SUCCESS: called snap_to_gameplay_and_unfreeze()")
	else:
		print("[NextScreenTrigger] ERROR: camera is missing method snap_to_gameplay_and_unfreeze()")
