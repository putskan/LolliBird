extends MarginContainer

func _on_Go_pressed():
	var nickname = self.find_node('NicknameInput', true, false).text
	if nickname != '':
		self.find_node('Go', true, false).disabled = true
		Server.request_player_login('create', nickname, null)
