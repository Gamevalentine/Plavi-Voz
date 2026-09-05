extends Node

const MAX_INTERACTION_DISTANCE_SQ := 36.0

var _candidates: Dictionary = {}
var _active: Node3D

func register_interactable(area: Node3D, prompt_text: String) -> void:
	if not is_instance_valid(area):
		return
	_candidates[area] = prompt_text
	_refresh_active()

func unregister_interactable(area: Node3D) -> void:
	_candidates.erase(area)
	if _active == area:
		_active = null
	_refresh_active()

func _process(_delta: float) -> void:
	if not _candidates.is_empty():
		_refresh_active()

func _unhandled_key_input(event: InputEvent) -> void:
	if not (event is InputEventKey) or not event.pressed or event.echo or event.keycode != KEY_E:
		return
	if get_tree().paused:
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null or not bool(player.get("can_move")):
		return

	_refresh_active()
	if _active == null or not is_instance_valid(_active) or not _active.has_method("interact"):
		return

	var target := _active
	unregister_interactable(target)
	target.call("interact", player)
	get_viewport().set_input_as_handled()

func _refresh_active() -> void:
	var ui := get_tree().get_first_node_in_group("game_ui")
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if ui == null or player == null or get_tree().paused or not bool(player.get("can_move")):
		_active = null
		if ui != null:
			ui.call("hide_interaction_prompt")
		return

	var nearest: Node3D
	var nearest_distance := INF
	var stale: Array = []

	for candidate in _candidates.keys():
		if not is_instance_valid(candidate):
			stale.append(candidate)
			continue
		if candidate.has_method("is_interaction_available") and not bool(candidate.call("is_interaction_available")):
			continue
		var distance := player.global_position.distance_squared_to(candidate.global_position)
		if distance > MAX_INTERACTION_DISTANCE_SQ:
			continue
		if distance < nearest_distance:
			nearest = candidate
			nearest_distance = distance

	for candidate in stale:
		_candidates.erase(candidate)

	_active = nearest
	if _active == null:
		ui.call("hide_interaction_prompt")
	else:
		ui.call("show_interaction_prompt", "[E] %s" % str(_candidates.get(_active, "Interact")))
