extends Node

var _Player: PackedScene = null

enum States {
	UNDEFINED = -1, 
	STOPPED = 0, 
	LOBBY = 1, 
	GAME = 2
}

var input_list: Array[StringName] = []

var status: States = States.UNDEFINED


func _ready():
	var i: int = 0
	input_list = InputMap.get_actions()
	while i < len(input_list):
		if !input_list[i].begins_with(&"ui_"):
			i += 1
		else:
			input_list.pop_at(i)
	_Player = load("res://network/player.tscn")
	var refresh_rate = DisplayServer.screen_get_refresh_rate()
	if refresh_rate < 0:
		refresh_rate = 60.0
	Engine.max_fps = int(refresh_rate) - 2
	status = States.LOBBY


func _process(_delta):
	if Input.is_action_just_pressed("fullscreen"):
		get_window().mode = (int(!get_window().mode) * 3) as Window.Mode
		
		Input.mouse_mode = (int(!Input.mouse_mode) * 2) as Input.MouseMode


func start_game():
	var Player: PackedScene = load("res://game/player.tscn")
	for player in get_node("/root/Network/Players").get_children():
		player.add_child(Player.instantiate())
	get_parent().add_child(load("res://game.tscn").instantiate())
	status = States.GAME
