extends MarginContainer

onready var start_round_button_node = find_node('StartRoundButton', true, false)
signal game_round_start
signal game_round_finish

func _ready():
	if Globals.is_host:
		start_round_button_node.disabled = false
	else:
		start_round_button_node.disabled = true
	Server.connect('round_start', self, '_on_round_start')
	Server.connect('round_finish', self, '_on_round_finish')


func _on_StartRoundButton_pressed():
	start_round_button_node.disabled = true
	Server.request_round_start()


func _on_round_start():
	emit_signal('game_round_start')


# for later ################################
func _on_round_finish():
	if Globals.is_host:
		start_round_button_node.disabled = false
	else:
		# add - waiting for host to start round
		pass
	emit_signal('game_round_finish')
