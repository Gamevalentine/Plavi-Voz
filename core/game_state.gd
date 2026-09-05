extends Node

signal flag_changed(key: String, value: Variant)
signal mission_state_changed
signal state_reset

var flags: Dictionary = {}
var current_mission_id := ""
var current_mission_title := ""
var completed_missions: Array = []

func set_flag(key: String, value: Variant = true) -> void:
	if flags.get(key) == value:
		return
	flags[key] = value
	flag_changed.emit(key, value)

func get_flag(key: String, default_value: Variant = false) -> Variant:
	return flags.get(key, default_value)

func set_current_mission(mission_id: String, title: String = "") -> void:
	current_mission_id = mission_id
	current_mission_title = title
	mission_state_changed.emit()

func complete_mission(mission_id: String) -> void:
	if mission_id.is_empty() or mission_id in completed_missions:
		return
	completed_missions.append(mission_id)
	if current_mission_id == mission_id:
		current_mission_id = ""
		current_mission_title = ""
	mission_state_changed.emit()

func is_mission_completed(mission_id: String) -> bool:
	return mission_id in completed_missions

func to_dict() -> Dictionary:
	return {
		"flags": flags.duplicate(true),
		"current_mission_id": current_mission_id,
		"current_mission_title": current_mission_title,
		"completed_missions": completed_missions.duplicate()
	}

func load_dict(data: Dictionary) -> void:
	var loaded_flags = data.get("flags", {})
	flags = loaded_flags.duplicate(true) if loaded_flags is Dictionary else {}
	current_mission_id = str(data.get("current_mission_id", ""))
	current_mission_title = str(data.get("current_mission_title", ""))
	var loaded_completed = data.get("completed_missions", [])
	completed_missions = loaded_completed.duplicate() if loaded_completed is Array else []
	mission_state_changed.emit()

func reset() -> void:
	flags.clear()
	current_mission_id = ""
	current_mission_title = ""
	completed_missions.clear()
	state_reset.emit()
	mission_state_changed.emit()
