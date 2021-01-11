extends Node

func _generate_room_id():
	# generate unused 4 digit number and add to the currently running rooms
	while true:
		var room_id = randi() % 9999
		if room_id < 1000:
			room_id += 1000
		if not room_id in Globals.running_rooms_ids:
			return room_id


func create_room(host_id):
	# init room and add as child to root_node
	var room = Globals.room_resource.instance()
	# set room attributes
	var room_id = HelperFunctions._generate_room_id()
	room.name = str(room_id)
	room.room_id = room_id
	room.host_id = host_id
	# add to SceneTree
	get_tree().get_root().get_node('RunningRooms').add_child(room, true)
	Globals.running_rooms_ids.append(room_id)
	return room


func create_player(player_id, player_name, player_team, room_id):
	# create a player and return error message is present
	var room_node = get_room_node(room_id)
	# add player data to room
	var player = {player_id: {'player_name': player_name}}
	room_node.add_player(player, player_team)
	# overcome a rematch edge case - host leaves room and rejoins
	if player_id == room_node.host_id:
		room_node.host_name = player_name
		Server.assign_new_room_host(player_id)
		Server.multicast_host_name(room_node)


func get_room_node(room_id):
	return Globals.running_rooms_node.get_node(str(room_id))


func create_garbage_collection_timer():
	# timer countdown every Globals.GARBAGE_COLLECTION_INTERVAL seconds
	var timer = Timer.new()
	timer.set_wait_time(Globals.GARBAGE_COLLECTION_INTERVAL)
	timer.connect("timeout",self,"_garbage_collect") 
	add_child(timer)
	timer.start()


func _garbage_collect():
	# close rooms open for more than Globals.GARBAGE_COLLECTION_INTERVAL seconds
	for room_node in Globals.running_rooms_node.get_children():
		if room_node.creation_unixtime < OS.get_unix_time() - Globals.GARBAGE_COLLECTION_INTERVAL:
			room_node.close_room()
		else:
			# rooms are ordered by time, stop if encountered a relatively new room
			return
