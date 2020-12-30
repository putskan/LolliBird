extends Node2D

# var current_round = 1
# var total_rounds = 5

var host_id
# format: {player_id: {'T': timestamp, 'P': position}, player_id: {...}}
var player_state_collection = {}

"""
teams_players = {
	'Team1': {player_id1: {'player_name': player_name, 'otherkey': othervalue}, ...}
	'Team2': {player_id1: {'player_name': player_name, 'otherkey': othervalue}, ...}
	'Unassigned': {player_id1: {'player_name': player_name, 'otherkey': othervalue}, ...}
}
"""
var teams_players = {'Team1': {}, 'Team2': {}, 'Unassigned': {}}
var player_ids = []
var captures = {}
## remove captives and init every round##
var players_left_in_round


func _ready():
	# change to true when game starts
	set_physics_process(false)


func _physics_process(_delta):
	# runs 20 times per second
	handle_players_states_distribution()
	## Add check if finished round/collision/etc.


func handle_players_states_distribution():
	# clean & multicast players states
	var players_states = prepare_players_states()
	var room_id = int(self.name)
	Server.multicast_players_states(room_id, players_states)


func prepare_players_states():
	# clean the players states for the client (remove clients' & add own timestamp)
	var players_states_to_client = {}
	for pid in player_state_collection:
		var state = player_state_collection[pid].duplicate()
		state.erase('T')
		players_states_to_client[pid] = state
	players_states_to_client['T'] = OS.get_system_time_msecs()
	return players_states_to_client


func update_player_state(player_id, player_state):
	# update a player's state on the server (only on new timestamps)
	# called on update from a client
	if not player_state_collection.has(player_id):
		player_state_collection[player_id] = player_state
		
	elif player_state_collection[player_id]['T'] < player_state['T']:
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


func round_start():
	set_physics_process(true)
	# init list of players left, so we could know when every1 finished
	players_left_in_round = player_ids.duplicate()
	for captives_ids in captures.values():
		for captive_id in captives_ids:
			players_left_in_round.erase(captive_id)


func on_player_caught(catcher_pid, runner_pid):
	# handle player finishing round, update catch info
	on_player_finished_round(runner_pid)
	update_catch_info(catcher_pid, runner_pid)


func update_catch_info(catcher_pid, runner_pid):
	# update new captives and release ones if needed
	if captures.has(catcher_pid):
		captures[catcher_pid].append(runner_pid)
	else:
		captures[catcher_pid] = [runner_pid]
	captures.erase(runner_pid)


func on_player_finished_round(pid):
	players_left_in_round.erase(pid)
	if players_left_in_round.empty():
		round_finish()


func round_finish():
	print('Round finished!')
	set_physics_process(false)
	Server.multicast_round_finish(self)
	var check_finish_data = check_game_finish()
	if check_finish_data[0]:
		Server.multicast_game_finish(check_finish_data[1], self)
		print('Game Over! %s Has Won!' % check_finish_data[1])
	else:
		print('Game aint over until its over!')
	

func check_game_finish():
	# return [true, winning_team] if game finished, [false, null] otherwise
	var players_number = {'Team1': 0, 'Team2': 0}
	var captures_number = {'Team1': 0, 'Team2': 0}
	for team_name in teams_players:
		if team_name in ['Team1', 'Team2']:
			for pid in teams_players[team_name]:
				players_number[team_name] += 1
				if captures.has(pid):
					captures_number[team_name] += captures[pid].size()
	
	if captures_number['Team1'] == players_number['Team2']:
		return [true, 'Team1']
	
	if captures_number['Team2'] == players_number['Team1']:
		return [true, 'Team2']

	return [false, null]


func get_captives():
	# return a list of all captives pids
	var all_captives = []
	for captive_list in captures.values():
		all_captives += captive_list
	return all_captives
