extends Node


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if !has_node("Map"):
		if get_node("/root/Network").players_data.has("map"):
			add_child(load("res://maps/"+str(get_node("/root/Network").players_data["map"])+".tscn").instantiate())
		if multiplayer.is_server():
			get_node("Map/Sun").queue_free()
			get_node("Map/Environment").environment = Environment.new()
