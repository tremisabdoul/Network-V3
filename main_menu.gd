extends Node2D


func _on_start_server_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	var network = load("res://server_network_handler.tscn").instantiate()
	network.PORT = $Connection/Port.text if $Connection/Port.text else 21212
	get_node("/root/").add_child(network)
	$Lobby.visible = false
	$Connection.visible = false


func _on_start_client_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	var network = load("res://client_network_handler.tscn").instantiate()
	network.TARGET_IP = $Connection/IP.text if $Connection/IP.text else "127.0.0.1"
	network.PORT = $Connection/Port.text if $Connection/Port.text else 21212
	get_node("/root/").add_child(network)
	$Lobby.visible = true
	$Connection.visible = false

func _on_disconnect_pressed():
	if get_node("/root/").has_node("Network"):
		get_node("/root/Network").queue_free()
	$Lobby.visible = false
	$Connection.visible = true
