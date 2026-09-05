extends Area3D

@onready var dialogue = preload("res://dialogues/radio.dialogue")
@onready var player = $"../../Player"

var repaired := false

func _ready() -> void:
	repaired = bool(GameState.get_flag("radio_repaired", false))
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or repaired:
		return
	InteractionManager.register_interactable(self, "Repair radio")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_interactable(self)

func is_interaction_available() -> bool:
	return not repaired

func interact(body: Node3D) -> void:
	if body != player or repaired:
		return
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
	repaired = true
	GameState.set_flag("radio_repaired", true)
	MissionManager.complete_mission("repair_radio")
	CheckpointManager.save_checkpoint(player)
	player.can_move = true
