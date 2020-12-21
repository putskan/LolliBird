extends MarginContainer

var room_id = null

func _on_Join_pressed():
	var room_id_str = self.find_node('RoomIDInput', true, false).text
	if room_id_str.length() == Globals.ROOM_ID_LENGTH:
		self.find_node('Join', true, false).disabled = true
		room_id = int(room_id_str)
		Server.request_room_id_join_validation(room_id)
		# waiting for repsonse from server
	else:
		room_id = null
		display_error('Room ID Not Found')


func handle_join_response(is_room_id_valid):
		if is_room_id_valid:
			Globals.room_id = room_id
			SceneHandler.handle_scene_change('get_player_prefs')
		
		else:
			display_error('Room ID Not Found')


func display_error(error_str):
	self.find_node('Join', true, false).disabled = false
	### add error to UI ###
	print(error_str)
