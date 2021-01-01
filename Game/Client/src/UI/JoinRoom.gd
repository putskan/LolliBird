extends MarginContainer

var room_id = null
onready var join_button = get_node("CenterContainer/VBoxContainer/VBoxContainer/Join")
onready var error_label = get_node("CenterContainer/VBoxContainer/VBoxContainer/ErrorMsg")

func handle_join_response(is_room_id_valid):
		if is_room_id_valid:
			Globals.room_id = room_id
			SceneHandler.handle_scene_change('get_player_prefs')
		
		else:
			handle_input_error('Error: Wrong PIN Entered')


func handle_input_error(error_msg):
	join_button.disabled = false
	error_label.text = error_msg


func _on_Join_pressed():
	var room_id_str = self.find_node('RoomIDInput', true, false).text
	if room_id_str.length() == Globals.ROOM_ID_LENGTH:
		join_button.disabled = true
		room_id = int(room_id_str)
		Server.request_room_id_join_validation(room_id)
		# waiting for repsonse from server
	else:
		room_id = null
		handle_input_error('Error: Wrong PIN Entered')
