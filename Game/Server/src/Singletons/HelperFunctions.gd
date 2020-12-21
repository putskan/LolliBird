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
	room.room_id = room_id
	room.name = str(room_id)
	room.host_id = host_id
		
	# add to SceneTree
	get_tree().get_root().get_node('RunningRooms').add_child(room, true)
	return room


func create_player(player_id, player_name, room_id):
	# create a player and return erro message is present
	var room_node = get_room_node(room_id)
	# check if exists in room already
	for team_notation in [Globals.UNASSIGNED_TEAM_NOTATION, Globals.TEAM_1_NOTATION, Globals.TEAM_2_NOTATION]:
		if room_node.has_node('Teams/%s/%s' % [team_notation, player_name]):
			return 'Player Name Already Taken'
	# init player object
	var player = Globals.player_resource.instance()
	player.player_id = player_id
	player.name = str(player_id)
	player.player_name = player_name
	player.team = 'Unassigned'
	# add player to tree
	room_node.get_node('Teams/Unassigned').add_child(player, true)
	# save data for future time complexity reduction
	room_node.room_teams_to_players['Unassigned'].append(player)
	room_node.room_teams_to_players_names['Unassigned'].append(player.player_name)
	room_node.room_player_ids.append(player_id)


func get_room_node(room_id):
	return get_tree().get_root().find_node(str(room_id), true, false)
	
