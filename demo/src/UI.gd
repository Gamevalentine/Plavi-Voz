extends Control

var player: Node3D
var terrain: Node3D

@onready var objective_header: Label = $MissionPanel/VBox/Header
@onready var mission_label: Label = %MissionLabel
@onready var flashlight_label: Label = %FlashlightLabel
@onready var interaction_prompt: PanelContainer = %InteractionPrompt
@onready var interaction_label: Label = %InteractionLabel
@onready var pause_overlay: Control = %PauseOverlay
@onready var load_checkpoint_button: Button = %LoadCheckpoint

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game_ui")
	visible = true
	GameState.mission_state_changed.connect(_refresh_mission)
	CheckpointManager.checkpoint_saved.connect(_refresh_pause_buttons)
	CheckpointManager.checkpoint_cleared.connect(_refresh_pause_buttons)
	_refresh_mission()
	_refresh_pause_buttons()

func _process(_delta: float) -> void:
	if player == null:
		return
	var power = player.get("flashlight_power")
	if power != null:
		flashlight_label.text = "FLASHLIGHT  %d%%" % int(round(float(power)))

func _refresh_mission() -> void:
	var mission := MissionManager.get_current_mission()
	var title := str(mission.get("title", ""))
	var step := int(mission.get("step", 0))
	var total := int(mission.get("total", 0))
	objective_header.text = "CHAPTER 1  •  OBJECTIVE %d/%d" % [step, total] if step > 0 else "CHAPTER 1  •  COMPLETE"
	mission_label.text = title if not title.is_empty() else "The Last Signal"

func _refresh_pause_buttons() -> void:
	load_checkpoint_button.disabled = not CheckpointManager.has_checkpoint()

func show_interaction_prompt(text: String) -> void:
	interaction_label.text = text
	interaction_prompt.visible = not text.is_empty()

func hide_interaction_prompt() -> void:
	interaction_prompt.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo:
		return

	match event.keycode:
		KEY_F11:
			toggle_fullscreen()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			if player != null and not bool(player.get("can_move")) and not get_tree().paused:
				return
			toggle_pause()
			get_viewport().set_input_as_handled()

func toggle_pause() -> void:
	var paused := not get_tree().paused
	get_tree().paused = paused
	pause_overlay.visible = paused
	if paused:
		hide_interaction_prompt()
	_refresh_pause_buttons()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED)

func toggle_fullscreen() -> void:
	if DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN, DisplayServer.WINDOW_MODE_FULLSCREEN]:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)

func _on_resume_pressed() -> void:
	if get_tree().paused:
		toggle_pause()

func _on_checkpoint_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.continue_from_checkpoint()

func _on_restart_pressed() -> void:
	get_tree().paused = false
	CheckpointManager.start_new_game()

func _on_quit_pressed() -> void:
	get_tree().paused = false
	get_tree().quit()
