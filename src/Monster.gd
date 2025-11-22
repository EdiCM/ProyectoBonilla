extends CharacterBody3D

const SPEED = 4.0

var target = null
var path = null
var path_finder : PathFinder = null
var path_timer : Timer = null

@onready var hitbox = $HitboxArea

func _ready():
	self.set_physics_process(false)
	
	hitbox.body_entered.connect(on_hit_player)
	
	await get_tree().process_frame
	
	var parent = get_parent()
	if parent != null:
		path_finder = PathFinder.new(parent, 1)
	
	path_timer = Timer.new()
	path_timer.wait_time = 1
	add_child(path_timer)
	path_timer.timeout.connect(find_path_timer)
	path_timer.start()
	
	

func _physics_process(delta):
	if target == null:
		return
	
	if not is_instance_valid(target):
		print("ERROR: Target is not valid")
		return
		
	self.look_at(target.global_position, Vector3.UP)
	
	if path != null and path.size() > 0:
		move_along_path(path)

		
	
func move_along_path(path):
	if global_position.distance_to(path[0]) < 0.1:
		path.remove_at(0)
		if path.size() == 0:
			return
	
	var direction = (path[0] - global_position).normalized()
	velocity = direction * SPEED
	move_and_slide()
	
	
func set_target(new_target):
	if new_target == null:
		print("ERROR: Trying to set null target")
		return
		
	self.target = new_target
	print("Target set to: ", target.name)
	self.set_physics_process(true)
	find_path_timer()
	
	
func on_hit_player(body):
	if body.name == "Player":
		# Intentar agarrar al jugador en lugar de solo hacer daño
		if body.has_method("get_grabbed"):
			body.get_grabbed()
		$Whisper.stop()
		$Growl.play()
		
	
func find_path_timer():
	# Si el target es null o inválido, detener el timer
	if target == null or not is_instance_valid(target) or path_finder == null:
		if path_timer:
			path_timer.stop()
		return
		
	path = path_finder.find_path(global_position, target.global_position)
	
	if path != null and path.size() > 0:
		path.remove_at(0)
