extends CharacterBody3D

# =======================
# Constants / Networking
# =======================
const UDP_PORT := 12345
@warning_ignore("integer_division")
var CURSOR_CENTER := Vector2i(DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW).x/2, DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW).y/2)

# =======================
# Nodes
# =======================
@onready var head := $Camera3D
@onready var raycast := $Camera3D/RayCast3D
@onready var ui := $Camera3D/UI
@onready var tooltip := $Camera3D/UI/Tooltip
@onready var GM := $".."

# =======================
# State
# =======================
var udp := PacketPeerUDP.new()

var speed := 6.0
var mouse_sensitivity := 0.002
var camera_smooth := 16.0

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

var hasFocus := false
var input_dir := Vector2.ZERO

var target_yaw := 0.0
var target_pitch := 0.0

var moving := {
	"forward": false,
	"back": false,
	"left": false,
	"right": false
}

# =======================
# Lifecycle
# =======================
func _ready() -> void:
	var err := udp.bind(UDP_PORT)
	if err != OK:
		push_error("Failed to bind UDP on port %d" % UDP_PORT)

	udp.set_broadcast_enabled(true)

	target_yaw = rotation.y
	target_pitch = head.rotation.x

# =======================
# Process
# =======================
func _process(delta: float) -> void:
	_process_udp()
	_update_input_dir()

	if not hasFocus:
		_release_cursor()
		ui.hide()
		return

	ui.show()
	_update_camera(delta)
	_update_tooltip()

# =======================
# Physics
# =======================
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_movement()
	move_and_slide()

# =======================
# UDP
# =======================
func _process_udp() -> void:
	while udp.get_available_packet_count() > 0:
		var packet := udp.get_packet().get_string_from_utf8().strip_edges()
		_process_udp_packet(packet)

func _process_udp_packet(packet: String) -> void:
	if packet.begins_with("stop_"):
		var key := packet.substr(5)
		if moving.has(key):
			moving[key] = false
		return

	match packet:
		"click":
			try_interact()
		"focus":
			hasFocus = !hasFocus
			OS.execute("hyprctl", ["keyword", "cursor:invisible", hasFocus])
		"focus ON":
			hasFocus = true
			OS.execute("hyprctl", ["keyword", "cursor:invisible", true])
		"focus OFF":
			hasFocus = false
			OS.execute("hyprctl", ["keyword", "cursor:invisible", false])
		"forward", "back", "left", "right":
			if moving.has(packet):
				moving[packet] = true
		_:
			pass

# =======================
# Input & Movement
# =======================
func _update_input_dir() -> void:
	input_dir = Vector2(
		int(moving["right"]) - int(moving["left"]),
		int(moving["back"]) - int(moving["forward"])
	)

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
		velocity.y = max(velocity.y, -50.0)
		if global_position.y < -10.0:
			global_position = Vector3(0, 2, 0)
	else:
		velocity.y = 0.0

func _apply_movement() -> void:
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		GM.send("player_pos: x=%.2f y=%.2f z=%.2f" % [position.x, position.y, position.z])
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

# =======================
# Camera / Cursor
# =======================
func _update_camera(delta: float) -> void:
	var output := []
	OS.execute("hyprctl", ["cursorpos"], output)

	if output.is_empty():
		return

	var parts = output[0].split(",")
	if parts.size() != 2:
		return

	var mouse_pos := Vector2i(
		int(parts[0].strip_edges()),
		int(parts[1].strip_edges())
	)

	var delta_mouse := mouse_pos - CURSOR_CENTER
	if delta_mouse == Vector2i.ZERO:
		return

	target_yaw -= delta_mouse.x * mouse_sensitivity
	target_pitch -= delta_mouse.y * mouse_sensitivity
	target_pitch = clamp(target_pitch, deg_to_rad(-89), deg_to_rad(89))

	rotation.y = lerp_angle(rotation.y, target_yaw, camera_smooth * delta)
	head.rotation.x = lerp_angle(head.rotation.x, target_pitch, camera_smooth * delta)

	OS.execute("hyprctl", ["dispatch", "movecursor", str(CURSOR_CENTER.x), str(CURSOR_CENTER.y)])

func _release_cursor() -> void:
	OS.execute("hyprctl", ["keyword", "cursor:invisible", "false"])

# =======================
# UI / Interaction
# =======================
func _update_tooltip() -> void:
	var found := false

	if raycast.is_colliding():
		var node: Node = raycast.get_collider()
		while node and node != get_tree().current_scene:
			if node is Interactable:
				tooltip.text = node.tooltip
				found = true
				break
			node = node.get_parent()

	if not found:
		tooltip.text = ""

func try_interact() -> void:
	if not raycast.is_colliding():
		return

	var node: Node = raycast.get_collider()
	while node and node != get_tree().current_scene:
		if node is Executable:
			node.interact()
			return
		node = node.get_parent()
