extends Node2D

var room_id
var state = 'Lobby'
var current_round = 1
var total_rounds = 5
# the room's creator
var host_id

var room_player_ids = []
var room_teams_to_players = {
	'Team1': [],
	'Team2': [],
	'Unassigned': []
}
var room_teams_to_players_names = {
	'Team1': [],
	'Team2': [],
	'Unassigned': []
}
