extends MarginContainer

onready var start_round_button_node = find_node('StartRoundButton', true, false)
onready var map_node = find_node('Map', true, false)
signal game_round_start
signal game_round_finish

func _ready():
	if Globals.is_host:
		start_round_button_node.disabled = false
	else:
		start_round_button_node.disabled = true
	Server.connect('round_start', self, '_on_round_start')
	Server.connect('round_finish', self, '_on_round_finish')
	map_node.connect('player_caught', self, '_on_player_caught')
	Server.connect('player_caught', self, '_on_player_caught')


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
############################################


func _on_player_caught(catcher_pid, runner_pid):
	print('_on_player_caught')
	if runner_pid == Globals.player_id:
		print('if1')
		# received from map scene (becuase own player was eliminated)
		Server.multicast_player_caught(catcher_pid, runner_pid)
		
	else:
		print('else')
		var runner_node = map_node.find_node(str(runner_pid), true, false)
		map_node.eliminate_player(runner_node)
		
	### update UI, relevant variables, etc ###
	print('Game.tscn: player caught!')
	pass
	
