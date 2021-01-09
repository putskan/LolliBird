extends Node2D

var player
var player_sprite
var motion = Vector2()

func _ready():
	set_physics_process(false)
	yield(get_tree(), "idle_frame")
	player = get_parent()
	player_sprite = player.get_node("AnimatedSprite")


func _physics_process(delta):
	motion.y += 3
	player.move_and_slide(motion)
	var rot_speed = rad2deg(10)
	player_sprite.set_rotation(player_sprite.get_rotation() + rot_speed * delta)
	if motion.y > 1000:
		player.queue_free()


func eliminate_player():
	player.set_physics_process(false)
	_remove_collision()
	_start_elimination_process()


func _remove_collision():
	var collision_detector = player.get_node('PlayersCollisionDetector')
	collision_detector.set_collision_layer_bit(Globals.MAP_COLLISION_BIT, false)
	collision_detector.set_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT, false)
	collision_detector.set_collision_layer_bit(Globals.RUNNERS_COLLISION_BIT, false)
	collision_detector.set_collision_layer_bit(Globals.END_OF_MAP_COLLISION_BIT, false)
	player.set_collision_layer_bit(Globals.MAP_COLLISION_BIT, false)
	player.set_collision_layer_bit(Globals.CATCHERS_COLLISION_BIT, false)
	player.set_collision_layer_bit(Globals.RUNNERS_COLLISION_BIT, false)
	player.set_collision_layer_bit(Globals.END_OF_MAP_COLLISION_BIT, false)
	collision_detector.set_collision_mask_bit(Globals.MAP_COLLISION_BIT, false)
	collision_detector.set_collision_mask_bit(Globals.CATCHERS_COLLISION_BIT, false)
	collision_detector.set_collision_mask_bit(Globals.RUNNERS_COLLISION_BIT, false)
	collision_detector.set_collision_mask_bit(Globals.END_OF_MAP_COLLISION_BIT, false)
	player.set_collision_mask_bit(Globals.MAP_COLLISION_BIT, false)
	player.set_collision_mask_bit(Globals.CATCHERS_COLLISION_BIT, false)
	player.set_collision_mask_bit(Globals.RUNNERS_COLLISION_BIT, false)
	player.set_collision_mask_bit(Globals.END_OF_MAP_COLLISION_BIT, false)


func _start_elimination_process():
	set_physics_process(true)


