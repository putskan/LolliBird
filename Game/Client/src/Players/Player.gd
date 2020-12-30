extends KinematicBody2D

var motion = Vector2()
signal collided_with_another_player(other_player_id)


func _ready():
	set_physics_process(false)

func _physics_process(_delta):
	_movement_loop()
	_send_player_state()

func _movement_loop():
	if Input.is_action_pressed("ui_up"):
		motion.y -= 5
	
	elif Input.is_action_pressed("ui_down"):
		motion.y += 5
		
	else:
		motion.y = motion.y / 1.1	
	
	# should be get_scale.x -> there seems to be a bug in Godot.
	if Input.is_action_pressed("ui_right") and get_scale().y > 0:
		motion.x += 5

	elif Input.is_action_pressed("ui_left") and get_scale().y < 0:
			motion.x -= 5

	else:
		# slow down
		motion.x = motion.x / 1.1

	motion = move_and_slide(motion)


func _send_player_state():
	var player_state = {'T': OS.get_system_time_msecs(), 'P': get_global_position()}
	Server.send_player_state(player_state)


func _on_PlayersCollisionDetector_area_shape_entered(_area_id, area, _area_shape, _self_shape):
	# check who collided and act accordingly 
	print('colliding')
	if area.get_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT) or area.get_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT):
		print('a')
		var other_player_id = int(area.get_parent().name)
		emit_signal('collided_with_another_player', other_player_id)

	elif area.get_collision_layer_bit(Globals.END_OF_MAP_COLLISION_BIT):
		Server.notify_player_reached_eom()
		set_physics_process(false)
		



