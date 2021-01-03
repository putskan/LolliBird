extends Control

var player_aligner_res = preload('res://src/Players/GamePlayerContainer.tscn')
var dummy_bird_res = preload('res://src/Players/DummyPlayer.tscn')
var player_bird_res = preload('res://src/Players/Player.tscn')
var client_player_node
# last time server sent players states
var latest_players_states_timestamp = null
# used for interpolation purposes
# structure: [state_to_interpolate_from, state_to_interpolate_to, future_state1, future_state2...]
var players_states_buffer = []
var players_ids_to_nodes = {}
var name_labels = []
onready var countdown_video_node = get_node('CountdownVideo')
signal player_caught(catcher_pid, runner_pid)


func _ready():
	set_process(false)
	init_all_players()
	Server.connect('player_disconnect', self, '_on_player_disconnect')
	Server.connect('receive_players_states', self, 'update_all_players_states')
	yield(get_tree(),"idle_frame")
	var game_node = get_tree().get_current_scene()
	game_node.connect('game_round_start', self, '_on_game_round_start')
	game_node.connect('game_round_finish', self, '_on_game_round_finish')


func _process(_delta):
	# used for off-tab browser sync purposes
	# if another client started the game, stop the countdown and start game as well
	if latest_players_states_timestamp:
		print(latest_players_states_timestamp)
		_on_CountdownVideo_finished()
		set_process(false)
		#set_physics_process(false)


func _physics_process(_delta):
	"""
	handle players states and interpolation
	"""
	# time of the frame to render
	var render_time = OS.get_system_time_msecs() - Globals.INTERPOLATION_OFFSET
	if players_states_buffer.size() > 1:
		while players_states_buffer.size() > 2 and render_time > players_states_buffer[1].T:
			# pop states we've already fully interpolated from (remove old states)
			players_states_buffer.remove(0)
		# a float between 0-1 indicating how close we are to the newer state (percentage)
		var interpolation_factor = float(render_time - players_states_buffer[0]['T']) / float(players_states_buffer[1]['T'] - players_states_buffer[0]['T'])
		for pid in players_states_buffer[1]:
			if str(pid) == 'T':
				continue
			if pid == Globals.player_id:
				continue
			# make sure exist in both states
			if not players_states_buffer[0].has(pid):
				continue
			var player_node = get_player_node_by_id(pid)
			# if not eliminated
			if player_node:
				var new_pos = lerp(players_states_buffer[0][pid]['P'], players_states_buffer[1][pid]['P'], interpolation_factor)
				player_node.set_global_position(new_pos)


func _on_player_disconnect(player_id):
	# clear player node. the container will be flushed in the next round.
	var player_node = get_player_node_by_id(player_id)
	if player_node:
		player_node.queue_free()
		players_ids_to_nodes.erase(player_id)


func _on_game_round_start():
	print('Map: Received Signal')
	countdown_video_node.visible = true
	countdown_video_node.play()
	set_process(true)


func _on_game_round_finish():
	init_all_players()


func _on_CountdownVideo_finished():
	# finished animation. can now hide it and start round!
	countdown_video_node.visible = false
	if client_player_node:
		# i.e., not a spectator
		client_player_node.set_physics_process(true)
		
	# hide name labels
	for label in name_labels:
		label.set_physics_process(true)
	name_labels = []


func init_all_players():
	# init players which are not captives
	clear_map_players()
	var captives = []
	for captives_list in Globals.captures.values():
		captives += captives_list
	
	for team_name in Globals.teams_players.keys():
		if team_name != 'Unassigned':
			for player_id in Globals.teams_players[team_name]:
				if not player_id in captives:
					var player_name = Globals.teams_players[team_name][player_id]['player_name']
					init_map_player(team_name, player_id, player_name)


