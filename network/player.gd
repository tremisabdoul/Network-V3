extends Node

var data: Dictionary = {"delay": 0, "online_variables": {}}
var inputs_pressed: Array[StringName] = []
var last_inputs_pressed: Array[StringName] = []

var last_process_time: float = Time.get_unix_time_from_system()

var playername: String = ""

func is_input_pressed(input_name):
	return input_name in inputs_pressed


func get_inputs_pressed(inputs):
	inputs_pressed = []
	var i: int = 0
	while inputs:
		if inputs % 2:
			inputs_pressed.append(Global.input_list[i])
		inputs /= 2
		i += 1
	return inputs_pressed


func is_input_just_pressed(input_name):
	return (!(input_name in last_inputs_pressed)) && (input_name in inputs_pressed)


func is_input_just_released(input_name):
	return ((input_name in last_inputs_pressed)) && !(input_name in inputs_pressed)


func synchronize_data(_data: Dictionary):
	data = _data
	data["delay"] = round(data["delay"]*10)/10
	if randf() < 0.01:
		print("Delay: ", data["delay"], "\tms")
	if playername != data["online_variables"]["playername"]:
		playername = data["online_variables"]["playername"]
		update_playername()


func update_playername():
	var Lobby = get_node("/root/Main Menu/Lobby")
	if playername and is_owner():
		Lobby.get_node("Ready Button")["theme_override_colors/font_color"] = Color.GREEN
	Lobby.playerlist[name] = playername
	Lobby.get_node("Ready Check").text = ""
	for player in Lobby.playerlist.values():
		Lobby.get_node("Ready Check").text += player + "\n"


func input_process(inputs: int):
	last_inputs_pressed = inputs_pressed
	inputs_pressed = get_inputs_pressed(inputs)
	get_node("Debug").text = playername + ": " + str(inputs_pressed) + ""


func get_online_variables():
	#var x = ""
	#for _i in range(3900):
	#	x += "0"
	#print(255*len(x))
	return {
		"state": "lobby", 
		"playername": playername, 
		"basis": Basis(), 
		"velocity": Vector3(),
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
	print(get_node("Debug").position.y)


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
			or len(_playername) < 1 or len(_playername) > 32:
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
