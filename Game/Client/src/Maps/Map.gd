extends Control

var dummy_bird_res = preload('res://src/Players/DummyPlayer.tscn')
var player_bird_res = preload('res://src/Players/Player.tscn')
onready var floor_node = get_node("Floor")
onready var map_height = null


func _ready():
	# request birds list
	Server.request_team_names_to_players_names()
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


func update_all_players_states(s_players_states):
	# :dict players_states: {'T': timestamp, playername1: {'P': position}, playername2: {...} ...}
	print(s_players_states)
	
