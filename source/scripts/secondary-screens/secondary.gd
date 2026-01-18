extends Control

var udp = PacketPeerUDP.new()

func _ready():
	# Se connecter au serveur
	var err = udp.bind(23456)
	if err != OK:
		print("Erreur de connexion UDP :", err)
	else:
		print("Prêt à recevoir des paquets UDP")

func _process(_delta):
	while udp.get_available_packet_count() > 0:
		var packet = udp.get_packet()
		var msg = packet.get_string_from_utf8()
		_process_udp_packet(msg)

func _process_udp_packet(packet: String) -> void:
	if packet.begins_with("player_pos: "):
		var key := packet.substr(len("player_pos: "))
		$Label.text = key
