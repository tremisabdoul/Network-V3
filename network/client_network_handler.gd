extends Node

@onready var Players: Node = get_node("Players")

var ENet: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var TARGET_IP: String = "127.0.0.1"
var PORT: int = 21212

const CONNECTION_STATUS_MESSAGES = [
	"net status: [color=#FF1500]disconnected[/color], ", 
	"net status: [color=#FFFF00]connecting...[/color], ",
	"net status: [color=#00FF00]connected[/color], "
]

var current_connection_status: int = 0
var gamestate: int = 0
var players_data: Dictionary = {"players": {}}

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


func join_room():
	print("Starting the server connection")
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	ENet.create_client(TARGET_IP, PORT)
	multiplayer.multiplayer_peer = ENet


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


@rpc("authority", "call_remote", "unreliable", 0)
func synchronise_data(data: Dictionary):
	var players_remaining = players_data["players"].keys()
	for id in data["players"]:
		players_remaining.erase(id)
		if !(id in players_data["players"].keys()):
			print("Client connection:\t", id)
			players_data["players"][id] = {"delay": 0.0}
			if !Players.has_node(id):
				var Player = Global._Player.instantiate()
				Player.name = id
				Players.add_child(Player)
			players_data["players"][id] = {"delay": 0.0}
			get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
					"id: " + str(multiplayer.get_unique_id()) + ", is server: false, players: " + \
					str(players_data["players"].keys())
		Players.get_node(id).synchronize_data(data["players"][id])

	for id in players_remaining:
		print("Client disconnection:\t", id)
		players_data["players"].erase(id)
		get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
				"id: " + str(multiplayer.get_unique_id()) + ", is server: false, players: " + \
				str(players_data["players"].keys())
	if data.has("map"):
		players_data["map"] = data["map"]


func rpc_call(path: NodePath = "/root/Network/Players/LOCAL_ID/...", \
		method: StringName = "_ready", arg_array: Array = [], to_all_peers: bool = false):
	rpc("rpc_call_server_reciver", path, method, arg_array, to_all_peers)


@rpc("any_peer", "call_remote", "unreliable", 0)
func rpc_call_server_reciver(_path: NodePath = "/root/Network/Players/0", _method: StringName = "_ready", \
		_arg_array: Array = [], _to_all_peers: bool = false):
	pass


@rpc("authority", "call_remote", "unreliable", 0)
func rpc_call_client_reciver(path: NodePath = "/root/Network/Players/0", method: StringName = "_ready", \
		arg_array: Array = []):
	#if multiplayer.get_remote_sender_id() == 1:
	if has_node(path):
		get_node(path).callv(method, arg_array)

# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


func _ready():
	join_room()
	get_node("/root/Global").status = get_node("/root/Global").States.LOBBY


func _process(_delta):
	if ENet.get_connection_status() != current_connection_status:
		current_connection_status = ENet.get_connection_status()
		get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
				"id: " + str(multiplayer.get_unique_id()) + ", is server: false, players: " + \
				str(players_data["players"].keys())

	if Input.is_action_just_pressed("switch_network_status_visibility"):
		get_node("Net Status").visible = !get_node("Net Status").visible

	if current_connection_status == 2:
		send_data()

func send_data():
	if Players.has_node(str(multiplayer.get_unique_id())):
		var inputs = 0
		for i in range(len(Global.input_list)):
			inputs += int(Input.is_action_pressed(Global.input_list[i])) * int(pow(2, i))
		Players.get_node(str(multiplayer.get_unique_id())).input_process(inputs)
		rpc_id(1, "synchronise_data", {
			"time": Time.get_unix_time_from_system(), 
			"inputs": inputs, 
			"delay": get_node("Players/"+str(multiplayer.get_unique_id())).data["delay"]
		})


func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
