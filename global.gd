extends Node

var actions: Array[StringName] = InputMap.get_actions()


func _ready():
	var i: int = 0
	while i < len(actions):
		if !actions[i].begins_with(&"ui_"):
			i += 1
		else:
			actions.pop_at(i)
