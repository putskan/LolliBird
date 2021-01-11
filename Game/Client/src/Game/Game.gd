extends MarginContainer

var scoreboard_player_label_name_pattern = 'ScoreboardLabel-%d'
var game_state = 'idle'
onready var start_game_button_node = find_node('StartGameButton', true, false)
onready var map_node = find_node('Map', true, false)
onready var ui_round_number_node = get_node("VBoxContainer/UIPane/Control/RoundNumber")
onready var ui_scoreboard_nodes = {
									'Team1': get_node("VBoxContainer/UIPane/Team1/Scoreboard"),
									'Team2': get_node("VBoxContainer/UIPane/Team2/Scoreboard")
								}

signal game_round_start
signal game_round_finish

func _ready():
	Audio.play_music('game')
	Server.start_clock_sync()
	if Globals.first_round_start:
		# make sure map scene has loaded and connected to game signals
		yield(get_tree(),"idle_frame")
		yield(get_tree(),"idle_frame")
		round_start()
		
	if Globals.is_host:
		start_game_button_node.disabled = false
		
	else:
		start_game_button_node.disabled = true
		
	Server.connect('player_disconnect', self, '_on_player_disconnect')
	Server.connect('assign_as_room_host', self, '_on_assign_as_room_host')
	Server.connect('round_start', self, 'round_start')
	Server.connect('round_finish', self, '_on_round_finish')
	Server.connect('game_finish', self, '_on_game_finish')
	Server.connect('player_caught', self, '_on_player_caught_remotely')
	map_node.connect('player_caught', self, '_on_player_caught_locally')

	ui_init_players_scoreboard()
	ui_update_round_number()
	ui_update_catchers_team()


func _on_player_disconnect(player_id):
	# free from ui and data structures
	var capturer = remove_player_from_captures_data(player_id)
	ui_remove_player_from_scoreboard(player_id)
	if capturer:
		ui_scoreboard_decrement_score(capturer)


func _on_assign_as_room_host():
	if game_state == 'idle':
		start_game_button_node.disabled = false
		

func _on_StartGameButton_pressed():
	start_game_button_node.disabled = true
	Server.request_round_start()


func round_start():
	game_state = 'active'
	emit_signal('game_round_start')


func _on_round_finish():
	game_state = 'idle'
	if Globals.round_number < Globals.total_rounds:
		# make sure not to exceed
		change_catchers_team()
		ui_update_catchers_team()
		Globals.round_number += 1
		ui_update_round_number()
	
	emit_signal('game_round_finish')
	round_start()


func change_catchers_team():
	if Globals.catchers_team == 'Team1':
		Globals.catchers_team = 'Team2'
	else:
		Globals.catchers_team = 'Team1'


func ui_update_catchers_team():
	get_node("VBoxContainer/UIPane/Control/RoundCatcher").text = 'Catcher: %s' % Globals.catchers_team


func _on_player_caught_locally(catcher_pid, runner_pid):
	Server.multicast_player_caught(catcher_pid, runner_pid)
	handle_capture_data(catcher_pid, runner_pid)


func _on_player_caught_remotely(catcher_pid, runner_pid):
	var runner_node = map_node.get_player_node_by_id(runner_pid)
	if runner_node:
		# if not eliminated locally already
		map_node.eliminate_player(runner_node)
		handle_capture_data(catcher_pid, runner_pid)


func handle_capture_data(catcher_pid, runner_pid):
	save_capture_data(catcher_pid, runner_pid)
	ui_scoreboard_save_capture(catcher_pid, runner_pid)


func save_capture_data(catcher_pid, runner_pid):
	# capture
	if not Globals.captures.has(catcher_pid):
		Globals.captures[catcher_pid] = [runner_pid]
	else:
		Globals.captures[catcher_pid].append(runner_pid)
	# release
	Globals.captures.erase(runner_pid)


func get_player_scoreboard_label(player_id):
	# return the label of a player in the scoreboard
	for scoreboard_parent in ui_scoreboard_nodes.values():
		for player_label in scoreboard_parent.get_children():
			if player_label.name == scoreboard_player_label_name_pattern % player_id:
				return player_label


func ui_scoreboard_save_capture(catcher_pid, runner_pid):
	# increment the catcher's score by 1, init the runner's to zero.
	var catcher_label = get_player_scoreboard_label(catcher_pid)
	var runner_label = get_player_scoreboard_label(runner_pid)
	# catcher:
	var catcher_splitted_label_text = catcher_label.text.split(': ')
	catcher_label.text = catcher_splitted_label_text[0] + ': %d' % (int(catcher_splitted_label_text[1]) + 1)
	# runner:
	var runner_splitted_label_text = runner_label.text.split(': ')
	runner_label.text = runner_splitted_label_text[0] + ': 0'


func ui_init_players_scoreboard():
	for team_name in Globals.teams_players:
		if team_name != 'Unassigned':
			var parent_node = ui_scoreboard_nodes[team_name]
			for pid in Globals.teams_players[team_name]:
				var player_name = Globals.teams_players[team_name][pid]['player_name']
				var player_label = Label.new()
				var new_dyn_font = Globals.small_dynamic_font_res
				player_label.add_font_override("font", new_dyn_font)
				player_label.name = scoreboard_player_label_name_pattern % pid
				player_label.text = '%s: 0' % player_name
				parent_node.add_child(player_label)


func remove_player_from_captures_data(player_id):
	# on disconnect, remove player, both as a captive and as capturer
	# return the player's capturer if exists, null otherwise
	Globals.captures.erase(player_id)
	for capturer in Globals.captures:
		if Globals.captures[capturer].has(player_id):
			Globals.captures[capturer].erase(player_id)
			return capturer
			
	return null 


func ui_remove_player_from_scoreboard(player_id):
	var player_scoreboard_label = get_player_scoreboard_label(player_id)
	if player_scoreboard_label:
		player_scoreboard_label.queue_free()


func ui_scoreboard_decrement_score(player_id):
	var player_scoreboard_label = get_player_scoreboard_label(player_id)
	var splitted_label_text = player_scoreboard_label.text.split(': ')
	player_scoreboard_label.text = splitted_label_text[0] + ': %d' % (int(splitted_label_text[1]) - 1)


func ui_update_round_number():
	ui_round_number_node.text = 'Round: %d/%d' % [Globals.round_number, Globals.total_rounds]


func _on_game_finish(winning_team):
	start_game_button_node.disabled = true
	Globals.team_won = winning_team
	SceneHandler.handle_scene_change('GameOver')

