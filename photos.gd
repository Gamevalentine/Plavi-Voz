extends Area3D

@onready var dialogue = preload("res://dialogues/photos.dialogue")
@onready var player = $"../../../../Player"

var done := false

func _ready() -> void:
	done = bool(GameState.get_flag("photos_inspected", false))
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or done:
		return
	InteractionManager.register_interactable(self, "Search the photographs")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_interactable(self)

func is_interaction_available() -> bool:
	return not done and MissionManager.is_current("inspect_photos")

func interact(body: Node3D) -> void:
	if body != player or not is_interaction_available():
		return
	done = true
	InteractionManager.unregister_interactable(self)
	_start_dialogue(dialogue, "start")

func _start_dialogue(dialogue_resource: DialogueResource, start_node: String) -> void:
	player.can_move = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_node)
	await DialogueManager.dialogue_ended
	_on_dialogue_ended()

func _on_dialogue_ended() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	player.can_move = true
	GameState.set_flag("photos_inspected", true)
	MissionManager.complete_mission("inspect_photos")
	CheckpointManager.save_progress()
