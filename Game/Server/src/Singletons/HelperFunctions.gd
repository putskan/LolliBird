extends Node


func _generate_room_id():
	# generate unused 4 digit number and add to the currently running rooms
	while true:
		var room_id = randi() % 9999
		if room_id < 1000:
			room_id += 1000
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

