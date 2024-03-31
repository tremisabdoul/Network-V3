extends CharacterBody3D


const SPEED: float = .1 # Speed added on each frame based on the user input
var linear_damp: float = pow(2, .1) # Friction in the air for the velocity variable
var rotation_velocity: Vector3 = Vector3()
var angular_damp: float = pow(2, .1) # Friction in the air for the rotation_velocity variable
var sensi: float = 0.003


func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_window().mode = Window.MODE_FULLSCREEN

func _input(event):
	if event is InputEventMouseMotion:
		rotation_velocity -= transform.basis.x * event.relative.y * sensi * angular_damp
		if !Input.is_action_pressed("rotate_z"):
			rotation_velocity -= transform.basis.y * event.relative.x * sensi * angular_damp
		else:
			rotation_velocity -= transform.basis.z * event.relative.x * sensi * angular_damp

func _physics_process(delta):
	var dir: Vector3 = Vector3(Input.get_axis("left", "right"), Input.get_axis("down", "up"), Input.get_axis("forward", "backward"))
	dir = dir.normalized() * SPEED * linear_damp
	get_node("../Rayi").target_position = Vector3()
	for i in [0, 1, 2]:
		velocity += dir[i] * transform.basis[i]
		if dir[i]:
			get_node("../Rayi").target_position -= dir[i]/abs(dir[i]) * transform.basis[i]
	get_node("../Ray").target_position = -velocity.normalized()
	velocity /= 1 + linear_damp * delta
	rotation_velocity /= 1 + angular_damp * delta
	for i in [0, 1, 2]:
		if rotation_velocity[i]:
			dir = Vector3()
			dir[i] += 1
			rotate(dir, rotation_velocity[i] * delta)
	move_and_slide()
