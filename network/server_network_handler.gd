extends Node

@onready var Players: Node = get_node("Players")

var ENet: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var PORT: int = 21212

const CONNECTION_STATUS_MESSAGES = [
	"net status: [color=#FF1500]disconnected[/color], ", 
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
	if !Players.has_node(id):
		Players.add_child(Global._Player.instantiate())
		Players.get_children()[-1].name = id
	players_data["players"][id] = Players.get_node(id).get_online_variables()
	players_data["players"][id]["delay"] = 0.
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"id: 1, is server: false, players: " + str(players_data["players"].keys())


func disconnect_peer(id):
	id = str(id)
	print("Client disconnection:\t", id)
	if players_data["players"].has(id):
		players_data["players"].erase(id)
	get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
			"id: 1, is server: false, players: " + str(players_data["players"].keys())


@rpc("any_peer", "call_remote", "unreliable", 0)
func synchronise_data(data: Dictionary):
	var id: String = str(multiplayer.get_remote_sender_id())
	if Players.has_node(id):
		Players.get_node(id).input_process(data["inputs"])
	players_data["players"][id]["delay"] = (players_data["players"][id]["delay"] * 24 + 
			(Time.get_unix_time_from_system() - data["time"]) * 1000) / 25
	players_data["players"][id]["delay"] = float(players_data["players"][id]["delay"])


func send_data():
	players_data["time"] = Time.get_unix_time_from_system()
	for id in players_data["players"]:
		players_data["players"][id]["online_variables"] = \
				Players.get_node(id).get_online_variables()
	rpc("synchronise_data", players_data)


func rpc_call(path: NodePath = "/root/Network/Players/LOCAL_ID/...", \
		method: StringName = "_ready", arg_array: Array = [], to_all_peers: bool = false):
	call_deferred("rpc_call_server_reciver", path, method, arg_array, to_all_peers)


@rpc("any_peer", "call_remote", "unreliable", 0)
func rpc_call_server_reciver(path: NodePath = "/root/Network/Players/0", method: StringName = "_ready", \
		arg_array: Array = [], to_all_peers: bool = false):
	var sender: int = multiplayer.get_remote_sender_id()
	if sender == 0: # If the function is called locally
		sender = 1  # The call come from the server
	if to_all_peers:
		if str(sender) in str(path) or sender == 1:
			for id in players_data["players"].keys():
				id = int(id)
				if id != sender:
					rpc_id(id, "rpc_call_client_reciver", path, method, arg_array)
	else:
		get_node(path).callv(method, arg_array)


@rpc("authority", "call_remote", "unreliable", 0)
func rpc_call_client_reciver(_path: NodePath = "/root/Network/Players/0", _method: StringName = "_ready", \
		_arg_array: Array = []):
	pass


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


func _ready():
	players_data = {"players": {}}

	create_room()

	var public_ipv4: String = ""
	if UDPServer.new().is_connection_available():
		var upnp = UPNP.new()
		upnp.discover(2000, 2, "InternetGatewayDevice")
		public_ipv4 = upnp.query_external_address()
	else:
		public_ipv4 = "0.0.0.0 (OFFLINE)"
	
	get_node("Net Status/Server help").text = "Server help:" + \
		"\n1) Do a port-forward on your firewall using the UDP protocol. (Needed: Port)" + \
		"\n2) Do the same on your router with the UDP protocol. (Needed: Local IPv4, Port)" + \
		"\n3) Give your Public IP to the players. (Needed: Public IPv4)" + \
		"\nJust please... The Public IP and the Local one aren't the same !" + \
		"\nPort: " + str(PORT) + "\nLocal IPv4 adress: " + IP.get_local_addresses()[-1] + \
		"\nPublic IPv4 adress: " + public_ipv4 + \
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
			Engine.max_fps = 60
			ProjectSettings["application/run/low_processor_mode"] = false
			#get_viewport().disable_3d = false
		else:
			print("f")
			get_parent().borderless = true
			get_parent().min_size = Vector2()
			get_window().size = Vector2()
			Engine.max_fps = 512
			ProjectSettings["application/run/low_processor_mode"] = true
			#get_viewport().disable_3d = true

	if current_connection_status == 2:
		send_data()


func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
