extends SpotLight3D

var timer = null

func _ready():
	timer = Timer.new()
	timer.wait_time = randf_range(0.05, 0.1)
	add_child(timer)
	timer.timeout.connect(_on_timer_timeout)
	timer.start()
	
func _on_timer_timeout():
	timer.wait_time = randf_range(0.05, 0.1)
	light_energy = randf_range(0.0, 1.0)
