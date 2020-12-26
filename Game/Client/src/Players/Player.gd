extends KinematicBody2D

var motion = Vector2()

# Called when the node enters the scene tree for the first time.
func _physics_process(delta):
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
	
