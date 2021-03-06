extends MarginContainer
onready var lobby_bird_resource = preload('res://src/Players/LobbyBird.tscn')
onready var start_game_button = get_node("VBoxContainer/HBoxContainer/StartGame")

func _ready():
	if Globals.is_host:
		start_game_button.disabled = false

	else:
		start_game_button.disabled = true
		
	get_node("VBoxContainer/HBoxContainer/RoomID").text += str(Globals.room_id)
	Server.connect('player_disconnect', self, 'remove_player_from_lobby')
	Server.connect('assign_as_room_host', self, '_on_assign_as_room_host')
	Server.connect('add_team_player', self, '_add_team_player')
	Server.connect('change_team_of_player_sig', self, 'change_player_team')
	Server.connect('start_game', self, 'start_game')
	Server.connect('receive_response_start_game', self, '_on_receive_response_start_game')
	# if already got players info, start aligning. else, register for a signal
	if Globals.teams_players:
		init_lobby_players()
	else:
		Server.connect('init_teams_players', self, 'init_lobby_players')


func _on_assign_as_room_host():
	start_game_button.disabled = false


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
	lobby_bird.get_node("VBoxContainer/CenterContainer/Control/LobbyBirdKinematic/AnimatedSprite").play(team_name)
	find_node(team_name, true, false).get_node('BirdsContainer').add_child(lobby_bird, true)


func _add_team_player(team_name, player_id, player_attributes):
	# wrapper for add_player_to_lobby to catch the Server.gd signal
	add_player_to_lobby(team_name, player_id, player_attributes['player_name'])


func remove_player_from_lobby(player_id):
	find_node(str(player_id), true, false).queue_free()


func change_player_team(_old_team_name, new_team_name, player_id):
	remove_player_from_lobby(player_id)
	var player_name = Globals.teams_players[new_team_name][player_id]['player_name']
	add_player_to_lobby(new_team_name, player_id, player_name)


func is_team_full(team_node):
	var max_players = Globals.TEAMS_MAX_PLAYERS[team_node.name]
	var players_count = team_node.get_node('BirdsContainer').get_child_count()
	return players_count >= max_players


func _on_StartGame_pressed():
	Server.request_start_game()
	start_game_button.disabled = true

func _on_receive_response_start_game(error_msg):
	if error_msg:
		start_game_button.disabled = false

func start_game():
	SceneHandler.handle_scene_change('StartGameScene')

