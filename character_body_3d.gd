extends Node

var data: Dictionary = {}
var inputs_pressed: Array[StringName] = []
var last_inputs_pressed: Array[StringName] = []


func is_input_pressed(input_name):
	return input_name in inputs_pressed


func get_inputs_pressed(inputs):
	inputs_pressed = []
	var i: int = 0
	while inputs:
		if inputs % 2:
			inputs_pressed.append(Global.actions[i])
		inputs /= 2
		i += 1
	return inputs_pressed


func is_input_just_pressed(input_name):
	return (!(input_name in last_inputs_pressed)) && (input_name in inputs_pressed)


func is_input_just_released(input_name):
	return ((input_name in last_inputs_pressed)) && !(input_name in inputs_pressed)
