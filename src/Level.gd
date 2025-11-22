extends Node3D
@onready var monster = $GridMap/Monster
@onready var monster2 = $GridMap/Monster2
@onready var player = $GridMap/Player
@onready var orb_container = $GridMap/OrbContainer
@onready var life_pickup_container = $GridMap/LifePickupContainer  # ← NUEVO
@onready var victory_zone = $VictoryZone

var collected_orbs = 0
var total_orb_count = 0
var collected_lives = 0 
var total_life_pickups = 0 

func _ready():
	await get_tree().process_frame
	
	if monster != null and player != null:
		monster.set_target(player)
	
	if monster2 != null and player != null:
		monster2.set_target(player)
	
	total_orb_count = orb_container.get_child_count()
	
	if life_pickup_container:
		total_life_pickups = life_pickup_container.get_child_count()
	
	player.orb_collected.connect(on_orb_collected)
	player.life_collected.connect(on_life_collected) 
	
	# Conectar la zona de victoria
	if victory_zone:
		victory_zone.player_won.connect(on_player_won)
	
	
	
func on_orb_collected():
	collected_orbs += 1
	print("Orbes recolectadas: ", collected_orbs, "/", total_orb_count)
	
	# Si recolectó todas las orbes, ganar
	if collected_orbs >= total_orb_count:
		print("¡Todas las orbes recolectadas! ¡VICTORIA!")
		on_player_won()

func on_life_collected():
	collected_lives += 1
	print("¡Vida recolectada! Total recogidas: ", collected_lives, "/", total_life_pickups)

func on_player_won():
	print("on_player_won() llamada - Cambiando a VictoryScreen...")
	get_tree().change_scene_to_file("res://src/VictoryScreen.tscn")
