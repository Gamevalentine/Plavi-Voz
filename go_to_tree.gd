extends Area3D

@onready var dialogue = preload("res://dialogues/gotothetree.dialogue")
@onready var player = $"../../../Player"

var done := false

func _ready() -> void:
	done = bool(GameState.get_flag("reached_tree", false))
	if done:
		call_deferred("queue_free")

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or done:
		return
	done = true
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
	GameState.set_flag("reached_tree", true)
	MissionManager.complete_mission("reach_tree")
	CheckpointManager.save_progress()
	call_deferred("queue_free")
