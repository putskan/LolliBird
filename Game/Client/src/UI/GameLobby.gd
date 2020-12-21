extends MarginContainer
onready var lobby_bird_resource = preload('res://src/Players/LobbyBird.tscn')

# Called when the node enters the scene tree for the first time.
func _ready():
	add_bird_to_team(Globals.player_name, Globals.player_team)


func add_bird_to_team(player_name, team_name):
	"""
	Add bird to lobby in the relevant team ('Team1', 'Team2', 'Unassigned').
	"""
	var lobby_bird = lobby_bird_resource.instance() 
	lobby_bird.get_node("VBoxContainer/PlayerName").text = player_name
	find_node(team_name, true, false).get_node('BirdsContainer').add_child(lobby_bird)
	
