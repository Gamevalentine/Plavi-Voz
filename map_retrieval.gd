extends Area3D

@onready var dialogue = preload("res://dialogues/map.dialogue")
@onready var player = $"../../../Player"

var done := false

func _ready() -> void:
	done = bool(GameState.get_flag("has_map", false))
	if done:
		player.has_map = true
		call_deferred("queue_free")
		return
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or done:
		return
	InteractionManager.register_interactable(self, "Pick up map")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		InteractionManager.unregister_interactable(self)

func is_interaction_available() -> bool:
	return not done and MissionManager.is_current("find_map")

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
	player.has_map = true
	GameState.set_flag("has_map", true)
	MissionManager.complete_mission("find_map")
	CheckpointManager.save_checkpoint(player)
	call_deferred("queue_free")
