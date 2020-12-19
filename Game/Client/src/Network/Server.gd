extends Node

var network = NetworkedMultiplayerENet.new()
var ip = "127.0.0.1"
var port = 1909

# Called when the node enters the scene tree for the first time.
func _ready():
	connect_to_server()


func connect_to_server():
	network.create_client(ip, port)
	get_tree().set_network_peer(network)
	# set_network_master(1)
	
	network.connect("connection_failed", self, "_on_connection_failed")
	network.connect("connection_succeeded", self, "_on_connection_succeeded")


func _on_connection_failed():
	print('failed to connect')


func _on_connection_succeeded():
	print('succesfully connected')


func request_game_creation():
	rpc_id(1, "create_game")
	pass


remote func on_game_creation(game_id):
	SceneHandler.handle_scene_change('game_created')
	


func request_player_login(player_attributes):
	# called from PlayerLogin scene
	# player attributes: json
	rpc_id(1, 'login_player', player_attributes)


remote func on_login_success():
	SceneHandler.handle_scene_change('login_success')
	
	
	
	
