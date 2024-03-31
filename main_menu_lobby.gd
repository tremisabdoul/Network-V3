extends Control

var playerlist: Dictionary = {}


func _on_ready_button_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").rpc_call(
			"/root/Network/Players/"+str(multiplayer.get_unique_id()), 
			"main_menu_ready_server_check", 
			[$ID.text], 
			false
		)
