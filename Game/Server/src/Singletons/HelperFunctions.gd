extends Node


func _generate_room_id():
	# generate unused 4 digit number and add to the currently running rooms
	while true:
		var room_id = randi()%9999+1000
		if not room_id in Globals.running_rooms_ids:
			print(Globals.running_rooms_ids)
			return room_id


func create_room(host_id):
	# init room and add as child to root_node
	var room = Globals.room_resource.instance()
	# set room attributes
	var room_id = HelperFunctions._generate_room_id()
	room.name = str(room_id)
	room.host_id = host_id
	# add to SceneTree
	get_tree().get_root().get_node('RunningRooms').add_child(room, true)
	Globals.running_rooms_ids.append(room_id)
	return room


func create_player(player_id, player_name, room_id):
	# create a player and return error message is present
	var room_node = get_room_node(room_id)
	if room_node.is_player_name_exists('player_name'):
		return 'Player Name Already Taken'
	# add player data to room
	var player = {player_id: {'player_name': player_name}}
	room_node.add_player(player, 'Unassigned')


func get_room_node(room_id):
	# return get_tree().get_root().find_node(str(room_id), true, false)
	return Globals.running_rooms_node.get_node(str(room_id))

























"""
func get_player_node_by_name(player_name, room_id):
	for team_node in get_room_node(room_id).get_node('Teams').get_children():
		for player_node in team_node.get_children():
			if player_node.player_name == player_name:
				return player_node
"""
"""
func get_team_names_to_player_names(room_id):
	# return: 
	# {'Team1': [p1_name, p2_name...], 'Team2' : [...], 'Unassigned': [...]}
	var team_names_to_player_names = {}
	for team_node in get_room_node(room_id).get_node('Teams').get_children():
		var team_players = []
		for player_node in team_node.get_children():
			team_players.append(player_node.player_name)
		team_names_to_player_names[team_node.name] = team_players
	return team_names_to_player_names
"""
