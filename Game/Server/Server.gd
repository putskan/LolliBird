extends Node

# var network = NetworkedMultiplayerENet.new()
var network = WebSocketServer.new();
var port = 1909
var max_players = 300
var running_rooms_ids = []
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
	
		
func generate_room_id():
	# generate unused 4 digit number
	while true:
		var room_id = randi()%9999+1000
		if not room_id in running_rooms_ids:
			running_rooms_ids.append(room_id)
			return room_id

"""
{
	mode: create/join
	nickname: name
	room_id: null/join_pin
}
"""
remote func login_player(mode, nickname, join_room_id):
	var player_id = get_tree().get_rpc_sender_id()
	var room
	# find / create room:
	if mode == 'create':
		# init room
		room = load('res://src/Room.tscn').instance()
		var room_id = generate_room_id()
		room.room_id = room_id
		room.name = 'room_%d' % room_id
		room.host_id = player_id
		root_node.add_child(room)
		
	else:
		# if join and not creating
		room = root_node.get_node("room_%d" % join_room_id)

	# create player
	var player = load('res://src/Player.tscn').instance()
	player.player_id = player_id
	player.name = 'player_%d' % player_id
	player.player_name = 'nickname'
	# add to tree
	room.add_child(player)
	# add to team "unassigned" (0)
	room.teams[0].append(player_id)
	rpc_id(player_id, 'on_login_success')


