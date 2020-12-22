extends Node

# var network = NetworkedMultiplayerENet.new()
var network = WebSocketServer.new();
var port = 1909
var max_players = 300
onready var root_node = get_tree().get_root()

# Called when the node enters the scene tree for the first time.
func _ready():
	print("I'm The Real Server!")
	start_server()

func _process(delta):
	if network.is_listening():
		# checking for incoming connections
		network.poll()


func start_server():
	network.listen(port, PoolStringArray(), true);
	# network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	
	
func _peer_connected(player_id):
	# player_id is actually peer_id
	print("User %s Connected!" % player_id)


func _peer_disconnected(player_id):
	print("User %s Disconnected!" % player_id)

"""
remote func login_player(mode, nickname, join_room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var room
	# find / create room:
	if mode == 'create':
		# init room
		room = HelperFunctions.create_room(player_id)

	else:
		# if join room
		room = Globals.running_rooms_node.get_node(str(join_room_id))

	# create Player object
	var player = HelperFunctions.create_player(player_id, nickname)

	# add player to tree
	room.get_node('Teams/Unassigned').add_child(player, true)
	# add to team "unassigned" (0)
	room.teams[0].append(player_id)
	print('Entering RPC call on_login_success')
	rpc_id(player_id, 'on_login_success', player.player_name, room.room_id, room.host_id == player_id)
	# broadcast the player has connected
	rpc_id(0, 'on_other_player_join', player.player_name)
	var room_players = HelperFunctions.get_all_players_in_room(room)
	
	# load previously connected players to the new client
	for p in room_players:
		rpc_id(player_id, 'on_other_player_join', p.player_name)
		print(p.player_name)
	
	get_tree().get_root().print_tree_pretty()
"""
"""
remote func fetch_room_teams_players(room_id):
	# get the players in the room of the requesting client
	print('roomid %d' % room_id)
	var room_node = HelperFunctions.get_room_node(room_id)
	return HelperFunctions.get_room_teams_and_players(room_node)
"""

remote func is_room_id_exists(room_id):
	# check if there's an open room with "room_id" and send back the info to the client
	rpc_id(get_tree().get_rpc_sender_id(), 'response_room_id_join_validation', room_id in Globals.running_rooms_ids)
	

remote func create_room():
	var player_id = get_tree().get_rpc_sender_id()
	var room = HelperFunctions.create_room(player_id)
	rpc_id(player_id, 'response_room_creation', room.name)


remote func create_player(player_name, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var error_message = HelperFunctions.create_player(get_tree().get_rpc_sender_id(), player_name, room_id)
	rpc_id(player_id, 'response_player_creation', error_message)
		

remote func client_lobby_entry_sync(player_name, room_id):
	var player_id = get_tree().get_rpc_sender_id()
	# send client the other player's data
	var room_node = HelperFunctions.get_room_node(room_id)
	
	rpc_id(player_id, 'sync_lobby_players', room_node.room_teams_to_players_names)
	
	# var teams_to_players_names = HelperFunctions.get_room_teams_and_players_names(room_id)
	#var player_names = HelperFunctions.nodes_to_names(HelperFunctions.flatten_dict_of_lists(teams_to_players))
	
	# multicast the new added player to the rest of the room clients
	for pid in room_node.room_player_ids:
		if pid != player_id:
			rpc_id(pid, 'sync_lobby_players', {'Unassigned': [player_name]})



