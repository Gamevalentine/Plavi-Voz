extends CanvasLayer

@onready var continue_button: Button = %Continue

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	continue_button.disabled = not CheckpointManager.has_checkpoint()

func _on_continue_pressed() -> void:
	if not CheckpointManager.continue_from_checkpoint():
		continue_button.disabled = true

func _on_restart_pressed() -> void:
	CheckpointManager.start_new_game()

func _on_quit_pressed() -> void:
	get_tree().quit()
