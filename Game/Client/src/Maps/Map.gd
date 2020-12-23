extends Control

var bird_res = preload('res://src/Players/Player.tscn')
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
				init_bird(team_name)


func init_bird(team):
	var bird_aligner = Control.new()
	var bird_node = bird_res.instance()
	bird_aligner.add_child(bird_node)
	get_node("Floor/%sPlayers" % team).add_child(bird_aligner)
	
	if team == 'Team1':
		bird_node.position.x += 20
	
	elif team == 'Team2':
		# align to right
		bird_aligner.set_h_size_flags(8)
		bird_node.position.x -= 20
		# mirror bird
		bird_node.set_scale(Vector2(bird_node.scale.x * -1, bird_node.scale.y))


