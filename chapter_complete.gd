extends Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_restart_pressed() -> void:
	CheckpointManager.start_new_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
