extends Area3D

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().change_scene_to_file("res://scenes/game_over.tscn")
