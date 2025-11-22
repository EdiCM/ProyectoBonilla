extends CanvasLayer

var resume_button
var quit_button

func _ready():
	for child in get_all_children(self):
		if child is Button:
			if "Resume" in child.text or "Continuar" in child.text:
				resume_button = child
			elif "Quit" in child.text or "Salir" in child.text:
				quit_button = child
	
	if resume_button:
		resume_button.pressed.connect(_on_resume_pressed)
	
	if quit_button:
		quit_button.pressed.connect(_on_quit_pressed)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func get_all_children(node: Node) -> Array:
	var children = []
	for child in node.get_children():
		children.append(child)
		children.append_array(get_all_children(child))
	return children

func _on_resume_pressed():
	resume_game()

func _on_quit_pressed():
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	queue_free()
	get_tree().change_scene_to_file("res://src/menu_components/MainMenu.tscn")

func resume_game():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().paused = false
	queue_free()
