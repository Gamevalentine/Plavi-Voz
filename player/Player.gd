extends CharacterBody3D

@export var MOVE_SPEED: float = 5.0
@export var JUMP_SPEED: float = 7.0
@export var headbob_freq := 2
@export var headbob_amp := 0.04
@export var light_shake_enabled: bool = true
@export var light_shake_intensity: float = 0.15
@export var light_shake_freq: float = 3.0
@export var flashlight_power: float = 100.0
@export var power_drain_rate: float = 100.0 / 30.0
@export var blink_interval: float = 0.4
@export var recharge_rate_multiplier: float = 2.0

@onready var dialogue = preload("res://dialogues/flashlight.dialogue")

var headbob_time := 0.0
var foot_sound := true
var foot_land := true
var light_shake_time := 0.0
var light_original_pos: Vector3
var spotlight_node: SpotLight3D
var flashlight_enabled := true
var is_blinking := false
var blink_timer := 0.0
var first_depletion := true
var is_recharging := false
var is_charging_audio_playing := false
var can_move := true
var has_map := false
var map_toggle := false

@export var first_person: bool = true:
	set(p_value):
		first_person = p_value
		if first_person:
			var tween: Tween = create_tween()
			tween.tween_property($CameraManager/Arm, "spring_length", 0.0, 0.33)
			tween.tween_callback($Body.set_visible.bind(false))
		else:
			$Body.visible = true
			create_tween().tween_property($CameraManager/Arm, "spring_length", 6.0, 0.33)

@export var gravity_enabled: bool = true:
	set(p_value):
		gravity_enabled = p_value
		if not gravity_enabled:
			velocity.y = 0.0

@export var collision_enabled: bool = true:
	set(p_value):
		collision_enabled = p_value
		$CollisionShapeBody.disabled = not collision_enabled
		$CollisionShapeRay.disabled = not collision_enabled

func _ready() -> void:
	spotlight_node = get_node_or_null("%SpotLight3D")
	if not spotlight_node:
		spotlight_node = get_node_or_null("SpotLight3D")
	if not spotlight_node:
		spotlight_node = get_node_or_null("CameraManager/SpotLight3D")

	if spotlight_node:
		light_original_pos = spotlight_node.position
		flashlight_enabled = spotlight_node.visible

func _physics_process(p_delta: float) -> void:
	if can_move:
		var direction := get_camera_relative_input()
		var horizontal_velocity := Vector2(direction.x, direction.z).normalized() * MOVE_SPEED
		if Input.is_key_pressed(KEY_SHIFT):
			horizontal_velocity *= 2.0
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.y
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	if gravity_enabled:
		if is_on_floor():
			if can_move and Input.is_key_pressed(KEY_SPACE):
				velocity.y = JUMP_SPEED
			elif velocity.y < 0.0:
				velocity.y = 0.0
		else:
			velocity.y -= 40.0 * p_delta

	move_and_slide()

	headbob_time += p_delta * Vector2(velocity.x, velocity.z).length() * float(is_on_floor())
	%Arm.transform.origin = headbob(headbob_time)

	if can_move:
		update_flashlight_power(p_delta)

	var is_moving := can_move and Vector2(velocity.x, velocity.z).length() > 0.1
	if light_shake_enabled and spotlight_node and flashlight_enabled and (not is_blinking or spotlight_node.visible) and is_moving:
		light_shake_time += p_delta * light_shake_freq
		spotlight_node.position = light_original_pos + light_shake()
	elif spotlight_node:
		spotlight_node.position = light_original_pos

	if not foot_land and is_on_floor():
		%FootAudio3D.play()
	elif foot_land and not is_on_floor():
		%FootAudio3D.play()
	foot_land = is_on_floor()

func update_flashlight_power(delta: float) -> void:
	if first_depletion and flashlight_power <= 5.0:
		first_depletion = false
		_start_dialogue(dialogue, "start")

	if flashlight_enabled and spotlight_node and not is_recharging:
		flashlight_power = max(0.0, flashlight_power - power_drain_rate * delta)
		_stop_charging_audio()

		if flashlight_power <= 50.0 and flashlight_power > 0.0:
			is_blinking = true
			handle_blinking(delta)
		elif flashlight_power <= 0.0:
			spotlight_node.visible = false
			is_blinking = false
		else:
			spotlight_node.visible = true
			is_blinking = false
	elif not flashlight_enabled and spotlight_node and is_recharging:
		flashlight_power = min(100.0, flashlight_power + power_drain_rate * recharge_rate_multiplier * delta)
		if not is_charging_audio_playing:
			%ChargingAudio3D.play()
			is_charging_audio_playing = true
	else:
		_stop_charging_audio()

