extends CharacterBody3D

const GRAVITY = -24.8
const MAX_SPEED = 7
const ACCEL = 3.5

@onready var collider = $Collider
@onready var camera = $CameraPivot/Camera3D
@onready var footsteps = $Footsteps
@onready var fader = $Fader

signal orb_collected

var dir = Vector3()
var collected_orbs = 0
var shake_amount = 0.01
var is_dying = false

const DEACCEL = 16
const MAX_SLOPE_ANGLE = 40

var rotation_helper
var walking = false

var MOUSE_SENSITIVITY = 0.05

func _ready():
	rotation_helper = $CameraPivot
	collider.area_entered.connect(on_area_entered)
	fader.fade_finished.connect(on_fade_finished)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _physics_process(delta):
	
	if is_dying:
		shake_amount += 0.02 * delta
		camera.h_offset = randf_range(-1, 1) * shake_amount
		camera.v_offset = randf_range(-1, 1) * shake_amount
		return
	
	process_input(delta)
	process_movement(delta)
	

func process_input(delta):
	# Walking
	dir = Vector3()
	var cam_xform = camera.get_global_transform()
	
	var input_movement_vector = Vector2()
	
	if Input.is_action_pressed("movement_forward"):
		input_movement_vector.y += 1
	if Input.is_action_pressed("movement_backward"):
		input_movement_vector.y -= 1
	if Input.is_action_pressed("movement_left"):
		input_movement_vector.x -= 1
	if Input.is_action_pressed("movement_right"):
		input_movement_vector.x += 1
	if Input.is_action_just_pressed("toggle_flashlight"):
		$CameraPivot/SpotLight3D.visible = not $CameraPivot/SpotLight3D.visible
		
	input_movement_vector = input_movement_vector.normalized()
	
	if input_movement_vector.x != 0 or input_movement_vector.y != 0:
		walking = true
	else:
		walking = false
		
	if walking and !footsteps.playing:
		footsteps.play()
	if not walking and footsteps.playing:
		footsteps.stop()
	
	dir += -cam_xform.basis.z.normalized() * input_movement_vector.y
	dir += cam_xform.basis.x.normalized() * input_movement_vector.x
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_VISIBLE:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func process_movement(delta):
	dir.y = 0
	dir = dir.normalized()
	
	# Aplicar gravedad solo si no está en el suelo
	if not is_on_floor():
		velocity.y += delta * GRAVITY
	else:
		if velocity.y < 0:
			velocity.y = 0
	
	var hvel = velocity
	hvel.y = 0
	
	var target = dir
	target *= MAX_SPEED
	
	var accel
	if dir.dot(hvel) > 0:
		accel = ACCEL
	else:
		accel = DEACCEL
	
	hvel = hvel.lerp(target, accel * delta)
	velocity.x = hvel.x
	velocity.z = hvel.z
	
	# Configurar propiedades antes de move_and_slide
	up_direction = Vector3(0, 1, 0)
	floor_max_angle = deg_to_rad(MAX_SLOPE_ANGLE)
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -90, 90)
		rotation_helper.rotation_degrees = camera_rot
		
	
func die():
	is_dying = true
	fader.set_playback_speed(0.15)
	fader.fade_out()
	

func on_area_entered(area):
	if area.is_in_group("Orb"):
		area.queue_free()
		emit_signal("orb_collected")
	
	
func on_fade_finished():
	get_tree().change_scene_to_file("res://src/menu_components/MainMenu.tscn")
