extends MarginContainer

var scoreboard_player_label_name_pattern = 'ScoreboardLabel-%d'
onready var start_round_button_node = find_node('StartRoundButton', true, false)
onready var map_node = find_node('Map', true, false)
onready var ui_round_number_node = get_node("VBoxContainer/UIPane/Control/RoundNumber")
onready var ui_scoreboard_nodes = {
									'Team1': get_node("VBoxContainer/UIPane/Team1/Scoreboard"),
									'Team2': get_node("VBoxContainer/UIPane/Team2/Scoreboard")
								}

signal game_round_start
signal game_round_finish

func _ready():
	if Globals.is_host:
		start_round_button_node.disabled = false
	else:
		start_round_button_node.disabled = true
	Server.connect('round_start', self, '_on_round_start')
	Server.connect('round_finish', self, '_on_round_finish')
	Server.connect('game_finish', self, '_on_game_finish')
	Server.connect('player_caught', self, '_on_player_caught')
	map_node.connect('player_caught', self, '_on_player_caught')

	ui_init_players_scoreboard()
	ui_update_round_number()
	ui_update_catchers_team()


func _on_StartRoundButton_pressed():
	start_round_button_node.disabled = true
	Server.request_round_start()


func _on_round_start():
	emit_signal('game_round_start')


func _on_round_finish():
	if Globals.round_number < Globals.total_rounds:
		# make sure not to exceed
		change_catchers_team()
		ui_update_catchers_team()
		Globals.round_number += 1
		ui_update_round_number()
	
	if Globals.is_host:
		start_round_button_node.disabled = false
	
	emit_signal('game_round_finish')


func change_catchers_team():
	if Globals.catchers_team == 'Team1':
		Globals.catchers_team = 'Team2'
	else:
		Globals.catchers_team = 'Team1'


func ui_update_catchers_team():
	get_node("VBoxContainer/UIPane/Control/RoundCatcher").text = 'Catcher: %s' % Globals.catchers_team


func _on_player_caught(catcher_pid, runner_pid):
	if runner_pid == Globals.player_id:
		# received from map scene (becuase own player was eliminated)
		Server.multicast_player_caught(catcher_pid, runner_pid)
		
	else:
		var runner_node = map_node.find_node(str(runner_pid), true, false)
		map_node.eliminate_player(runner_node)

	handle_capture_data(catcher_pid, runner_pid)


func handle_capture_data(catcher_pid, runner_pid):
	save_capture_data(catcher_pid, runner_pid)
	ui_save_capture_data(catcher_pid, runner_pid)


func save_capture_data(catcher_pid, runner_pid):
	if not Globals.captures.has(catcher_pid):
		Globals.captures[catcher_pid] = [runner_pid]
	else:
		Globals.captures[catcher_pid].append(runner_pid)


func ui_save_capture_data(catcher_pid, runner_pid):
	for scoreboard_parent in ui_scoreboard_nodes.values():
		for player_label in scoreboard_parent.get_children():
			if player_label.name == scoreboard_player_label_name_pattern % catcher_pid:
				# increment by 1
				var splitted_label_text = player_label.text.split(': ')
				player_label.text = splitted_label_text[0] + ': %d' % (int(splitted_label_text[1]) + 1)
				
			elif player_label.name == scoreboard_player_label_name_pattern % runner_pid:
				var splitted_label_text = player_label.text.split(': ')
				player_label.text = splitted_label_text[0] + ': 0'


func ui_init_players_scoreboard():
	for team_name in Globals.teams_players:
		if team_name != 'Unassigned':
			var parent_node = ui_scoreboard_nodes[team_name]
			for pid in Globals.teams_players[team_name]:
				var player_name = Globals.teams_players[team_name][pid]['player_name']
				var player_label = Label.new()
				player_label.name = scoreboard_player_label_name_pattern % pid
				player_label.text = '%s: 0' % player_name
				parent_node.add_child(player_label)


func ui_update_round_number():
	ui_round_number_node.text = 'Round: %d/%d' % [Globals.round_number, Globals.total_rounds]


func _on_game_finish(winning_team):
	start_round_button_node.disabled = true
	var game_over_pop_up = get_node('GameOverPopup')
	game_over_pop_up.get_node("GameOverText").text = '%s won!' % winning_team
	game_over_pop_up.popup()
	print('Client: %s won' % winning_team)
	
