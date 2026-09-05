extends Node

signal mission_started(mission_id: String, title: String)
signal mission_completed(mission_id: String)
signal mission_cleared

func _ready() -> void:
	if GameState.current_mission_id.is_empty() and not GameState.is_mission_completed("reach_tree"):
		start_mission("reach_tree", "Reach the tree")

func start_mission(mission_id: String, title: String = "") -> void:
	if mission_id.is_empty() or GameState.is_mission_completed(mission_id):
		return
	GameState.set_current_mission(mission_id, title)
	mission_started.emit(mission_id, title)

func complete_mission(mission_id: String = "") -> void:
	var target_id := mission_id if not mission_id.is_empty() else GameState.current_mission_id
	if target_id.is_empty() or GameState.is_mission_completed(target_id):
		return
	GameState.complete_mission(target_id)
	mission_completed.emit(target_id)
	if GameState.current_mission_id.is_empty():
		mission_cleared.emit()

func is_completed(mission_id: String) -> bool:
	return GameState.is_mission_completed(mission_id)

func get_current_mission() -> Dictionary:
	return {
		"id": GameState.current_mission_id,
		"title": GameState.current_mission_title
	}
