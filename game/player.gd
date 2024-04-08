extends CharacterBody3D

var speed = 7.5
var jump = 12.
var gravity = 64
var input_dir: Vector2 = Vector2()
var accel: float = 25.
var air_accel: float = 5.
var decel: float = 100.
var sensi = Vector2(0.003, 0.003)

var dt: float = 0


func _ready():
	if get_parent().is_owner():
		get_node("Label").queue_free()
		get_node("/root/Main Menu").visible = false
	else:
		get_node("Label").text = get_parent().playername
		get_node("Camera").queue_free()


func _network_process(): # Executed on all clients
	if get_parent().is_owner():
		global_position = (get_parent().data["online_variables"]["origin"])
		global_rotation.y += angle_difference(global_rotation.y, get_parent().data["online_variables"]["rotation y"])
		velocity = (get_parent().data["online_variables"]["velocity"])
		position -= (velocity * get_parent().data["delay"]/1000)/2
		return
	global_rotation.y = get_parent().data["online_variables"]["rotation y"]
	velocity = get_parent().data["online_variables"]["velocity"]
	global_position = get_parent().data["online_variables"]["origin"]


func input_process(_delta):
	input_dir = get_parent().InputTool.get_vector("left", "right", "forward", "backward").normalized()
	#if get_parent().InputTool.is_action_just_pressed("jump") and is_on_floor():
	if get_parent().InputTool.is_action_pressed("jump") and is_on_floor():
		velocity.y = jump


func _process(_delta):
	if get_parent().is_owner():
		if is_on_floor():
			if 1:
				get_node("Camera").position.y = pow(cos(dt*.018), 2)*.05+.475
				get_node("Camera").position.x = pow(sin(dt*.018), 1)*.05
				get_node("Camera").position.z = -pow(sin(dt*.018*2), 1)*.02
				get_node("Camera").fov = (get_node("Camera").fov * 2 + 87.5 + 
					(abs(get_real_velocity().x) + abs(get_real_velocity().z))*.5)/3
			else:
				get_node("Camera").position = Vector3(0, .5, 0)
				get_node("Camera").fov = 90
	Engine.max_fps = int(Input.is_action_pressed("crouch"))*2


func _physics_process(delta):
	speed = 7.5
	#if !multiplayer.is_server():
	#	$CollisionShape3D.disabled = false
	if multiplayer.is_server():
		get_parent().origin = global_position
		get_parent().rotation_y = global_rotation.y
		get_parent().velocity = velocity
	delta = delta
	if get_parent().is_owner() or multiplayer.is_server():
		var direction: Vector3 = transform.basis * Vector3(input_dir.x, 0, input_dir.y)
		var acceleration: float
		var x = max(velocity.normalized().dot(direction), .1)
		if is_on_floor():
			#print(direction)
			#print(delta)
			acceleration = accel*x + decel*(1-x)
		else:
			acceleration = air_accel
			velocity.y -= gravity * delta
		velocity += direction * speed * delta * acceleration
		velocity.x /= 1+delta * acceleration
		velocity.z /= 1+delta * acceleration
		#velocity.x = direction.x * speed
		#velocity.z = direction.z * speed
	if get_parent().is_owner():
		change_settings()
		get_node("Camera/E").visible = get_node("Camera").global_transform.origin.y < -1
		get_node("/root/Game/Map/Environment").environment.fog_enabled = get_node("Camera").global_transform.origin.y < -1
	#get_node("/root/Game/Map/Environment").environment.fog_enabled = true
	move_and_slide()
	velocity = get_real_velocity()
	#if get_parent().is_owner():
	#	print(round(get_real_velocity().length()*delta*1000)/1000)
	dt += abs(velocity.x) + abs(velocity.z)

func change_settings():
	var i = true
	get_node("Camera").attributes.dof_blur_near_enabled = i
	get_node("/root/Game/Map/Environment").environment.volumetric_fog_enabled = i
	get_node("/root/Game/Map/Sun").shadow_enabled = i
