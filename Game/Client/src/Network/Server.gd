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
	var error = network.connect_to_url(server_url, PoolStringArray(), true);
	get_tree().set_network_peer(network)
	# set_network_master(1) - not a must.
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")


func _on_connection_failed():
	print('failed to connect')


func _on_connection_succeeded():
	print('succesfully connected')


func request_player_login(mode, nickname, join_room_id):
	# called from PlayerLogin scene (former ChooseNickname)
	# params:
	#	mode: join/create
	#	nickname: name
	#	join_room_id: id if trying to join, null otherwise
	rpc_id(1, 'login_player', mode, nickname, join_room_id)


remote func on_login_success():
	SceneHandler.handle_scene_change('login_success')
	
