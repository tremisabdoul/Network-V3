extends Node


var ENet: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var PORT: int = 21212

enum States {
	UNDEFINED = -1, 
	STOPPED = 0, 
	LOBBY = 1, 
	GAME = 2
}

const CONNECTION_STATUS_MESSAGES = [
	"net status: [color=#FF1500]disconnected[/color],", 
	"net status: [color=#FFFF00]connecting...[/color], ",
	"net status: [color=#00FF00]connected[/color], "
]

var current_connection_status: int
var players_data: Dictionary


func create_room():
	print("Server creation started")
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	ENet.create_server(PORT)
	multiplayer.multiplayer_peer = ENet
	multiplayer.peer_connected.connect(self.connect_peer)
	multiplayer.peer_disconnected.connect(self.disconnect_peer)


func connect_peer(id):
	id = str(id)
	print("Client connection:\t", id)
	players_data["players"][id] = {"delay": 0.0}
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"is server: true, players: " + str(players_data["players"].keys())


func disconnect_peer(id):
	id = str(id)
	print("Client disconnection:\t", id)
	if players_data["players"].has(id):
		players_data["players"].erase(id)
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"is server: true, players: " + str(players_data["players"].keys())


func instanciate_player(id: String):
	print("Client ", id, "'s Player scene spawned")
	#var Player = _Player.instantiate()
	#Player.name = str(id)
	#get_node("/root/Game/Entities/Players").add_child(Player)


func uninstanciate_player(id: String):
	print("Client ", id, "'s Player scene unspawned")
	#if get_node("/root/").has_node("/Game/Entities/Players/" + str(id)):
	#	get_node("/root/Game/Entities/Players/" + str(id)).queue_free()


@rpc("any_peer", "call_remote", "unreliable", 0)
func synchronise_data(data: Dictionary):
	var sender: String = str(multiplayer.get_remote_sender_id())
	players_data["players"][sender]["delay"] = (players_data["players"][sender]["delay"] * 99 + 
			(Time.get_unix_time_from_system() - data["time"]) * 1000) / 100
	players_data["players"][sender]["delay"] = float(players_data["players"][sender]["delay"])


func send_data():
	players_data["time"] = Time.get_unix_time_from_system()
	var x = load("res://icon.svg")
	for i in range(10000):
		players_data["i"+str(i)] = x
	rpc("synchronise_data", players_data)


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


func _ready():
	players_data = {"players": {}}

	create_room()

	var upnp = UPNP.new()
	upnp.discover(2000, 2, "InternetGatewayDevice")
	get_node("Net Status/Server help").text = "Server help:" + \
		"\n1) Do a port-forward on your firewall using the UDP protocol. (Needed: Port)" + \
		"\n2) Do the same on your router with the UDP protocol. (Needed: Local IPv4, Port)" + \
		"\n3) Give your Public IP to the players. (Needed: Public IPv4)" + \
		"\nJust please... The Public IP and the Local one aren't the same !" + \
		"\nPort: " + str(PORT) + "\nLocal IPv4 adress: " + IP.get_local_addresses()[-1] + \
		"\nPublic IPv4 adress: " + upnp.query_external_address() + \
		"\nDon't forget to close the port that you opened on your router when you will close " + \
		"the server !"

	get_node("Net Status/Server help").visible = true


func _process(_delta):
	if ENet.get_connection_status() != current_connection_status:
		current_connection_status = ENet.get_connection_status()
		get_node("Net Status").set("text", CONNECTION_STATUS_MESSAGES[current_connection_status] + \
				"is server: true, players: " + str(players_data["players"].keys())
		)

	if Input.is_action_just_pressed("switch_network_status_visibility"):
		get_node("Net Status").visible = !get_node("Net Status").visible
		if get_node("Net Status").visible:
			get_window().reset_size()
			get_viewport().disable_3d = false
		else:
			get_window().size = Vector2(0, 0)
			get_viewport().disable_3d = true

	if current_connection_status == 2:
		send_data()


func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
