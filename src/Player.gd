extends CharacterBody3D

const GRAVITY = -24.8
const MAX_SPEED = 7
const SPRINT_SPEED = 16  # Velocidad al correr
var is_sprinting = false
var can_sprint = true
var sprint_duration = 0.5  # Duración del sprint en segundos
var sprint_cooldown = 5.0  # Tiempo de espera para volver a hacer sprint
const ACCEL = 3.5

@onready var collider = $Collider
@onready var camera = $CameraPivot/Camera3D
@onready var footsteps = $Footsteps
@onready var fader = $Fader
@onready var health_label = $CanvasLayer/HealthLabel
@onready var grab_warning_label = $CanvasLayer/GrabWarningLabel
@onready var orb_count_label = $CanvasLayer/OrbCountLabel

signal orb_collected
signal player_died
signal health_changed
signal life_collected


var dir = Vector3()
var collected_orbs = 0
var total_orbs = 10  # Total de orbes en el nivel
var shake_amount = 0.01
var is_dying = false

# Sistema de vidas
var max_health = 3
var current_health = 3
var is_invulnerable = false
var invulnerability_time = 1.0

# Sistema de agarre del monstruo
var is_grabbed = false
var grab_escape_count = 0
var grab_escape_required = 10  # Clicks necesarios para escapar
var grab_damage_timer = 0.0
var grab_damage_interval = 2.5  # Daño cada 2.5 segundos

const DEACCEL = 16
const MAX_SLOPE_ANGLE = 40

var rotation_helper
var walking = false

var MOUSE_SENSITIVITY = 0.05

func _ready():
	rotation_helper = $CameraPivot
	collider.area_entered.connect(on_area_entered)
	fader.fade_finished.connect(on_fade_finished)
	
	# Inicializar vidas
	current_health = max_health
	update_health_ui()
	
	# Inicializar contador de orbes
	update_orb_ui()
	
	emit_signal("health_changed", current_health)
	
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func update_health_ui():
	if health_label:
		# Mostrar corazones
		var hearts = ""
		for i in range(current_health):
			hearts += "❤️ "
		
		# Si no tiene vidas, mostrar mensaje
		if current_health <= 0:
			health_label.text = "💀 Sin vidas"
		else:
			health_label.text = hearts

func update_orb_ui():
	if orb_count_label:
		orb_count_label.text = "Orbs: " + str(collected_orbs) + "/" + str(total_orbs)

func handle_grabbed_state(delta):
	# Detener movimiento
	velocity = Vector3.ZERO
	
	# Aumentar el timer de daño
	grab_damage_timer += delta
	
	# Causar daño cada X segundos
	if grab_damage_timer >= grab_damage_interval:
		grab_damage_timer = 0.0
		take_damage(1)
	
	# Detectar clicks rápidos en SPACE para escapar
	if Input.is_action_just_pressed("ui_accept"):  # SPACE
		grab_escape_count += 1
		
		# Actualizar mensaje con progreso
		grab_warning_label.text = "Press SPACE rapidly to escape or die! (" + str(grab_escape_count) + "/" + str(grab_escape_required) + ")"
		
		# Si presionó suficiente, escapar
		if grab_escape_count >= grab_escape_required:
			escape_from_grab()

func get_grabbed():
	# Llamada por el monstruo cuando atrapa al jugador
	if is_grabbed or is_dying:
		return
	
	is_grabbed = true
	grab_escape_count = 0
	grab_damage_timer = 0.0
	
	# Mostrar mensaje de advertencia
	grab_warning_label.visible = true
	grab_warning_label.text = "Press SPACE rapidly to escape or die! (0/" + str(grab_escape_required) + ")"

func escape_from_grab():
	is_grabbed = false
	grab_escape_count = 0
	grab_damage_timer = 0.0
	
	# Ocultar mensaje
	grab_warning_label.visible = false
	
	# Hacer invulnerable temporalmente al escapar
	is_invulnerable = true
	await get_tree().create_timer(1.5).timeout
	is_invulnerable = false

func _physics_process(delta):
	
	if is_dying:
		shake_amount += 0.02 * delta
		camera.h_offset = randf_range(-1, 1) * shake_amount
		camera.v_offset = randf_range(-1, 1) * shake_amount
		return
	
	# Si está agarrado por el monstruo
	if is_grabbed:
		handle_grabbed_state(delta)
		return
	
	process_input(delta)
	process_movement(delta)
	

