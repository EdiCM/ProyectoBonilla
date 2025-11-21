extends CharacterBody3D

const SPEED = 2.0

var target = null
var path = null
var path_finder : PathFinder = null

@onready var hitbox = $HitboxArea

func _ready():
	
	self.set_physics_process(false)
	
	hitbox.body_entered.connect(on_hit_player)
	path_finder = PathFinder.new(get_parent(), 1)
	
	var timer = Timer.new()
	timer.wait_time = 1
	add_child(timer)
	timer.timeout.connect(find_path_timer)
	timer.start()
	
	
	

func _physics_process(delta):
	if target == null:
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
	
	
func set_target(target):
	self.target = target
	self.set_physics_process(true)
	find_path_timer()
	
	
func on_hit_player(body):
	if body.name == "Player":
		body.die()
		$Whisper.stop()
		$Growl.play()
		
	
func find_path_timer():
	if target == null or path_finder == null:
		return
		
	path = path_finder.find_path(global_position, target.global_position)
	if path != null and path.size() > 0:
		path.remove_at(0)
