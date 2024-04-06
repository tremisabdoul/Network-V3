extends Node

@onready var InputTool: Node

var data: Dictionary = {"delay": 0, "online_variables": {}}
var last_data: Dictionary = {"delay": 0, "online_variables": {}}


func _input(event):
	if is_owner():
		if event is InputEventMouseMotion:
			rpc_id(1, "mouse_motion", event.relative.x, event.relative.y)
			mouse_motion(event.relative.x, event.relative.y)


@rpc("any_peer", "call_remote", "unreliable")
func mouse_motion(x, y):
	if has_node("Player"):
		get_node("Player").rotation.y += -x * get_node("Player").sensi.x
		if has_node("Player/Camera"):
			get_node("Player/Camera").rotation.x += -y * get_node("Player").sensi.y

func synchronize_data(_data: Dictionary):
	last_data = data
	data = _data
	data["delay"] = round(data["delay"]*10)/10
	if randf() < 1:#0.01:
		get_node("Debug").text = playername+"'s delay: " + str(data["delay"]) + "\tms"
		#print("Delay: ", data["delay"], "\tms")
	if playername != data["online_variables"]["playername"]:
		playername = data["online_variables"]["playername"]
		update_playername()
	if has_node("Player"):
		get_node("Player")._network_process()


func update_playername():
	var Lobby = get_node("/root/Main Menu/Lobby")
	if playername and is_owner():
		Lobby.get_node("Ready Button")["theme_override_colors/font_color"] = Color.GREEN
	Lobby.playerlist[name] = playername
	Lobby.get_node("Ready Check").text = ""
	for player in Lobby.playerlist.values():
		Lobby.get_node("Ready Check").text += player + "\n"
	var is_everyone_ready: bool = true
	for player in get_node("..").get_children():
		if !(get_node("../"+str(player.name)).playername):
			is_everyone_ready = false
	if is_everyone_ready:
		Global.start_game()


var playername: String = ""
var rotation_y: float = 0.
var origin: Vector3 = Vector3()
var velocity: Vector3 = Vector3()


func get_online_variables():
	#var x = ""
	#for _i in range(3900):
	#	x += "0"
	#print(255*len(x))
	return { 
		"playername": playername, 
		"rotation y": rotation_y, 
		"origin": origin, 
		"velocity": velocity
	}


func display(variable, sender: int):
	var id1 = 0.
	for _char in str(sender):
		id1 += int(_char) * .1
	var id2 = 0.
	for _char in str(multiplayer.get_unique_id()):
		id2 += int(_char) * .1
	print("--- Remote display --- Sender: "+str(id1)[0]+str(id1)[2]+" --- Reciver: "+str(id2)[0]+str(id2)[2]+"\n"+variable+"\n")


func _ready():
	get_node("Debug").position.y = 72 + 64 * (get_parent().get_child_count() - 1)
	if is_owner() or multiplayer.is_server():
		add_child(load("res://input_tool.tscn").instantiate())
		InputTool = get_node("InputTool")

func server_network_process(_data: Dictionary):
	data = _data
	input_process(_data["inputs"])

func input_process(inputs: int):
	InputTool.input_process(inputs)

func _physics_process(_delta):
	
	if !multiplayer.is_server():
		pass
	if is_owner():
		pass#NETWORK_RPC_CALL_EXEMPLE()
	if multiplayer.is_server() or is_owner():
		pass
	else:
		pass#print(len(data["online_variables"]["x"]))


func is_owner(): return str(multiplayer.get_unique_id()) == name


func NETWORK_RPC_CALL_EXEMPLE():
	get_node("/root/Network").rpc_call(
		get_path(),	# Path (Current path there)
		"display",	# Function name
		[
			"Boujour voici un poti message !", 
			multiplayer.get_unique_id()
		]			# Arguments
	)


func main_menu_ready_server_check(_playername: String = "Snow"):
	var i = 0
	while i < len(_playername):
		if ("A"<=_playername[i]) and (_playername[i]<="Z") or \
				("a"<=_playername[i]) and (_playername[i]<="z") or \
				("0"<=_playername[i]) and (_playername[i]<="9") or \
				_playername[i] in "-_!?.éè#':":
			i += 1
		else:
			_playername = _playername.erase(i)
		
	if _playername in get_node("/root/Main Menu/Lobby").playerlist.values() \
			or len(_playername) < 1 or len(_playername) > 32 \
			or Global.status != Global.States.LOBBY:
		return
	#get_node("/root/Network").rpc_call(
	#	get_path(), 
	#	"main_menu_set_ready", 
	#	[_playername], 
	#	true
	#)
	#
	main_menu_set_ready(_playername)


func main_menu_set_ready(_playername: String = "Snow"):
	var Lobby = get_node("/root/Main Menu/Lobby")
	Lobby.playerlist[name] = _playername
	playername = _playername
	#print("\n", multiplayer.get_unique_id())
	#print(name, "'s name set to: ", _playername)
	#print(Lobby.playerlist)
	#if str(multiplayer.get_unique_id()) in Lobby.playerlist.keys():
	#	Lobby.get_node("Ready Button")["theme_override_colors/font_color"] = Color.GREEN
	#else:
	#	Lobby.get_node("Ready Button")["theme_override_colors/font_color"] = Color.RED
	Lobby.get_node("Ready Check").text = ""
	for player in Lobby.playerlist.values():
		Lobby.get_node("Ready Check").text += player + "\n"
	
	var is_everyone_ready: bool = true
	for player in get_node("..").get_children():
		if !(get_node("../"+str(player.name)).playername):
			is_everyone_ready = false
	if is_everyone_ready:
		Global.start_game()
		get_node("/root/Network").players_data["map"] = str(randi()%1+1)
