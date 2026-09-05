extends Area3D

@export var one_shot := true
var _saved := false

func _on_body_entered(body: Node3D) -> void:
	if _saved or not body.is_in_group("player"):
		return
	if CheckpointManager.save_checkpoint(body):
		_saved = one_shot
