extends Node

@onready var Players: Node = get_node("Players")

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
	if !Players.has_node(id):
		Players.add_child(Global._Player.instantiate())
		Players.get_children()[-1].name = id
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"is server: true, players: " + str(players_data["players"].keys())


func disconnect_peer(id):
	id = str(id)
	print("Client disconnection:\t", id)
	if players_data["players"].has(id):
		players_data["players"].erase(id)
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"is server: true, players: " + str(players_data["players"].keys())


@rpc("any_peer", "call_remote", "unreliable", 0)
func synchronise_data(data: Dictionary):
	var id: String = str(multiplayer.get_remote_sender_id())
	if Players.has_node(id):
		Players.get_node(id).input_process(data["inputs"])
	players_data["players"][id]["delay"] = (players_data["players"][id]["delay"] * 99 + 
			(Time.get_unix_time_from_system() - data["time"]) * 1000) / 100
	players_data["players"][id]["delay"] = float(players_data["players"][id]["delay"])


func send_data():
	players_data["time"] = Time.get_unix_time_from_system()
	for id in players_data["players"]:
		players_data["players"][id]["online_variables"] = \
				Players.get_node(id).get_online_variables()
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
		if !get_parent().size:
			print("e")
			get_parent().borderless = false
			get_window().reset_size()
			if get_window().size.length() < 128:
				get_window().size = Vector2(736, 328)
				get_window().position = Vector2(0, 32)
			#get_viewport().disable_3d = false
		else:
			print("f")
			get_parent().borderless = true
			get_parent().min_size = Vector2()
			get_window().size = Vector2()
			#get_viewport().disable_3d = true

	if current_connection_status == 2:
		send_data()


func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
