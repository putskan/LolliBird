extends Node

# const IP_ADDRESS = "127.0.0.1"
# const PORT = 11111
# var server_url = 'ws://%s:%d' % [IP_ADDRESS, PORT]
const IP_ADDRESS = 'lollibird.herokuapp.com'
const PORT = 443
var server_url = 'wss://%s:%d/ws/' % [IP_ADDRESS, PORT]
var network = WebSocketClient.new()
# clock sync varibales
var latency = 0
var decimal_collector : float = 0
var latency_array = []
var delta_latency = 0

signal player_disconnect(player_id)
signal return_from_tab_switch
signal init_teams_players
signal assign_as_room_host
signal receive_host_name(host_name)
signal change_team_of_player_sig(team_name, player_id)
signal add_team_player(team_name, player_id, player_attributes)
signal start_game
signal round_start
signal round_finish
signal receive_players_states(players_states)
signal player_caught(catcher_pid, runner_pid)
signal game_finish(winning_team)
signal receive_response_start_game(error_msg)


func _ready():
	connect_to_server()
	set_physics_process(false)
	self.connect('return_from_tab_switch', self, 'fetch_server_time')


func _process(_delta):
	if network.get_connection_status() in [NetworkedMultiplayerPeer.CONNECTION_CONNECTED, NetworkedMultiplayerPeer.CONNECTION_CONNECTING]:
		network.poll()


func _physics_process(delta):
	# handle tab switches in game
	if HelperFunctions.check_return_from_tab_switch():
		emit_signal('return_from_tab_switch')

	# make the clock tick
	Globals.client_clock += int(delta * 1000) + delta_latency
	delta_latency = 0
	# collect remaining milliseconds - ~0.667 ms per iteration
	decimal_collector += (delta * 1000) - int(delta * 1000)
	if decimal_collector >= 1.00:
		Globals.client_clock += 1
		decimal_collector -= 1.00


func connect_to_server():
	network.connect_to_url(server_url, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")


func _on_connection_failed():
	pass


func _on_connection_succeeded():
	Globals.player_id = get_tree().get_network_unique_id()


func start_clock_sync():
	# called by Game
	set_physics_process(true)
	fetch_server_time()
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.autostart = true
	timer.connect('timeout', self, 'determine_latency')
	self.add_child(timer)


func fetch_server_time():
	rpc_id(1, 'fetch_server_time', OS.get_system_time_msecs())


remote func return_server_time(server_time, client_time):
	# add the latency because until the packet arrives, the server's clock is already higher
	latency = (OS.get_system_time_msecs() - client_time) / 2
	Globals.client_clock = server_time + latency


func determine_latency():
	rpc_id(1, 'determine_latency', OS.get_system_time_msecs())


remote func return_latency(client_time):
	latency_array.append((OS.get_system_time_msecs() - client_time) / 2)
	if latency_array.size() == 9:
		var total_latency = 0
		latency_array.sort()
		var mid_point = latency_array[4]
		for i in range(latency_array.size()-1, -1, -1):
			var current_latency = latency_array[i]
			if current_latency > mid_point * 2 and current_latency > 20:
				# remove high-latency that occured due to packet loss
				latency_array.remove(i)
			else:
				total_latency += current_latency
				
		var avg_latency = total_latency / latency_array.size()
		delta_latency = avg_latency - latency
		latency = avg_latency
		latency_array.clear()


remote func receive_player_disconnect(player_id):
	for team in Globals.teams_players:
		var players_in_team = Globals.teams_players[team]
		if players_in_team.has(player_id):
			players_in_team.erase(player_id)
			
	emit_signal('player_disconnect', player_id)


func request_room_id_join_validation(room_id):
	# send room id to server for validation that room exists/not full, etc.
	# called from JoinRoom
	rpc_id(1, 'is_room_join_valid', room_id)


remote func response_room_id_join_validation(error_msg):
	# response from the server 
	# current_scene should be JoinRoom
	get_tree().get_current_scene().handle_join_response(error_msg)


func request_room_creation():
	rpc_id(1, 'create_room')


func request_room_close(room_id):
	rpc_id(1, 'close_room', room_id)


remote func response_room_creation(room_id):
	Globals.room_id = room_id
	assign_as_room_host()


func request_host_name():
	rpc_id(1, 'unicast_host_name', Globals.room_id)
	
	
remote func receive_host_name(host_name):
	Globals.host_name = host_name
	emit_signal('receive_host_name', host_name)


func request_player_creation(player_name, room_id, player_team='Unassigned'):
	# request server to create the player
	rpc_id(1, 'create_player', player_name, player_team, room_id)


remote func response_player_creation(_error_msg):
	# :str error_message: error occurred in serverside's player creation, null otherwise
	SceneHandler.handle_scene_change('GoToLobby')


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
		
	emit_signal("change_team_of_player_sig", old_team_name, new_team_name, player_id)


func multicast_change_team_of_player(old_team_name, new_team_name, player_id):
	rpc_id(1, 'multicast_change_team_of_player', old_team_name, new_team_name, player_id, Globals.room_id)


func request_start_game():
	rpc_id(1, 'start_game', Globals.room_id)


remote func response_start_game(error_msg=null):
	emit_signal('receive_response_start_game', error_msg)


remote func start_game():
	emit_signal('start_game')


remote func assign_as_room_host():
	emit_signal('assign_as_room_host')
	Globals.is_host = true
	if Globals.player_name:
		Globals.host_name = Globals.player_name


func send_player_state(player_state):
	# call from player
	rpc_unreliable_id(1, 'receive_player_state', player_state, Globals.room_id)


remote func receive_all_players_states(s_players_states):
	# caught by Map scene 
	emit_signal('receive_players_states', s_players_states)


func request_round_start():
	rpc_id(1, 'start_first_round', Globals.room_id)


remote func round_start():
	Globals.first_round_start = true
	emit_signal('round_start')


func multicast_player_caught(catcher_pid, runner_pid):
	rpc_id(1, 'receive_player_caught', catcher_pid, runner_pid, Globals.room_id)


remote func receive_player_caught(catcher_pid, runner_pid):
	# caught by Game
	yield(get_tree().create_timer(float(Globals.INTERPOLATION_OFFSET) / 1000.0), "timeout")
	emit_signal('player_caught', catcher_pid, runner_pid)


func notify_player_reached_eom():
	# eom - end of map
	rpc_id(1, 'receive_player_reached_eom', Globals.room_id)


remote func receive_round_finish():
	emit_signal('round_finish')


remote func receive_game_finish(winning_team):
	emit_signal('game_finish', winning_team)
