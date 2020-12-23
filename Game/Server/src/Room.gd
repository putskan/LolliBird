extends Node2D

var room_id
var current_round = 1
var total_rounds = 5
# the room's creator
var host_id

# for easy, non-tree access
var room_player_ids = []
#var room_teams_to_players_names = {
#	'Team1': [],
#	'Team2': [],
#	'Unassigned': []
#}