func init_map_player(team_name, player_id, player_name):
	var player_node = create_player_node(team_name, player_id)
	# for reduction of complexity in other functions (e.g., update_all_players_states)
	players_ids_to_nodes[player_id] = player_node
	var aligner_node = align_player_node(player_node, team_name)
	add_player_name_label(aligner_node, player_name, player_id)


func clear_map_players():
	latest_players_states_timestamp = null
	for team_name in ['Team1', 'Team2']:
		var team_players_container = get_node("%sPlayers" % team_name)
		for player_container in team_players_container.get_children():
			player_container.queue_free()
		
	players_ids_to_nodes = {}



func create_player_node(team_name, player_id):
	var player_node
	if player_id == Globals.player_id:
		player_node = player_bird_res.instance()
		client_player_node = player_node
		player_node.connect('collided_with_another_player', self, 'handle_players_collision')

	else:
		player_node = dummy_bird_res.instance()
		
	player_node.get_node("AnimatedSprite").play(team_name)
	player_node.name = str(player_id)
	player_node = set_player_collision(player_node, team_name)
	return player_node


func get_player_node_by_id(player_id):
	if players_ids_to_nodes.has(player_id):
		return players_ids_to_nodes[player_id]
	return null


func set_player_collision(player_node, team_name):
	# collide and slide with own team, detect collision with the other team.
	var team_layer_bit
	var other_team_layer_bit
	if team_name == Globals.catchers_team:
		print('cathcer')
		team_layer_bit = Globals.CATCHERS_COLLISION_BIT
		other_team_layer_bit = Globals.RUNNERS_COLLISION_BIT
		
	else:
		print('runner')
		team_layer_bit = Globals.RUNNERS_COLLISION_BIT
		other_team_layer_bit = Globals.CATCHERS_COLLISION_BIT


	player_node.set_collision_layer_bit(team_layer_bit, true)
	player_node.set_collision_mask_bit(team_layer_bit, true)
	
	var collision_detector = player_node.get_node('PlayersCollisionDetector')
	collision_detector.set_collision_layer_bit(team_layer_bit, true)
	collision_detector.set_collision_mask_bit(other_team_layer_bit, true)
	collision_detector.set_collision_mask_bit(Globals.END_OF_MAP_COLLISION_BIT, true)
	return player_node


func align_player_node(player_node, team_name):
	# align player and return its aligner node
	var player_aligner = player_aligner_res.instance()
	player_aligner.get_node("VBoxContainer/CenterContainer/PlayerParent").add_child(player_node)
	get_node("%sPlayers" % team_name).add_child(player_aligner)
	if team_name == 'Team2':
		player_node.get_node('AnimatedSprite').flip_h = true
	
	return player_aligner


func add_player_name_label(aligner_node, player_name, player_id):
	var name_label_node = aligner_node.get_node('VBoxContainer/PlayerName')
	name_label_node.text = player_name
	if player_id == Globals.player_id:
		name_label_node.add_color_override("font_color", Color(0, 0.5, 0.5))
		
	name_labels.append(name_label_node)


func update_all_players_states(players_states):
	# update states, so they could be used for players positioning and interpolation
	if players_states.size() <= 1:
		return
	
	if latest_players_states_timestamp == null or players_states['T'] > latest_players_states_timestamp:
		# new data received
		latest_players_states_timestamp = players_states['T']
		players_states_buffer.append(players_states)


func handle_players_collision(other_player_id):
	if is_own_player_catcher():
		print('handle_players_collision')
		emit_signal('player_caught', Globals.player_id, other_player_id)
		eliminate_player(players_ids_to_nodes[other_player_id])
	else:
		emit_signal('player_caught', other_player_id, Globals.player_id)
		eliminate_player(client_player_node)


func is_own_player_catcher():
	# return true if the client is a catcher, false otherwise
	return Globals.catchers_team == Globals.player_team


func eliminate_player(eliminated_player_node):
	if eliminated_player_node:
		var pid = int(eliminated_player_node.name)
		players_ids_to_nodes.erase(pid)
		eliminated_player_node.queue_free()
