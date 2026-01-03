extends Area2D

@export var trunk_top: CanvasItem
@export var player_path: NodePath

@export var fade_duration := 0.15

var _fade_tween: Tween

func _ready() -> void:
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node) -> void:
	if not _is_player(body):
		return
	_fade_trunk(false)

func _on_body_exited(body: Node) -> void:
	if not _is_player(body):
		return
	_fade_trunk(true)

func _fade_trunk(show: bool) -> void:
	if trunk_top == null:
		return

	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()

	var target_alpha := 1.0 if show else 0.0

	_fade_tween = create_tween()
	_fade_tween.set_trans(Tween.TRANS_QUAD)
	_fade_tween.set_ease(Tween.EASE_OUT)
	_fade_tween.tween_property(trunk_top, "modulate:a", target_alpha, fade_duration)

func _is_player(body: Node) -> bool:
	if player_path != NodePath():
		return body == get_node_or_null(player_path)
	return body.is_in_group("player")
