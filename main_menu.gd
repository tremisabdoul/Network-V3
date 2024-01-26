extends Node2D


func _on_start_server_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	var network = load("res://server_network_handler.tscn").instantiate()
	if $Connection/Port.text: network.PORT = $Connection/Port.text
	else: network.PORT = 21212
	get_node("/root/").add_child(network)
	$Lobby.visible = false
	$Connection.visible = false


func _on_start_client_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	var network = load("res://client_network_handler.tscn").instantiate()
	var x:String = $Connection/IP.text
	if x: network.TARGET_IP = x
	else: network.TARGET_IP = "127.0.0.1"
	if $Connection/Port.text: network.PORT = $Connection/Port.text
	else: network.PORT = 21212
	get_node("/root/").add_child(network)
	$Lobby.visible = true
	$Connection.visible = false

func _on_disconnect_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	$Lobby.visible = false
	$Connection.visible = true
