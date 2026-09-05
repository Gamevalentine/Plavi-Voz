extends Node

signal mission_started(mission_id: String, title: String)
signal mission_completed(mission_id: String)
signal mission_cleared

const STORY_MISSIONS := [
	{"id": "reach_tree", "title": "Reach the tree"},
	{"id": "repair_radio", "title": "Repair the radio"},
	{"id": "find_map", "title": "Find the map"},
	{"id": "follow_route", "title": "Follow the route to the railway"},
	{"id": "reach_train", "title": "Reach the evacuation train"}
]

func _ready() -> void:
	call_deferred("_advance_story")

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
	_advance_story()

func is_completed(mission_id: String) -> bool:
	return GameState.is_mission_completed(mission_id)

func get_current_mission() -> Dictionary:
	return {
		"id": GameState.current_mission_id,
		"title": GameState.current_mission_title
	}

func _advance_story() -> void:
	for mission in STORY_MISSIONS:
		var mission_id := str(mission["id"])
		if GameState.is_mission_completed(mission_id):
			continue
		if GameState.current_mission_id != mission_id:
			start_mission(mission_id, str(mission["title"]))
		return

	if not GameState.current_mission_id.is_empty():
		GameState.set_current_mission("", "")
	mission_cleared.emit()
