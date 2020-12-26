extends MarginContainer
onready var lobby_bird_resource = preload('res://src/Players/LobbyBird.tscn')
### Append & pop by LobbyBirds
### onready var all_lobby_birds = []


func _ready():
	# Server.request_lobby_entry_sync()
	get_node("VBoxContainer/HBoxContainer/RoomID").text += str(Globals.room_id)
	Server.connect('add_team_player', self, '_add_team_player')
	Server.connect('change_team_of_player_sig', self, 'change_player_team')
	# if already got players info, start aligning. else, register for a signal
	if Globals.teams_players:
		init_lobby_players()
	else:
		Server.connect('init_teams_players', self, 'init_lobby_players')


func init_lobby_players():
	for team_name in Globals.teams_players:
		var players_in_team = Globals.teams_players[team_name]
		for player_id in players_in_team:
			add_player_to_lobby(team_name, player_id, players_in_team[player_id]['player_name'])


func add_player_to_lobby(team_name, player_id, player_name):
	var lobby_bird = lobby_bird_resource.instance()
	lobby_bird.player_id = player_id
	lobby_bird.name = str(player_id)
	lobby_bird.get_node("VBoxContainer/PlayerName").text = player_name
	find_node(team_name, true, false).get_node('BirdsContainer').add_child(lobby_bird, true)


func _add_team_player(team_name, player_id, player_attributes):
	# wrapper for add_player_to_lobby to catch the Server.gd signal
	add_player_to_lobby(team_name, player_id, player_attributes['player_name'])


func remove_player_from_lobby(player_id):
	### call on disconnection
	print_tree_pretty()
	print(player_id)
	print(str(player_id))
	find_node(str(player_id), true, false).queue_free()


func change_player_team(_old_team_name, new_team_name, player_id):
	remove_player_from_lobby(player_id)
	var player_name = Globals.teams_players[new_team_name][player_id]['player_name']
	add_player_to_lobby(new_team_name, player_id, player_name)


#func add_birds_to_teams(teams_to_players_dict):
#	"""
#	Add birds to lobby in the relevant teams
#	:params: teams_to_players_dict. 
#		e.g: 
#		{'Team1': ['Dave', 'Ben', ...], 'Team2': ['Daniel', ...], 'Unassigned': [...]}	
#	"""
#	for team_name in teams_to_players_dict.keys():
#		for player_name in teams_to_players_dict[team_name]:
#			pass


"""
func move_lobby_bird(bird_name, new_team):
	if bird_name == Globals.player_name:
		Globals.player_team = new_team
	# O(2N) - may by improved by deleting by index
	for bird in all_lobby_birds:
		if bird.bird_name == bird_name:
			all_lobby_birds.erase(bird)
			bird.queue_free()
			break

	add_birds_to_teams({new_team: [bird_name]})
"""


func _on_StartGame_pressed():
	Server.request_start_game()
	SceneHandler.handle_scene_change('StartGame')

