extends Node

var network = NetworkedMultiplayerENet.new()
var port = 1909
var max_players = 300
var running_game_ids = []

# Called when the node enters the scene tree for the first time.
func _ready():
	print("I'm The Real Server!")
	start_server()
	
func start_server():
	network.create_server(port, max_players)
	get_tree().set_network_peer(network)
	
	network.connect("peer_connected", self, "_peer_connected")
	network.connect("peer_disconnected", self, "_peer_disconnected")
	
	
func _peer_connected(player_id):
	# player_id is actually peer_id
	print("User %s Connected!" % player_id)
	
func _peer_disconnected(player_id):
	print("User %s Disconnected!" % player_id)
	
		
func generate_game_id():
	# generate unused 4 digit number
	while true:
		var game_id = randi()%9999+1000
		if not game_id in running_game_ids:
			running_game_ids.append(game_id)
			return game_id
		

remote func create_game():
	# game_id is used as a pin as well.
	var player_id = get_tree().get_rpc_sender_id()
	var game_id = generate_game_id()
	print(game_id)
	rpc_id(player_id, "on_game_creation", game_id)
	
	
remote func login_player(player_attributes):
	var player_id = get_tree().get_rpc_sender_id()
	### save player info here ###
	rpc_id(player_id, 'on_login_success')
	

