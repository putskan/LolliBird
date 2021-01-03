extends Node2D

var round_number = 1
var total_rounds = 6
var host_id
var host_name
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
var players_left_in_round = []
var has_game_started = false

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


func is_player_in_room(player_id):
	return player_ids.has(player_id)


func is_player_in_round(player_id):
	return players_left_in_round.has(player_id)


func remove_player(player_id):
	# delete player from everywhere
	player_ids.erase(player_id)
	if player_ids.empty():
		close_room()
		return
	
	if player_id == host_id:
		host_id = player_ids[0]
		host_name = get_name_by_id(player_ids[0])
		Server.assign_new_room_host(host_id)
		Server.multicast_host_name(self)
	
	players_left_in_round.erase(player_id)
	player_state_collection.erase(player_id)
	captures.erase(player_id)
	for capturer in captures:
		captures[capturer].erase(player_id)
		
	# remove from teams_players
	for team in teams_players:
		var players_in_team = teams_players[team]
		if players_in_team.has(player_id):
			players_in_team.erase(player_id)


func get_name_by_id(player_id):
	print(teams_players)
	for team_name in teams_players:
		if teams_players[team_name].has(player_id):
			return teams_players[team_name][player_id]['player_name']


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
	round_number += 1
	player_state_collection = {}
	set_physics_process(false)
	Server.multicast_round_finish(self)
	var check_finish_data = check_game_finish()
	if check_finish_data[0]:
		game_finish(check_finish_data[1])


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

	if round_number > total_rounds:
		var team_1_players_left = players_number['Team1'] - captures_number['Team2']
		var team_2_players_left = players_number['Team2'] - captures_number['Team1']
		if team_1_players_left > team_2_players_left:
			return [true, 'Team1']
			
		elif team_1_players_left < team_2_players_left:
			return [true, 'Team2']
			
		else:
			return [true, 'Draw']
			
	else:
		# check if a team fully eliminated the other one
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


func game_finish(winning_team):
	Server.multicast_game_finish(winning_team, self)
	prepare_for_rematch()


func prepare_for_rematch():
	round_number = 1
	player_state_collection = {}
	teams_players = {'Team1': {}, 'Team2': {}, 'Unassigned': {}}
	player_ids = []
	captures = {}
	players_left_in_round = []
	has_game_started = false
