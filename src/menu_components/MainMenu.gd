extends Node3D

@onready var start_button = $CanvasLayer/Fader/Control/VBoxContainer/CenterContainer/VBoxContainer/StartButton
@onready var quit_button = $CanvasLayer/Fader/Control/VBoxContainer/CenterContainer/VBoxContainer/QuitButton
@onready var fader = $CanvasLayer/Fader
@onready var animation_player = $AnimationPlayer

@export var game_scene: PackedScene = null

func _ready():
	# Liberar el mouse al entrar al menú
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	start_button.pressed.connect(on_start_pressed)
	quit_button.pressed.connect(on_quit_pressed)
	fader.fade_finished.connect(on_fade_finished)

func on_start_pressed():
	fader.fade_out()
	animation_player.play("fade_out")

func on_quit_pressed():
	get_tree().quit()

func on_fade_finished():
	get_tree().change_scene_to_packed(game_scene)
