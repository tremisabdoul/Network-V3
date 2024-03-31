extends CharacterBody3D

const XZ_FORCE = 14.
const Y_FORCE = 1.
const JUMP_FORCE = 10.
const GRAVITY = .75

var dir: Vector2 = Vector2()
var boost: float = 1.
var hp: float = 100.

func _input(event):
	if event is InputEventMouseMotion:
		$Compensation/Head.rotation.x -= event.relative.y * 0.003
		#rotation_remaining -= event.relative.x * 0.003*1000
		rotate(Vector3.UP, -event.relative.x*0.003)

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_window().mode = Window.MODE_FULLSCREEN

func _enter_tree():
	get_parent().call_deferred("remove_child", get_node("../Meshes"))

func _physics_process(delta):
	rotation -= Vector3(dir.y, 0, dir.x)
	$Compensation.rotation += Vector3(dir.y, 0, dir.x)
	
	rotation += Vector3(0, rotation.y, 0) * delta * 10
	rotation /= 1+ delta*10
	
	dir += Input.get_vector("right", "left", "forward", "backward").normalized() * delta * 4
	dir += Vector2() * delta * 16
	dir /= 1 + delta * 4 + delta * 16
	
	rotation += Vector3(dir.y, 0, dir.x)
	$Compensation.rotation -= Vector3(dir.y, 0, dir.x)
	
	if $RayCast3D.is_colliding():
		var y_mult = (1-($RayCast3D.get_collision_point() - position).length() / $RayCast3D.target_position.length())*.5+.5
		if Input.is_action_pressed("boost"):
			y_mult *= 1+boost*JUMP_FORCE
			boost = 0.
			#hit(1, Vector3.FORWARD)
		if Input.is_action_just_pressed("shoot"):
			hit(100, Vector3.FORWARD)
		velocity += ($RayCast3D.get_collision_normal()*.01 + transform.basis.y*.99) * Vector3(0, 1, 0) * y_mult * Y_FORCE
	
	velocity += ($RayCast3D.get_collision_normal()*.01 + transform.basis.y*.99) * XZ_FORCE * Vector3(1, 0, 1)

	#$Compensation/Head/Camera3D/Camera2D/Precision.scale = Vector2.ONE * (1-boost) * 32
	boost = min(boost+delta, 1)
	velocity.y -= GRAVITY
	move_and_slide()
	velocity.x += 0*delta*32
	velocity.x /= 1+delta*32
	velocity.z += 0*delta*32
	velocity.z /= 1+delta*32
	velocity.y += 0*delta*2
	velocity.y /= 1+delta*2


func hit(damages: float, dir: Vector3):
	velocity.y += damages/5
	rotate(dir.cross(Vector3.UP), -damages/200)
	hp -= damages
	if hp <= 0:
		var body = RigidBody3D.new()
		body.transform = transform
		body.linear_velocity = dir * damages/5 + Vector3.UP * damages/100
		body.angular_velocity = -body.linear_velocity / 10
		body.mass = 60
		body.angular_damp = 10
		for e in $Meshes.get_children():
			body.add_child(e.duplicate())
		body.add_child($CollisionShape3D.duplicate())
		#var camera = $Compensation/Head/Camera3D
		#$Compensation/Head.remove_child(camera)
		#body.add_child(camera)
		#collision_mask = 0b0
		#collision_layer = 0b0
		get_parent().add_child(body)
		#process_mode = PROCESS_MODE_DISABLED
		#visible = false
