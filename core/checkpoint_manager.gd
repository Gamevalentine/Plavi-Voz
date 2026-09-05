extends Node

signal progress_saved
signal checkpoint_saved
signal checkpoint_loaded
signal checkpoint_cleared

const SAVE_PATH := "user://checkpoint.json"
const SAVE_VERSION := 1
const MAIN_SCENE := "res://main.tscn"

var _save_data: Dictionary = {}
var _restore_pending := false

func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	_load_file()

func save_progress() -> bool:
	if _save_data.is_empty():
		_save_data = {"version": SAVE_VERSION}
	_save_data["state"] = GameState.to_dict()
	var saved := _write_file()
	if saved:
		progress_saved.emit()
	return saved

func save_checkpoint(player: Node3D = null) -> bool:
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return false

	_save_data = {
		"version": SAVE_VERSION,
		"state": GameState.to_dict(),
		"checkpoint_position": [player.global_position.x, player.global_position.y, player.global_position.z],
		"player": {
			"flashlight_power": player.get("flashlight_power"),
			"has_map": player.get("has_map")
		}
	}
	var saved := _write_file()
	if saved:
		checkpoint_saved.emit()
	return saved

func has_checkpoint() -> bool:
	return _save_data.has("checkpoint_position")

func continue_from_checkpoint() -> bool:
	if not has_checkpoint():
		return false

	var state = _save_data.get("state", {})
	if state is Dictionary:
		GameState.load_dict(state)
		MissionManager.reset_story()
	_restore_pending = true
	get_tree().paused = false
	var error := get_tree().change_scene_to_file(MAIN_SCENE)
	if error != OK:
		_restore_pending = false
		return false
	return true

func start_new_game() -> void:
	clear_checkpoint()
	MissionManager.reset_story()
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)

func clear_checkpoint() -> void:
	_save_data.clear()
	_restore_pending = false
	GameState.reset()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	checkpoint_cleared.emit()

func _load_file() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	_save_data = parsed
	if _save_data.get("version", 0) != SAVE_VERSION:
		_save_data.clear()
		return
	var state = _save_data.get("state", {})
	if state is Dictionary:
		GameState.load_dict(state)
		MissionManager.reset_story()
	_restore_pending = has_checkpoint()
	if _restore_pending:
		call_deferred("_try_restore_player")

func _write_file() -> bool:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(_save_data))
	return true

func _on_node_added(node: Node) -> void:
	if _restore_pending and node is CharacterBody3D:
		call_deferred("_try_restore_player")

func _try_restore_player() -> void:
	if not _restore_pending:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return

	player.set("has_map", bool(GameState.get_flag("has_map", player.get("has_map"))))
	var player_data = _save_data.get("player", {})
	if player_data is Dictionary and player_data.has("flashlight_power"):
		player.set("flashlight_power", float(player_data["flashlight_power"]))

	var position_data = _save_data.get("checkpoint_position", [])
	if position_data is Array and position_data.size() == 3:
		player.global_position = Vector3(float(position_data[0]), float(position_data[1]), float(position_data[2]))

	_restore_pending = false
	checkpoint_loaded.emit()
