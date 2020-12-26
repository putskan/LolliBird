extends Node

var network = WebSocketServer.new();
var port = 11111
var max_players = 300
onready var root_node = get_tree().get_root()


func _ready():
	print("I'm The Real Server!")
	start_server()


func _process(delta):
	if network.is_listening():
		# checking for incoming connections
		network.poll()

func start_server():
	network.listen(port, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")


func _peer_connected(player_id):
	# player_id is actually peer_id
	print("User %s Connected!" % player_id)


func _peer_disconnected(player_id):
	print("User %s Disconnected!" % player_id)
	var player_node = Globals.running_rooms_node.find_node(str(player_id), true, false)
	if not player_node:
		# if not found (i.e., not inside a room)
		return
		
	# clean room resources		
	var room_node = player_node.get_parent().get_parent().get_parent()
	room_node.room_player_basic_info.erase(player_id)
	room_node.player_state_collection.erase(player_id)
	# remove player from sceneTree
	player_node.queue_free()
	# notify other clients in room
	for pid in HelperFunctions.get_room_player_ids(int(room_node.name), get_tree().get_rpc_sender_id()):
		rpc_id(pid, 'update_room_players_dict', {player_id: null}, true)


	if room_node.host_id == player_id:
		if not room_node.room_player_basic_info.empty():
			# if there are players left, assign new host
			room_node.host_id = room_node.room_player_basic_info.keys()[0]
			rpc_id(room_node.host_id, 'assign_as_room_host')

		else:
			# close room
			Globals.running_rooms_ids.erase(room_node.name)
			room_node.queue_free()


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
		# update player list on room clients
		rpc_id(player_id, 'update_room_players_dict', HelperFunctions.get_room_node(room_id).room_player_basic_info)
		for pid in HelperFunctions.get_room_player_ids(room_id, get_tree().get_rpc_sender_id()):
			rpc_id(pid, 'update_room_players_dict', {player_id: {'player_name': player_name, 'team_name': 'Unassigned'}})


remote func client_lobby_entry_sync(player_name, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	# send client the other player's data
	rpc_id(player_id, 'sync_lobby_players', HelperFunctions.get_team_names_to_player_names(room_id))
	# multicast the new added player to the rest of the room clients
	for pid in HelperFunctions.get_room_player_ids(room_id, get_tree().get_rpc_sender_id()):
		rpc_id(pid, 'sync_lobby_players', {'Unassigned': [player_name]})


remote func multicast_lobby_bird_move(bird_name, new_team, room_id):
	# update locally
	HelperFunctions.update_player_team(bird_name, new_team, room_id)
	# notify all other room players
	var pids = HelperFunctions.get_room_player_ids(room_id, get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_id(pid, 'move_lobby_bird', bird_name, new_team)


remote func get_team_names_to_player_names(room_id):
	rpc_id(get_tree().get_rpc_sender_id(), 'response_team_names_to_players_names', HelperFunctions.get_team_names_to_player_names(room_id))


remote func start_game(room_id):
	# notify all other room players & start running
	var pids = HelperFunctions.get_room_player_ids(room_id, get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_id(pid, 'start_game')
	HelperFunctions.get_room_node(room_id).set_physics_process(true)


remote func receive_player_state(player_state, room_id):
	var room_node = HelperFunctions.get_room_node(room_id)
	room_node.update_player_state(get_tree().get_rpc_sender_id(), player_state)


func multicast_players_states(room_id, players_states):
	# called from room
	var pids = HelperFunctions.get_room_player_ids(room_id, get_tree().get_rpc_sender_id())
	for pid in pids:
		rpc_unreliable_id(pid, 'receive_all_players_states', players_states)

