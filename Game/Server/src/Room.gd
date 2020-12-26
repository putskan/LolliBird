extends Node2D

# var current_round = 1
# var total_rounds = 5

# the room's creator
var host_id
# format: {player_id: {'T': timestamp, 'P': position}, player_id: {...}}
var player_state_collection = {}

"""
teams_players = {
	'Team1': 
		{
			player_id1: {'player_name': player_name, 'otherkey': othervalue}, 
			player_id2: {'player_name': player_name, 'otherkey': othervalue},
		}
	'Team2': 
		{
			player_id1: {'player_name': player_name, 'otherkey': othervalue}, 
			player_id2: {'player_name': player_name, 'otherkey': othervalue},
		}
	'Unassigned':
		{
			player_id1: {'player_name': player_name, 'otherkey': othervalue}, 
			player_id2: {'player_name': player_name, 'otherkey': othervalue},
		}
}
"""

var teams_players = {'Team1': {}, 'Team2': {}, 'Unassigned': {}}
var player_ids = []
# add to client side as well
# get_team_names_to_player_names - convert to something else
# bird lobby sync - change to signals
# remove player on client side from all scenes on disconnect, using signal (e.g., from lobby)
# dict erase - make sure not running through the dict when trying to remove

func _ready():
	# change to true when game starts
	set_physics_process(false)


func _physics_process(delta):
	# 20 fps
	# remove player timestamp, change pids to players names, add server timestamp
	# changing pids to player_names because client knows only names.
	var player_state_to_client = {}
	for pid in player_state_collection:
		var state = player_state_collection[pid].duplicate().erase('T')
		player_state_to_client[find_node(str(pid), true, false).player_name] = state
	player_state_to_client['T'] = OS.get_system_time_msecs()
	Server.multicast_players_states(int(self.name), player_state_to_client)


func update_player_state(player_id, player_state):
	# update a player's state on the server
	if not player_state_collection.has(player_id):
		player_state_collection[player_id] = player_state
		
	elif player_state_collection[player_id]['T'] < player_state['T']:
		# update only if received timestamp is newer than the existing one
		player_state_collection[player_id] = player_state


func is_player_name_exists(player_name):
	for team_players_dict in teams_players.values():
		for player in team_players_dict:
			if team_players_dict[player]['player_name'] == player_name:
				return true
	return false


func add_player(player_attributes_dict, team):
	# player_attributes_dict: {player_id: {'player_name': name, ...}}
	for player_id in player_attributes_dict:
		teams_players[team][player_id] = player_attributes_dict[player_id]
		player_ids.append(player_id)


func get_player_ids(excluded_pid=null):
	if excluded_pid:
		var player_ids_dup = player_ids.duplicate()
		player_ids_dup.erase(excluded_pid)
		return player_ids_dup
		
	return player_ids


func update_player_team(player_id, team_name):
	for team in teams_players:
		var players_in_team = teams_players[team]
		if players_in_team.has(player_id):
			var player_attributes = players_in_team[player_id]
			players_in_team.erase(player_id)
			teams_players[team_name][player_id] = player_attributes
			return true
			
	push_error('Room %s: Player %d update failed - player not found!' % [self.name, player_id])
	return false


func remove_player(player_id):
	# remove player from ids, states, teams
	# assign new host if needed
	# close room if needed
	# return: false if player not found, true if deleted, null if room closed
	if not player_ids.has(player_id):
		return false
		
	player_ids.erase(player_id)
	if player_ids.empty():
		close_room()
		return

	player_state_collection.erase(player_id)
	if player_id == host_id:
		host_id = player_ids[0]
		Server.assign_new_room_host(host_id)
	
	# remove from teams_players
	for team in teams_players:
		var players_in_team = teams_players[team]
		if players_in_team.has(player_id):
			players_in_team.erase(player_id)
			return true
	
	push_error('Room %s: Player %d removal - found in ids, not in teams!' % [self.name, player_id])


func close_room():
	Globals.running_rooms_ids.erase(int(self.name))
	queue_free()

