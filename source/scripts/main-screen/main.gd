extends Node3D

var udp = PacketPeerUDP.new()

func _ready():
	# Se connecter au serveur
	var err = udp.connect_to_host("127.0.0.1", 23456)  # IP et port du serveur
	if err != OK:
		print("Erreur de connexion UDP :", err)
	else:
		print("Prêt à envoyer des paquets UDP")

func send(message: String):
	var bytes = message.to_utf8_buffer()  # Convertir la chaîne en tableau d'octets
	var err = udp.put_packet(bytes)
	if err != OK:
		print("Erreur envoi UDP :", err)
