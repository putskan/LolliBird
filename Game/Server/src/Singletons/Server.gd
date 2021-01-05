extends Node

const PORT = 11111
var network = WebSocketServer.new();
onready var root_node = get_tree().get_root()


func _ready():
	start_server()


func _process(_delta):
	if network.is_listening():
		# check for incoming connections
		network.poll()


func start_server():
	network.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(player_id):
	pass


func _peer_disconnected(player_id):
	for room_node in Globals.running_rooms_node.get_children():
		if room_node.is_player_in_room(player_id):
			room_node.remove_player(player_id)
			# if room not closed - notify room players of deletion
			if room_node:
				for pid in room_node.get_player_ids():
					rpc_id(pid, 'receive_player_disconnect', player_id)
			return


func assign_new_room_host(host_id):
	rpc_id(host_id, 'assign_as_room_host')


func multicast_host_name(room_node):
	for pid in room_node.get_player_ids():
		rpc_id(pid, 'receive_host_name', room_node.host_name)


remote func unicast_host_name(room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	rpc_id(get_tree().get_rpc_sender_id(), 'receive_host_name', room_node.host_name)


remote func is_room_join_valid(room_id):
	# check if there's an open room with "room_id" & not full
	# response with null if all good, error message otherwise
	var error_msg = null
	var room_node = HelperFunctions.get_room_node(room_id)
	if not room_id in Globals.running_rooms_ids:
		error_msg = 'Error: Wrong PIN Entered'
	
	elif room_node.player_ids.size() >= Globals.ROOM_MAX_PLAYERS:
		error_msg = 'Error: Room is full'
		
	elif room_node.has_game_started:
		error_msg = 'Error: Game already started'
		
	rpc_id(get_tree().get_rpc_sender_id(), 'response_room_id_join_validation', error_msg)


remote func create_room():
	var player_id = get_tree().get_rpc_sender_id()
	var room = HelperFunctions.create_room(player_id)
	rpc_id(player_id, 'response_room_creation', int(room.name))


remote func close_room(room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	if get_tree().get_rpc_sender_id() == room_node.host_id:
		room_node.close_room()


remote func create_player(player_name, player_team, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var error_message = HelperFunctions.create_player(get_tree().get_rpc_sender_id(), player_name, player_team, room_id)
	rpc_id(player_id, 'response_player_creation', error_message)
	if not error_message:
		# send all existing players to the new player
		rpc_id(player_id, 'init_teams_players', HelperFunctions.get_room_node(room_id).teams_players)
		# send an update of the new player to all other room players
		var room_node = HelperFunctions.get_room_node(room_id)
		var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
		for pid in pids:
			rpc_id(pid, 'add_team_player', player_team, player_id, {'player_name': player_name})


remote func multicast_change_team_of_player(old_team_name, new_team_name, player_id, room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	# update locally
	room_node.teams_players[new_team_name][player_id] = room_node.teams_players[old_team_name][player_id]
	room_node.teams_players[old_team_name].erase(player_id)
	# send to all room players
	var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_id(pid, 'change_team_of_player', old_team_name, new_team_name, player_id)


remote func start_game(room_id):
	# notify all other room players & start running
	var room_node = HelperFunctions.get_room_node(room_id)
	if room_node.teams_players['Team1'].size() >= 1 and room_node.teams_players['Team2'].size() >= 1:
		room_node.has_game_started = true
		var pids = room_node.get_player_ids()
		for pid in pids:
			rpc_id(pid, 'start_game')
	else:
		rpc_id(get_tree().get_rpc_sender_id(), 'response_start_game', 'Error: assign players to teams')


remote func receive_player_state(player_state, room_id):
	HelperFunctions.get_room_node(room_id).update_player_state(get_tree().get_rpc_sender_id(), player_state)


func multicast_players_states(room_id, players_states):
	# called from room
	var pids = HelperFunctions.get_room_node(room_id).get_player_ids()
	for pid in pids:
		rpc_unreliable_id(pid, 'receive_all_players_states', players_states)


remote func round_start(room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	room_node.round_start()
	var pids = room_node.get_player_ids()
	for pid in pids:
		rpc_id(pid, 'round_start')


remote func receive_player_caught(catcher_pid, runner_pid, room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	if room_node.is_player_in_round(runner_pid):
		# handle client sync issues
		var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
		for pid in pids:
			rpc_id(pid, 'receive_player_caught', catcher_pid, runner_pid)
		room_node.on_player_caught(catcher_pid, runner_pid)


remote func receive_player_reached_eom(room_id):
	var pid = get_tree().get_rpc_sender_id()
	var room_node = HelperFunctions.get_room_node(room_id)
	room_node.on_player_finished_round(pid)


remote func multicast_round_finish(room_node):
	var pids = room_node.get_player_ids()
	for pid in pids:
		rpc_id(pid, 'receive_round_finish')


func multicast_game_finish(winning_team, room_node):
	var pids = room_node.get_player_ids()
	for pid in pids:
		rpc_id(pid, 'receive_game_finish', winning_team)
