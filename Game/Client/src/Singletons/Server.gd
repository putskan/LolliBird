extends Node

var network = WebSocketClient.new()
var ip = "127.0.0.1"
var port = 11111
var server_url = 'ws://%s:%d' % [ip, port]
signal response_received_team_names_to_players_names(result)
signal peer_list_updated


func _ready():
	connect_to_server()


func _process(delta):
	if network.get_connection_status() in [NetworkedMultiplayerPeer.CONNECTION_CONNECTED, NetworkedMultiplayerPeer.CONNECTION_CONNECTING]:
		network.poll();


func connect_to_server():
	# non websocket implementation, using ENet: network.create_client(ip, port)
	network.connect_to_url(server_url, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	# set_network_master(1) - not a must.
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")


func _on_connection_failed():
	print('failed to connect')


func _on_connection_succeeded():
	print('succesfully connected')


func request_room_id_join_validation(room_id):
	# send room id to server for validation that the room exists
	# called from JoinRoom
	print('Client: sending roomid for check: %d' % room_id)
	rpc_id(1, 'is_room_id_exists', room_id)


remote func response_room_id_join_validation(is_room_id_valid):
	# response from the server 
	# current_scene should be JoinRoom
	print('room id valid? %s' % is_room_id_valid)
	get_tree().get_current_scene().handle_join_response(is_room_id_valid)


func request_room_creation():
	rpc_id(1, 'create_room')


remote func response_room_creation(room_id):
	Globals.room_id = room_id
	assign_as_room_host()


func request_player_creation(player_name, room_id):
	# request server to create the player
	rpc_id(1, 'create_player', player_name, room_id)


remote func response_player_creation(error_message):
	# error_message: str if error occurred in serverside's player creation, null otherwise
	# current scene should be UserPrefs
	get_tree().get_current_scene().handle_player_creation_response(error_message)


func request_lobby_entry_sync():
	# relevant for GameLobby scene
	# tell the server the player connected to lobby successfully,
	# receive all other relevant players details (player names)
	rpc_id(1, 'client_lobby_entry_sync', Globals.player_name, Globals.room_id)


remote func sync_lobby_players(teams_to_players_dict):
	# relevant for GameLobby scene
	# receive a dict of the players to add to the lobby (for sync purposes)
	get_tree().get_current_scene().add_birds_to_teams(teams_to_players_dict)


func multicast_lobby_bird_move(bird_name, new_team):
	rpc_id(1, 'multicast_lobby_bird_move', bird_name, new_team, Globals.room_id)


remote func move_lobby_bird(bird_name, new_team):
	# current scene should be GameLobby
	get_tree().get_current_scene().move_lobby_bird(bird_name, new_team)


func request_team_names_to_players_names():
	rpc_id(1, 'get_team_names_to_player_names', Globals.room_id)


remote func response_team_names_to_players_names(result):
	emit_signal('response_received_team_names_to_players_names', result)


func request_start_game():
	rpc_id(1, 'start_game', Globals.room_id)


remote func start_game():
	SceneHandler.handle_scene_change('StartGame')


remote func assign_as_room_host():
	Globals.is_host = true


func send_player_state(player_state):
	# call from player
	rpc_unreliable_id(1, 'receive_player_state', player_state, Globals.room_id)


remote func receive_all_players_states(s_players_states):
	# send to function on map node
	get_tree().get_current_scene().update_all_players_states(s_players_states)


remote func update_room_players_dict(players_details, remove=false):
	# players_details - {player_id: {'player_name': name, 'team_name': team}, ...}
	if remove:
		for k in players_details:
			Globals.room_players_dict.erase(k)
	
	else:
		for k in players_details:
			Globals.room_players_dict[k] = players_details[k]
	emit_signal('peer_list_updated')




