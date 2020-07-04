extends KinematicBody

onready var camera = $Pivot/Camera

const MOTION_SPEED = 8

puppet var puppet_transform
puppet var puppet_motion = Vector3()
var motion = Vector3()

var random_number_generator = RandomNumberGenerator.new()

export var speed = 100
export var acceleration = 5
export var gravity = 0.98
export var jump_power = 30
export var mouse_sensitivity = 0.003

var last_motion
var last_transform

onready var knight = $knight
var last_anim = 'idle'


func _ready():
	$HUD/Panel.hide()
	$HUD/Players.hide()
	if is_network_master():
		camera.current = true
		set_color()
	puppet_transform = transform
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func set_color():
	var material = $Model.get_surface_material(0)
	random_number_generator.randomize()
	var r = random_number_generator.randf_range(0.0, 1.0)
	random_number_generator.randomize()
	var g = random_number_generator.randf_range(0.0, 1.0)
	random_number_generator.randomize()
	var b = random_number_generator.randf_range(0.0, 1.0)
	var color = Vector3(r, g, b).normalized()
	material.albedo_color = Color(color.x, color.y, color.z, 1.0)


func _unhandled_input(event):
	var mouse_motion = event is InputEventMouseMotion
	var mouse_captured = Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if event.is_action_pressed("shoot"):
		if !mouse_captured:
			$HUD/Panel.hide()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	if event.is_action_pressed("ui_cancel"):
		if mouse_captured:
			release_mouse()
			$HUD/Panel.show()
	if mouse_motion and mouse_captured:
		rotate_y(-event.relative.x * mouse_sensitivity)
		$Pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		$Pivot.rotation.x = clamp($Pivot.rotation.x, -0.8, 0.4)


func _physics_process(delta):
	motion.x = 0
	motion.z = 0
	
	var camera_basis = camera.global_transform.basis
	var direction = Vector3()
	
	if is_network_master():
		if Input.is_action_pressed("move_forward"):
			direction -= camera_basis.z
			if direction.y != 0:
				direction.y = 0
		if Input.is_action_pressed("move_back"):
			direction += camera_basis.z
			if direction.y != 0:
				direction.y = 0
		if Input.is_action_pressed("strafe_left"):
			direction -= camera_basis.x
		if Input.is_action_pressed("strafe_right"):
			direction += camera_basis.x
		
		direction = direction.normalized()
		
		motion = motion.linear_interpolate(direction * speed, acceleration * delta)
		motion.y -= gravity
		
		if Input.is_action_just_pressed("jump") and is_on_floor():
			motion.y = jump_power
		
		var anim = 'idle'
		
		if motion.x != 0 or motion.z != 0:
			anim = "walk"
		else:
			anim = "idle"
		
		play_anim(anim)
		if last_anim != anim:
			rpc('play_anim', anim)
		last_anim = anim
		if last_motion != motion:
			rset("puppet_motion", motion)
		if last_transform != transform:
			rset("puppet_transform", transform)
		
		last_motion = motion
		last_transform = transform
		
	else:
		transform = puppet_transform
		motion = puppet_motion
		
	move_and_slide(motion, Vector3.UP, true)
	if not is_network_master():
		puppet_transform = transform


func set_player_name(player):
	$Name/Viewport/GUI/Player.text = player


func _on_cancel_button_pressed():
	$HUD/Panel.hide()
	release_mouse()


func capture_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func release_mouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_quit_button_pressed():
	get_tree().set_network_peer(null)
	network.end_game()


func update_list():
	$HUD/Players/List.clear()
	for player in network.players:
		$HUD/Players/List.add_item(network.players[player])


func _process(delta):
	handle_input()


func handle_input():
	if Input.is_action_just_pressed("tab"):
		update_list()
		$HUD/Players.show()
	if Input.is_action_just_released("tab"):
		$HUD/Players.hide()


puppet func play_anim(anim):
	knight.play_anim(anim)
