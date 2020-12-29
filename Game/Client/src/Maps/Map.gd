extends Control

var dummy_bird_res = preload('res://src/Players/DummyPlayer.tscn')
var player_bird_res = preload('res://src/Players/Player.tscn')
var client_player_node
var PLAYER_POSITION_OFFSET = 20
# last time server sent players states
var latest_players_states_timestamp = null
var players_ids_to_nodes = {}
onready var map_height = null
onready var countdown_video_node = get_node('CountdownVideo')
signal player_caught(catcher_pid, runner_pid)


"""
func _ready():
	# request birds list
	#########  Server.request_team_names_to_players_names()
	# fetch response
	Server.connect('response_received_team_names_to_players_names', self, 'align_birds_in_map')


func align_birds_in_map(teams_to_players):
	# get birds from server and insert to map
	# :dict teams_to_players: {'Team1': ['Dave', 'Ben', ...], 'Team2': [...]}
	for team_name in teams_to_players.keys():
		if team_name != 'Unassigned':
			for player_name in teams_to_players[team_name]:
				init_bird(team_name, player_name)


func init_bird(team_name, player_name):
	var bird_aligner = Control.new()
	var bird_node
	if player_name == Globals.player_name:
		bird_node = player_bird_res.instance()
		# make bird distinguishable
		bird_node.set_modulate(Color(248, 0, 0))
	else: 
		# not the player itself.
		bird_node = dummy_bird_res.instance()


	bird_aligner.add_child(bird_node)
	get_node("Floor/%sPlayers" % team_name).add_child(bird_aligner)
	
	if team_name == 'Team1':
		bird_node.position.x += 20
	
	elif team_name == 'Team2':
		# align to right
		bird_aligner.set_h_size_flags(8)
		bird_node.position.x -= 20
		# mirror bird
		bird_node.set_scale(Vector2(bird_node.scale.x * -1, bird_node.scale.y))
"""

func _ready():
	init_all_players()
	Server.connect('receive_players_states', self, 'update_all_players_states')
	yield(get_tree(),"idle_frame")
	var game_node = get_tree().get_current_scene()
	game_node.connect('game_round_start', self, '_on_game_round_start')

	
	# fetch response
	####Server.connect('response_received_team_names_to_players_names', self, 'align_birds_in_map')


func _on_game_round_start():
	# in the future: add countdown
	countdown_video_node.visible = true
	countdown_video_node.play()

	
func _on_CountdownVideo_finished():
	# finished animation. can now hide it and start round!
	countdown_video_node.visible = false
	client_player_node.set_physics_process(true)


func init_all_players():
	for team_name in Globals.teams_players.keys():
		if team_name != 'Unassigned':
			for player_id in Globals.teams_players[team_name]:
				var player_name = Globals.teams_players[team_name][player_id]['player_name']
				init_map_player(team_name, player_id, player_name)


func init_map_player(team_name, player_id, player_name):
	var player_node = create_player_node(team_name, player_id, player_name)
	# for reduction of complexity in other functions (e.g., update_all_players_states)
	players_ids_to_nodes[player_id] = player_node
	align_player_node(player_node, team_name)


func create_player_node(team_name, player_id, player_name):
	var player_node
	if player_id == Globals.player_id:
		player_node = player_bird_res.instance()
		# make bird distinguishable
		player_node.set_modulate(Color(248, 0, 0))
		client_player_node = player_node
		player_node.connect('collided_with_another_player', self, 'handle_players_collision')

	else:
		player_node = dummy_bird_res.instance()
	
	player_node.name = str(player_id)
	player_node = set_player_collision(player_node, team_name)
	return player_node


func set_player_collision(player_node, team_name):
	# collide and slide with own team, detect collision with the other team.
	var team_layer_bit
	var other_team_layer_bit
	if team_name == Globals.catchers_team:
		team_layer_bit = 2
		other_team_layer_bit = 3
	else:
		team_layer_bit = 3
		other_team_layer_bit = 2

	player_node.set_collision_layer_bit(team_layer_bit, true)
	player_node.set_collision_mask_bit(team_layer_bit, true)
	
	var collision_detector = player_node.get_node('PlayersCollisionDetector')
	collision_detector.set_collision_layer_bit(team_layer_bit, true)
	collision_detector.set_collision_mask_bit(other_team_layer_bit, true)
	return player_node


func align_player_node(player_node, team_name):
	var player_aligner = Control.new()
	player_aligner.add_child(player_node)
	get_node("%sPlayers" % team_name).add_child(player_aligner)
	
	if team_name == 'Team1':
		player_node.position.x += PLAYER_POSITION_OFFSET
	
	elif team_name == 'Team2':
		# align to right
		player_node.position.x -= PLAYER_POSITION_OFFSET
		player_aligner.set_h_size_flags(8)
		# mirror player, so it flips sides
		player_node.set_scale(Vector2(player_node.scale.x * -1, player_node.scale.y))


func update_all_players_states(players_states):
	if latest_players_states_timestamp == null or players_states['T'] > latest_players_states_timestamp:
		# new data received
		latest_players_states_timestamp = players_states['T']
		players_states.erase('T')
		players_states.erase(Globals.player_id)
		for player_id in players_states:
			if players_ids_to_nodes.has(player_id):
				# if not eliminated
				var new_position = players_states[player_id]['P']
				players_ids_to_nodes[player_id].set_global_position(new_position)


func handle_players_collision(other_player_id):
	if is_player_caught_on_collision():
		# notify own player was eliminated by another
		emit_signal('player_caught', other_player_id, Globals.player_id)
		eliminate_player(client_player_node)
		### update details, send to server, hide player, etc. ###
		pass


func is_player_caught_on_collision():
	# called on collision with another player
	# check if the player was caught by one of the other team's players
	return Globals.catchers_team != Globals.player_team


func eliminate_player(eliminated_player_node):
	var pid = int(eliminated_player_node.name)
	players_ids_to_nodes.erase(pid)
	eliminated_player_node.queue_free()

