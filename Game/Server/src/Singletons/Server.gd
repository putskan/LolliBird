extends Node

const PORT = 11111
var network = WebSocketServer.new();
onready var root_node = get_tree().get_root()


func _ready():
	print("I'm The Real Server!")
	start_server()


func _process(_delta):
	if network.is_listening():
		# checking for incoming connections
		network.poll()

func start_server():
	network.listen(PORT, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(player_id):
	# player_id is actually peer_id
	print("User %s Connected!" % player_id)


func _peer_disconnected(player_id):
	print("User %s Disconnected!" % player_id)
	for room_node in Globals.running_rooms_node.get_children():
		# may be true, or null if room is closing
		if room_node.remove_player(player_id) != false:
			# notify room players of deletion, if player removed & room not closed
			if room_node:
				for pid in room_node.get_player_ids(get_tree().get_rpc_sender_id()):
					rpc_id(pid, 'update_players_data', {player_id: null}, true)
			break


func assign_new_room_host(host_id):
	rpc_id(host_id, 'assign_as_room_host')


remote func is_room_id_exists(room_id):
	# check if there's an open room with "room_id" and send back the info to the client
	rpc_id(get_tree().get_rpc_sender_id(), 'response_room_id_join_validation', room_id in Globals.running_rooms_ids)


remote func create_room():
	var player_id = get_tree().get_rpc_sender_id()
	var room = HelperFunctions.create_room(player_id)
	rpc_id(player_id, 'response_room_creation', int(room.name))


remote func create_player(player_name, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var error_message = HelperFunctions.create_player(get_tree().get_rpc_sender_id(), player_name, room_id)
	rpc_id(player_id, 'response_player_creation', error_message)
	# update 
	if not error_message:
		# send all existing players to the new player
		rpc_id(player_id, 'init_teams_players', HelperFunctions.get_room_node(room_id).teams_players)
		# send an update of the new player to all other room players
		var room_node = HelperFunctions.get_room_node(room_id)
		var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
		for pid in pids:
			rpc_id(pid, 'add_team_player', 'Unassigned', player_id, {'player_name': player_name})


remote func multicast_change_team_of_player(old_team_name, new_team_name, player_id, room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	# update locally
	room_node.teams_players[new_team_name][player_id] = room_node.teams_players[old_team_name][player_id]
	room_node.teams_players[old_team_name].erase(player_id)
	# send to all room players
	var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_id(pid, 'change_team_of_player', old_team_name, new_team_name, player_id)


"""
# related to lobby - must be changed

remote func client_lobby_entry_sync(player_name, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	# send client the other player's data
	rpc_id(player_id, 'sync_lobby_players', HelperFunctions.get_team_names_to_player_names(room_id))
	# multicast the new added player to the rest of the room clients
	var room_node = HelperFunctions.get_room_node(room_id)
	var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_id(pid, 'sync_lobby_players', {'Unassigned': [player_name]})


remote func multicast_lobby_bird_move(bird_name, new_team, room_id):
	var pid = get_tree().get_rpc_sender_id()
	var room_node = HelperFunctions.get_room_node(room_id)
	# update locally
	room_node.update_player_team(pid, new_team)
	# notify all other room players
	var pids = room_node.get_player_ids(pid)
	for client_pid in pids:
		rpc_id(pid, 'move_lobby_bird', bird_name, new_team)


remote func get_team_names_to_player_names(room_id):
	rpc_id(get_tree().get_rpc_sender_id(), 'response_team_names_to_players_names', HelperFunctions.get_team_names_to_player_names(room_id))
"""


######################################## Game ########################################

remote func start_game(room_id):
	# notify all other room players & start running
	var room_node = HelperFunctions.get_room_node(room_id)
	var pids = room_node.get_player_ids()
	for pid in pids:
		rpc_id(pid, 'start_game')
	# HelperFunctions.get_room_node(room_id).set_physics_process(true)


remote func receive_player_state(player_state, room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	room_node.update_player_state(get_tree().get_rpc_sender_id(), player_state)


func multicast_players_states(room_id, players_states):
	# called from room
	var room_node = HelperFunctions.get_room_node(room_id)
	var pids = room_node.get_player_ids(get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_unreliable_id(pid, 'receive_all_players_states', players_states)

###################


# P2
remote func round_start(room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	var pids = room_node.get_player_ids()
	for pid in pids:
		rpc_id(pid, 'round_start')
	# do serverside stuff, update, stats etc
