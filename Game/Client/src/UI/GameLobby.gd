extends MarginContainer
onready var lobby_bird_resource = preload('res://src/Players/LobbyBird.tscn')
# Append & pop by LobbyBirds
onready var all_lobby_birds = []

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.request_lobby_entry_sync()
	get_node("VBoxContainer/HBoxContainer/RoomID").text += str(Globals.room_id)


func add_birds_to_teams(teams_to_players_dict):
	"""
	Add birds to lobby in the relevant teams
	:params: teams_to_players_dict. 
		e.g: 
		{'Team1': ['Dave', 'Ben', ...], 'Team2': ['Daniel', ...], 'Unassigned': [...]}	
	"""
	for team_name in teams_to_players_dict.keys():
		for player_name in teams_to_players_dict[team_name]:
			var lobby_bird = lobby_bird_resource.instance()
			lobby_bird.get_node("VBoxContainer/PlayerName").text = str(player_name)
			find_node(team_name, true, false).get_node('BirdsContainer').add_child(lobby_bird)


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



func _on_StartGame_pressed():
	Server.request_start_game()
	SceneHandler.handle_scene_change('StartGame')

