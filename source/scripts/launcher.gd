# single_screen_wallpaper.gd
extends Node

func _ready():
	# Récupérer l'écran via argument
	var idx : int = 0
	var args = OS.get_cmdline_args()
	if args.size() > 0:
		idx = int(args[0])

	# Position et taille de l'écran
	var pos = DisplayServer.screen_get_position(idx)
	var size = DisplayServer.screen_get_size(idx)

	# Configurer la fenêtre
	var win = get_window()
	win.position = pos
	win.size = size
	win.borderless = true
	win.title = "background%d" % idx

	# Charger la scène appropriée
	var scene_path : String
	if idx == 0:
		scene_path = "res://scenes/main.tscn"
	else:
		scene_path = "res://scenes/secondary.tscn"

	if ResourceLoader.exists(scene_path):
		var scene_instance = load(scene_path).instantiate()
		add_child(scene_instance)
	else:
		push_error("Scene introuvable: %s" % scene_path)

	print("Écran %d prêt avec scène: %s" % [idx, scene_path])
