extends CharacterBody3D


const SPEED = 5.0
const JUMP_VELOCITY = 8.
const GRAVITY = 24.

func _input(event):
	if event is InputEventMouseMotion:
		$Head.rotation.x -= event.relative.y * 0.003
		rotation.y -= event.relative.x * 0.003

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_window().mode = Window.MODE_FULLSCREEN

func _physics_process(delta):
	var dir = Input.get_vector("left", "right", "forward", "backward")
	dir = ((transform.basis * Vector3(dir.x, 0, dir.y))*(Vector3(1, 0, 1))).normalized()
	
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
		var vn = (velocity*Vector3(1, 0, 1)).normalized()
		velocity += vn * min(vn.dot(dir), 0) * SPEED * delta
		var v = dir * (1-abs(vn.dot(dir))) * SPEED * delta * 30
	
		velocity -= v.length() * vn
		velocity += v
	else:
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		if Input.is_action_pressed("jump"):
			velocity.y = JUMP_VELOCITY
	#print((velocity*Vector3(1, 0, 1)).length())

	move_and_slide()
