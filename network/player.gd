extends Node

var data: Dictionary = {"delay": 0, "online_variables": {}}
var inputs_pressed: Array[StringName] = []
var last_inputs_pressed: Array[StringName] = []

var last_process_time: float = Time.get_unix_time_from_system()
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
	if randf() < 0.001:
		print("Delay: ", data["delay"], "\tms")


func input_process(inputs: int):
	last_inputs_pressed = inputs_pressed
	inputs_pressed = get_inputs_pressed(inputs)
	get_node("Debug").text = str(inputs_pressed) + ""


func get_online_variables():
	return {
		"state": "lobby", 
		"basis": Basis(), 
		"velocity": Vector3(), 
		#"x": OS.get_system_fonts()
	}


func _physics_process(_delta):
	if !multiplayer.is_server():
		pass
	if multiplayer.is_server() or is_owner():
		pass
	else:
		pass#print(len(data["online_variables"]["x"]))

func is_owner(): return str(multiplayer.get_unique_id()) == name
