extends Node

var _Player: PackedScene

var input_list: Array[StringName] = InputMap.get_actions()


func _ready():
	var i: int = 0
	while i < len(input_list):
		if !input_list[i].begins_with(&"ui_"):
			i += 1
		else:
			input_list.pop_at(i)
	_Player = load("res://network/player.tscn")
