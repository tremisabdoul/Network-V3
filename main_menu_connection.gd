extends Control


func _on_start_server_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	var network = load("res://network/server_network_handler.tscn").instantiate()
	if $Port.text: network.PORT = $Port.text
	else: network.PORT = 21212
	get_node("/root/").add_child(network)
	get_node("../Lobby").visible = false
	visible = false


func _on_start_client_pressed():
	if get_node("/root/").has_node("Network"): get_node("/root/Network").queue_free()
	var network = load("res://network/client_network_handler.tscn").instantiate()
	var x:String = $IP.text
	if x: network.TARGET_IP = x
	else: network.TARGET_IP = "127.0.0.1"
	if $Port.text: network.PORT = $Port.text
	else: network.PORT = 21212
	get_node("/root/").add_child(network)
	get_node("../Lobby").visible = true
	visible = false

func _on_disconnect_pressed():
	if get_node("/root/").has_node("Network"): get_node("/root/Network").queue_free()
	get_node("../Lobby").visible = false
	visible = true
