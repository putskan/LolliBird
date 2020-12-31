extends Label
var opacity = 1

func _ready():
	set_physics_process(false)


func _physics_process(_delta):
	# fade out text
	fade_out_process()


func fade_out_process():
	opacity -= 0.015
	set_modulate(Color(1, 1, 1, opacity))
	if opacity == 0:
		queue_free()
