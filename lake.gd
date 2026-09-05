extends Area3D

@onready var dialogue = preload("res://dialogues/lake.dialogue")
@onready var player = $"../../../Player"

var done := false

func _ready() -> void:
	done = bool(GameState.get_flag("lake_seen", false))

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or done or not MissionManager.is_current("reach_lake"):
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
	GameState.set_flag("lake_seen", true)
	MissionManager.complete_mission("reach_lake")
	CheckpointManager.save_checkpoint(player)
