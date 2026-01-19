extends Interactable
class_name Executable

@export var command: String = ""
@export var runs_in_background := false

const UDP_FOCUS_ON_CMD := "echo \"focus ON\" | socat - UDP4-DATAGRAM:127.0.0.1:12345"
const UDP_FOCUS_OFF_CMD := "echo \"focus OFF\" | socat - UDP4-DATAGRAM:127.0.0.1:12345"
@warning_ignore("integer_division")
var CURSOR_CENTER := Vector2i(DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW).x/2, DisplayServer.screen_get_size(DisplayServer.SCREEN_OF_MAIN_WINDOW).y/2)

var process_id := -1

# =======================
# Public API
# =======================
func interact() -> void:
	print("Interacted with:", name)

	if runs_in_background:
		_exec_background()
	else:
		_exec_foreground()

# =======================
# Foreground execution
# =======================
func _exec_foreground() -> void:
	_send_focus(false)
	_reset_submap()

	# Already running → focus window
	if process_id != -1:
		_focus_process()
		return

	process_id = OS.create_process("sh", ["-lc", command])
	if process_id == -1:
		push_error("Failed to start process: %s" % command)
		return

	set_process(true)

# =======================
# Background execution
# =======================
func _exec_background() -> void:
	OS.execute("sh", ["-lc", command])

# =======================
# Process monitoring
# =======================
func _process(_delta: float) -> void:
	if process_id == -1:
		return

	if OS.is_process_running(process_id):
		return

	_on_process_finished()

func _on_process_finished() -> void:
	print("Command finished:", name)

	process_id = -1
	set_process(false)

	_send_focus(true)
	_restore_submap()

# =======================
# Helpers
# =======================
func _send_focus(toggle: bool) -> void:
	if toggle:
		OS.execute("sh", ["-lc", UDP_FOCUS_ON_CMD])
	else:
		OS.execute("sh", ["-lc", UDP_FOCUS_OFF_CMD])

func _focus_process() -> void:
	OS.execute("hyprctl", ["dispatch", "focuswindow", "pid:%d" % process_id])

func _reset_submap() -> void:
	OS.execute("hyprctl", ["keyword", "cursor:invisible", "false"])
	OS.execute("hyprctl", ["dispatch", "submap", "reset"])

func _restore_submap() -> void:
	OS.execute("hyprctl", ["keyword", "cursor:invisible", "true"])
	OS.execute("hyprctl", ["dispatch", "movecursor", str(CURSOR_CENTER.x), str(CURSOR_CENTER.y)])
	OS.execute("hyprctl", ["dispatch", "submap", "hyprrealm"])
