extends CanvasLayer

@onready var continue_button = $CenterContainer/ContinueButton

func _ready():
	# Forzar que el mouse esté visible
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	continue_button.pressed.connect(on_continue_pressed)

func on_continue_pressed():
	get_tree().change_scene_to_file("res://src/menu_components/MainMenu.tscn")
