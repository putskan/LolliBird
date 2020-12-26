extends MarginContainer

var player_name

func _on_Create_pressed():
	player_name = self.find_node('NicknameInput', true, false).text
	if player_name != '' and player_name.length() < 10:
		self.find_node('Create', true, false).disabled = true
		Server.request_player_creation(player_name, Globals.room_id)


func handle_player_creation_response(error_message):
	if error_message:
		### send error in ui ###
		self.find_node('Create', true, false).disabled = false
		
	else:
		Globals.player_name = player_name
		SceneHandler.handle_scene_change('GoToLobby')