func handle_blinking(delta: float) -> void:
	blink_timer += delta
	var current_interval := max(0.05, blink_interval * (flashlight_power / 50.0))

	if blink_timer < current_interval:
		return

	blink_timer = 0.0
	var on_chance := flashlight_power / 50.0
	var random_factor := randf()

	if random_factor < 0.8:
		spotlight_node.visible = randf() < on_chance
	elif random_factor < 0.9:
		spotlight_node.visible = false
		create_tween().tween_callback(func():
			if is_blinking:
				spotlight_node.visible = randf() < on_chance
		).set_delay(current_interval * 0.3)
	else:
		spotlight_node.visible = false
		create_tween().tween_callback(func():
			if is_blinking:
				spotlight_node.visible = randf() < on_chance
		).set_delay(current_interval * 0.7)

func _stop_charging_audio() -> void:
	if is_charging_audio_playing:
		%ChargingAudio3D.stop()
		is_charging_audio_playing = false

func headbob(time: float) -> Vector3:
	var headbob_pos := Vector3.ZERO
	headbob_pos.y = sin(time * headbob_freq) * headbob_amp
	headbob_pos.x = cos(time * headbob_freq / 2.0) * headbob_amp

	var foot_threshold := -headbob_amp + 0.002
	if headbob_pos.y > foot_threshold:
		foot_sound = true
	elif headbob_pos.y < foot_threshold and foot_sound:
		foot_sound = false
		%FootAudio3D.play()

	return headbob_pos

func light_shake() -> Vector3:
	return Vector3(
		sin(light_shake_time * 1.3) * light_shake_intensity,
		cos(light_shake_time * 1.7) * light_shake_intensity * 0.8,
		sin(light_shake_time * 2.1) * light_shake_intensity * 0.6
	)

func start_light_shake() -> void:
	light_shake_enabled = true

func stop_light_shake() -> void:
	light_shake_enabled = false

func toggle_flashlight() -> void:
	if spotlight_node:
		flashlight_enabled = not flashlight_enabled
		spotlight_node.visible = flashlight_enabled and flashlight_power > 0.0

func map_toggle_fun() -> void:
	if not has_map:
		return

	map_toggle = not map_toggle
	if map_toggle:
		%MapMeshInstance3D.visible = true
		%MapInAudio3D.play()
		create_tween().tween_property(%MapArm3D, "spring_length", -0.2, 0.33)
	else:
		%MapOutAudio3D.play()
		create_tween().tween_property(%MapArm3D, "spring_length", 4.0, 0.33)

func get_camera_relative_input() -> Vector3:
	var input_dir := Vector3.ZERO
	if Input.is_key_pressed(KEY_A):
		input_dir -= %Arm.global_transform.basis.x
	if Input.is_key_pressed(KEY_D):
		input_dir += %Arm.global_transform.basis.x
	if Input.is_key_pressed(KEY_W):
		input_dir -= %Arm.global_transform.basis.z
	if Input.is_key_pressed(KEY_S):
		input_dir += %Arm.global_transform.basis.z
	return input_dir

func _input(p_event: InputEvent) -> void:
	if not (p_event is InputEventKey):
		return

	if not p_event.pressed and p_event.keycode == KEY_R:
		is_recharging = false
		_stop_charging_audio()
		return

	if not can_move or not p_event.pressed or p_event.echo:
		return

	match p_event.keycode:
		KEY_F:
			toggle_flashlight()
		KEY_R:
			is_recharging = true
		KEY_M:
			map_toggle_fun()

func _start_dialogue(dialogue_resource: DialogueResource, start_node: String) -> void:
	can_move = false
	is_recharging = false
	_stop_charging_audio()
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	DialogueManager.show_dialogue_balloon(dialogue_resource, start_node)
	await DialogueManager.dialogue_ended
	_on_dialogue_ended()

func _on_dialogue_ended() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	can_move = true
