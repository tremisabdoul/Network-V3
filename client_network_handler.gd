extends Node

var ENet: ENetMultiplayerPeer = ENetMultiplayerPeer.new()
var TARGET_IP: String = "127.0.0.1"
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



func instanciate_player(id: int):
	print("Client ", id, "'s Player scene spawned")
	#var player = _Player.instantiate()
	#player.name = str(id)
	#player.set_multiplayer_authority(id)
	#get_node("/root/Game/Entities/Players").add_child(player)


func uninstanciate_player(id: int):
	print("Client ", id, "'s Player scene unspawned")
	if get_node("/root/").has_node("/Game/Entities/Players/" + str(id)):
		get_node("/root/Game/Entities/Players/" + str(id)).queue_free()


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
			get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
					"is server: false, players: " + str(players_data["players"].keys())

		if id == str(multiplayer.get_unique_id()):
			if randf() > .0:
				print("Delay: ", round(data["players"][id]["delay"]*5)/5, "\tms")

	for id in players_remaining:
		print("Client disconnection:\t", id)
		players_data["players"].erase(id)
		get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
		"is server: false, players: " + players_data["players"].keys()


# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #
# --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- --- #


func _ready():
	players_data = {"players": {}}

	join_room()


func _process(_delta):
	if ENet.get_connection_status() != current_connection_status:
		current_connection_status = ENet.get_connection_status()
		get_node("Net Status").text = CONNECTION_STATUS_MESSAGES[current_connection_status] + \
		"is server: false, players: " + str(players_data["players"].keys())

	if Input.is_action_just_pressed("switch_network_status_visibility"):
		get_node("Net Status").visible = !get_node("Net Status").visible

	if current_connection_status == 2:
		var action_var: int = 0
		for i in range(len(Global.actions)):
			action_var += int(Input.is_action_pressed(Global.actions[i])) * int(pow(2, i))
		rpc_id(1, "synchronise_data", {
			"time": Time.get_unix_time_from_system(), 
			"inputs": action_var
		})


func _exit_tree():
	if multiplayer.multiplayer_peer:
		multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = null
