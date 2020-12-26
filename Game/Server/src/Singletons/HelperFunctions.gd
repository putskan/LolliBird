extends Node


func _generate_room_id():
	# generate unused 4 digit number and add to the currently running rooms
	while true:
		var room_id = randi()%9999+1000
		if not room_id in Globals.running_rooms_ids:
			Globals.running_rooms_ids.append(room_id)
			print(Globals.running_rooms_ids)
			return room_id


func create_room(host_id):
	# init room and add as child to root_node
	var room = Globals.room_resource.instance()
	# add team nodes to room hierarchy
	var teams_node = Node.new()
	teams_node.name = 'Teams'
	var team_1_node = Node.new()
	team_1_node.name = Globals.TEAM_1_NOTATION
	var team_2_node = Node.new()
	team_2_node.name = Globals.TEAM_2_NOTATION
	var unassigned_team_node = Node.new()
	unassigned_team_node.name = Globals.UNASSIGNED_TEAM_NOTATION
	teams_node.add_child(team_1_node)
	teams_node.add_child(team_2_node)
	teams_node.add_child(unassigned_team_node)
	room.add_child(teams_node, true)
	# set room attributes
	var room_id = HelperFunctions._generate_room_id()
	room.name = str(room_id)
	room.host_id = host_id
		
	# add to SceneTree
	get_tree().get_root().get_node('RunningRooms').add_child(room, true)
	return room


func create_player(player_id, player_name, room_id):
	# create a player and return error message is present
	var room_node = get_room_node(room_id)
	for team_notation in [Globals.UNASSIGNED_TEAM_NOTATION, Globals.TEAM_1_NOTATION, Globals.TEAM_2_NOTATION]:
		if room_node.has_node('Teams/%s/%s' % [team_notation, player_name]):
			return 'Player Name Already Taken'
	# init player object
	var player = Globals.player_resource.instance()
	player.player_id = player_id
	player.name = str(player_id)
	player.player_name = player_name
	# add player to tree
	room_node.get_node('Teams/Unassigned').add_child(player, true)
	# save data for future time complexity reduction
	room_node.room_player_basic_info[player_id] = {'player_name': player_name, 'team_name': 'Unassigned'}


func get_room_node(room_id):
	# return get_tree().get_root().find_node(str(room_id), true, false)
	return Globals.running_rooms_node.get_node(str(room_id))


func get_room_player_ids(room_id, excluded_pid=null):
	var pids = get_room_node(room_id).room_player_basic_info.keys()
	if excluded_pid:
		pids.erase(excluded_pid)
	return pids


func update_player_team(player_name, player_team_name, room_id):
	"""
	serverside only: update player's team in sceneTree hierarchy & globals, by its name
	"""
	var player_node = get_player_node_by_name(player_name, room_id)
	var new_team_node = player_node.get_parent().get_parent().get_node(player_team_name)
	# remove from previous team
	player_node.get_parent().remove_child(player_node)
	# add to new team
	new_team_node.add_child(player_node)
	get_room_node(room_id).room_player_basic_info[int(player_node.name)].team_name = new_team_node.name


func get_player_node_by_name(player_name, room_id):
	for team_node in get_room_node(room_id).get_node('Teams').get_children():
		for player_node in team_node.get_children():
			if player_node.player_name == player_name:
				return player_node


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

