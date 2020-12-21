extends MarginContainer
onready var lobby_bird_resource = preload('res://src/Players/LobbyBird.tscn')

# Called when the node enters the scene tree for the first time.
func _ready():
	Server.request_lobby_entry_sync()
	
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