func process_input(delta):
	# Caminar
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
	if Input.is_action_just_pressed("ui_shift") and can_sprint and not is_sprinting:
		activate_sprint()
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			toggle_pause()
		
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
	
	# Capturing/Freeing el cursor
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
	var current_speed = SPRINT_SPEED if is_sprinting else MAX_SPEED
	target *= current_speed
	
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
	floor_snap_length = 0.2  # Ayuda a no trabarse en bordes
	
	move_and_slide()

func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation_helper.rotate_x(deg_to_rad(event.relative.y * MOUSE_SENSITIVITY * -1))
		self.rotate_y(deg_to_rad(event.relative.x * MOUSE_SENSITIVITY * -1))
		
		var camera_rot = rotation_helper.rotation_degrees
		camera_rot.x = clamp(camera_rot.x, -90, 90)
		rotation_helper.rotation_degrees = camera_rot
		

func die():
	if is_dying:
		return
		
	is_dying = true
	current_health = 0
	
	# Liberar el mouse antes de morir
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	emit_signal("player_died")
	fader.set_playback_speed(0.15)
	fader.fade_out()

func take_damage(amount = 1):
	# Si ya está muriendo o es invulnerable, no hacer nada
	if is_dying or is_invulnerable:
		return
	
	# Restar vida
	current_health -= amount
	update_health_ui()
	emit_signal("health_changed", current_health)
	
	# Si todavía tiene vidas, activar invulnerabilidad temporal
	if current_health > 0:
		is_invulnerable = true
		
		# Hace que la pantalla tiemble más fuerte
		var original_fov = camera.fov
		camera.fov = 80  # Zoom out momentáneo
		
		# Timer para quitar invulnerabilidad
		await get_tree().create_timer(invulnerability_time).timeout
		is_invulnerable = false
		camera.fov = original_fov  # Restaurar FOV
	else:
		# Sin vidas, morir
		die()

func add_life():
	if current_health < max_health:
		current_health += 1
	else:
		# Si ya tiene vidas máximas, igual dar feedback
		current_health += 1  # Permitir sobrepasar el máximo
	
	update_health_ui()
	emit_signal("life_collected")
	emit_signal("health_changed", current_health)
	print("¡Vida extra! Vidas actuales: ", current_health)

func on_area_entered(area):
	if area.is_in_group("Orb"):
		# Activar partículas si existen
		var particles = area.get_node_or_null("CollectParticles")
		if particles:
			# Desparentar las partículas para que no se eliminen con la orbe
			area.remove_child(particles)
			get_parent().add_child(particles)
			particles.global_position = area.global_position
			particles.emitting = true
			# Eliminar las partículas después de que terminen
			await get_tree().create_timer(particles.lifetime).timeout
			particles.queue_free()
		
		area.queue_free()
		collected_orbs += 1
		update_orb_ui()
		emit_signal("orb_collected")
	
	# Detectar pickups de vida
	elif area.is_in_group("LifePickup"):
		area.queue_free()
		add_life()

func on_fade_finished():
	get_tree().change_scene_to_file("res://src/GameOverScreen.tscn")

func toggle_pause():
	if get_tree().paused:
		return
	
	print("PAUSANDO JUEGO")
	
	# Forza cursor visible antes de pausar
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Pequeña pausa para que el input system procese el cambio
	await get_tree().process_frame
	get_tree().paused = true
	
	# Instanciar el menú de pausa
	var pause_menu = load("res://src/PauseMenu.tscn").instantiate()
	pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(pause_menu)
	
	print("MENÚ CREADO")

func activate_sprint():
	if not can_sprint or is_grabbed or is_dying:
		return
	
	is_sprinting = true
	can_sprint = false
	
	print("Sprint activado!")
	
	# Duración del sprint
	await get_tree().create_timer(sprint_duration).timeout
	is_sprinting = false
	
	print("Sprint terminado, esperando cooldown...")
	
	# Cooldown
	await get_tree().create_timer(sprint_cooldown).timeout
	can_sprint = true
	
	print("Sprint disponible de nuevo!")
