extends MarginContainer


func _on_Go_pressed():
	var input_text = self.find_node('NicknameInput', true, false).text
	if input_text != '':
		self.find_node('Go', true, false).disabled = true
		Server.request_player_login({'nickname': input_text})


