extends Control

var dummy_bird_res = preload('res://src/Players/DummyPlayer.tscn')
var player_bird_res = preload('res://src/Players/Player.tscn')
var client_player_node
var PLAYER_POSITION_OFFSET = 20
# last time server sent players states
var latest_players_states_timestamp = null
var players_ids_to_nodes = {}
onready var countdown_video_node = get_node('CountdownVideo')
signal player_caught(catcher_pid, runner_pid)


func _ready():
	init_all_players()
	Server.connect('receive_players_states', self, 'update_all_players_states')
	yield(get_tree(),"idle_frame")
	var game_node = get_tree().get_current_scene()
	game_node.connect('game_round_start', self, '_on_game_round_start')
	game_node.connect('game_round_finish', self, '_on_game_round_finish')


func _on_game_round_start():
	# in the future: add countdown
	countdown_video_node.visible = true
	countdown_video_node.play()

func _on_game_round_finish():
	init_all_players()


func _on_CountdownVideo_finished():
	# finished animation. can now hide it and start round!
	countdown_video_node.visible = false
	client_player_node.set_physics_process(true)


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


func init_map_player(team_name, player_id, _player_name):
	var player_node = create_player_node(team_name, player_id)
	# for reduction of complexity in other functions (e.g., update_all_players_states)
	players_ids_to_nodes[player_id] = player_node
	align_player_node(player_node, team_name)


func clear_map_players():
	for player_node in players_ids_to_nodes.values():
		player_node.queue_free()
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
		emit_signal('player_caught', other_player_id, Globals.player_id)
		eliminate_player(client_player_node)


func is_player_caught_on_collision():
	# called on collision with another player
	# check if the player was caught by one of the other team's players
	return Globals.catchers_team != Globals.player_team


func eliminate_player(eliminated_player_node):
	var pid = int(eliminated_player_node.name)
	players_ids_to_nodes.erase(pid)
	eliminated_player_node.queue_free()
