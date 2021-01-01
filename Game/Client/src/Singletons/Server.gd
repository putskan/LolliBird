extends Node

const IP_ADDRESS = "127.0.0.1"
const PORT = 11111
var network = WebSocketClient.new()
var server_url = 'ws://%s:%d' % [IP_ADDRESS, PORT]
signal player_disconnect(player_id)
signal init_teams_players
signal assign_as_room_host
signal change_team_of_player_sig(team_name, player_id)
signal add_team_player(team_name, player_id, player_attributes)
signal start_game
signal round_start
signal round_finish
signal receive_players_states(players_states)
signal player_caught(catcher_pid, runner_pid)
signal game_finish(winning_team)


func _ready():
	connect_to_server()


func _process(_delta):
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
	Globals.player_id = get_tree().get_network_unique_id()
	print('succesfully connected')


remote func receive_player_disconnect(player_id):
	for team in Globals.teams_players:
		var players_in_team = Globals.teams_players[team]
		if players_in_team.has(player_id):
			players_in_team.erase(player_id)
			
	emit_signal('player_disconnect', player_id)
	

func request_room_id_join_validation(room_id):
	# send room id to server for validation that the room exists
	# called from JoinRoom
	print('Client: verifying room id: %d' % room_id)
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


remote func init_teams_players(teams_players_data):
	Globals.teams_players = teams_players_data
	emit_signal('init_teams_players')


remote func add_team_player(team_name, player_id, player_attributes):
	Globals.teams_players[team_name][player_id] = player_attributes
	emit_signal("add_team_player", team_name, player_id, player_attributes)


remote func change_team_of_player(old_team_name, new_team_name, player_id):
	# update in Globals.teams_players & change own player team if needed.
	if old_team_name == new_team_name:
		return
	Globals.teams_players[new_team_name][player_id] = Globals.teams_players[old_team_name][player_id]
	Globals.teams_players[old_team_name].erase(player_id)
	
	if player_id == Globals.player_id:
		Globals.player_team = new_team_name
		
	### change in receiver
	emit_signal("change_team_of_player_sig", old_team_name, new_team_name, player_id)


func multicast_change_team_of_player(old_team_name, new_team_name, player_id):
	rpc_id(1, 'multicast_change_team_of_player', old_team_name, new_team_name, player_id, Globals.room_id)


func request_start_game():
	rpc_id(1, 'start_game', Globals.room_id)


remote func start_game():
	emit_signal('start_game')


remote func assign_as_room_host():
	emit_signal('assign_as_room_host')
	Globals.is_host = true


func send_player_state(player_state):
	# call from player
	rpc_unreliable_id(1, 'receive_player_state', player_state, Globals.room_id)


remote func receive_all_players_states(s_players_states):
	# caught by Map scene 
	emit_signal('receive_players_states', s_players_states)


func request_round_start():
	rpc_id(1, 'round_start', Globals.room_id)


remote func round_start():
	emit_signal('round_start')


func multicast_player_caught(catcher_pid, runner_pid):
	rpc_id(1, 'receive_player_caught', catcher_pid, runner_pid, Globals.room_id)


remote func receive_player_caught(catcher_pid, runner_pid):
	# caught by Game
	print('received_player_caught_remotely!')
	emit_signal('player_caught', catcher_pid, runner_pid)


func notify_player_reached_eom():
	# eom > end of map
	rpc_id(1, 'receive_player_reached_eom', Globals.room_id)


remote func receive_round_finish():
	emit_signal('round_finish')


remote func receive_game_finish(winning_team):
	emit_signal('game_finish', winning_team)
