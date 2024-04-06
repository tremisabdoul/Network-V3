extends Node

var inputs_pressed: Array[StringName] = []
var last_inputs_pressed: Array[StringName] = []
var last_process_time: float = Time.get_unix_time_from_system()


func is_action_pressed(input_name):
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


func is_action_just_pressed(input_name):
	return (!(input_name in last_inputs_pressed)) && (input_name in inputs_pressed)


func is_action_just_released(input_name):
	return ((input_name in last_inputs_pressed)) && !(input_name in inputs_pressed)

func get_axis(input_name0, input_name1):
	return float(input_name1 in last_inputs_pressed) - float(input_name0 in inputs_pressed)

func get_vector(input_name0, input_name1, input_name2, input_name3):
	return Vector2(float(input_name1 in last_inputs_pressed) - float(input_name0 in inputs_pressed),
			float(input_name3 in last_inputs_pressed) - float(input_name2 in inputs_pressed)
	)

func input_process(inputs: int):
	last_inputs_pressed = inputs_pressed
	inputs_pressed = get_inputs_pressed(inputs)
	#get_node("../Debug").text = get_parent().playername + ": " + str(inputs_pressed) + ""
	if has_node("../Player"):
		get_node("../Player").input_process(Time.get_unix_time_from_system() - last_process_time)
	last_process_time = Time.get_unix_time_from_system()


func _ready():
	pass
