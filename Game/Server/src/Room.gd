extends Node2D

# var room_id
# var current_round = 1
# var total_rounds = 5

# the room's creator
var host_id
# for easy, non-tree access - {player_id: {'player_name': name, 'team_name': team}, ...}
var room_player_basic_info = {}
# format: {player_id: {'T': timestamp, 'P': position}, player_id: {...}}
var player_state_collection = {}


func _ready():
	# change to true when game starts
	set_physics_process(false)


func _physics_process(delta):
	# 20 fps
	# remove player timestamp, change pids to players names, add server timestamp
	# changing pids to player_names because client knows only names.
	var player_state_to_client = {}
	for pid in player_state_collection:
		var state = player_state_collection[pid].duplicate().erase('T')
		player_state_to_client[find_node(str(pid), true, false).player_name] = state
	player_state_to_client['T'] = OS.get_system_time_msecs()
	Server.multicast_players_states(int(self.name), player_state_to_client)


func update_player_state(player_id, player_state):
	# update a player's state on the server
	if not player_state_collection.has(player_id):
		player_state_collection[player_id] = player_state
		
	elif player_state_collection[player_id]['T'] < player_state['T']:
		# update only if received timestamp is newer than the existing one
		player_state_collection[player_id] = player_state

