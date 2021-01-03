extends KinematicBody2D

const MAX_SPEED = 700
const SPEED = 17
const FRICTION = 1.1

var motion = Vector2()
signal collided_with_another_player(other_player_id)


func _ready():
	set_physics_process(false)

func _physics_process(_delta):
	_movement_loop()
	_send_player_state()

func _movement_loop():
	if Input.is_action_pressed("ui_up"):
		motion.y -= SPEED
		if motion.y > 0:
			motion.y = motion.y / FRICTION
			
	elif Input.is_action_pressed("ui_down"):
		motion.y += SPEED
		if motion.y < 0:
			motion.y = motion.y / FRICTION
		
	else:
		motion.y = motion.y / FRICTION
	
	
	if Input.is_action_pressed("ui_right") and not $AnimatedSprite.flip_h:
		motion.x = min(motion.x + SPEED, MAX_SPEED)


	elif Input.is_action_pressed("ui_left") and $AnimatedSprite.flip_h:
			motion.x = max(motion.x - SPEED, -MAX_SPEED)
			
	else:
		motion.x = motion.x / FRICTION

	motion = move_and_slide(motion)


func _send_player_state():
	var player_state = {'T': OS.get_system_time_msecs(), 'P': get_global_position()}
	Server.send_player_state(player_state)


func _on_PlayersCollisionDetector_area_shape_entered(_area_id, area, _area_shape, _self_shape):
	# check who collided and act accordingly 
	if area.get_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT) or area.get_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT):
		var other_player_id = int(area.get_parent().name)
		emit_signal('collided_with_another_player', other_player_id)

	elif area.get_collision_layer_bit(Globals.END_OF_MAP_COLLISION_BIT):
		Server.notify_player_reached_eom()
		set_physics_process(false)
		



