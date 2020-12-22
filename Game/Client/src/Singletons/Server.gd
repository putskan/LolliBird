extends Node

var network = WebSocketClient.new()
var ip = "127.0.0.1"
var port = 1909
var server_url = 'ws://%s:%d' % [ip, port]


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

"""
func request_player_login(mode, nickname, join_room_id):
	# called from PlayerLogin scene (former ChooseNickname)
	# params:
	#	mode: join/create
	#	nickname: name
	#	join_room_id: id if trying to join, null otherwise
	rpc_id(1, 'login_player', mode, nickname, join_room_id)
"""
"""
remote func on_login_success(player_name, room_id, is_player_host):
	Globals.player_name = player_name
	Globals.room_id = room_id
	print('Room ID is %d' % room_id)
	Globals.player_team = 'Unassigned'
	Globals.is_host = is_player_host
	SceneHandler.handle_scene_change('login_success')
"""
"""
remote func on_other_player_join(s_other_player_name):
	# add bird to GameLobby if other player has joined the lobby
	var current_scene = get_tree().get_current_scene()
	print(current_scene.name)
	if current_scene.name  == 'GameLobby' and s_other_player_name != Globals.player_name:
		current_scene.add_bird_to_team(s_other_player_name, Globals.UNASSIGNED_TEAM_NOTATION)
"""
"""
func request_room_teams_players():
	# fetch all player names in the room by their teams. 
	# e.g., {'Team1': ['Dave', ...], 'Team2': ['Rachel', ...], 'Unassigned': ['Daniel', ...]}
	rpc_id(1, 'fetch_room_teams_players', Globals.room_id)
"""
"""
remote func response_room_teams_players():
	# the response from request_room_teams_players
	pass
"""

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
	Globals.is_host = true


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
	teams_to_players_dict = teams_to_players_dict
	get_tree().get_current_scene().add_birds_to_teams(teams_to_players_dict)
		
