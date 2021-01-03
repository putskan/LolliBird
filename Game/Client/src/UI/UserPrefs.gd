extends MarginContainer

var player_name
onready var error_label = get_node("CenterContainer/VBoxContainer/VBoxContainer/ErrorMsg")
onready var button_node = get_node("CenterContainer/VBoxContainer/VBoxContainer/Create")
onready var input_node = get_node("CenterContainer/VBoxContainer/VBoxContainer/NicknameInput")


func _on_Create_pressed():
	player_name = input_node.text
	if player_name == '':
		handle_error('Please Enter A Valid Name')
		return

	if player_name.length() >= 8:
		handle_error('Name Too Long')
		return
		
	if not is_string_english(player_name):
		handle_error('Please use English characters')
		return
		
	button_node.disabled = true
	Globals.player_name = player_name
	Server.request_player_creation(player_name, Globals.room_id)


func handle_error(error_msg):
	input_node.text = ''
	button_node.disabled = false
	error_label.text = error_msg


func is_string_english(s):
	var regex = RegEx.new()
	regex.compile("[A-Za-z0-9_-]+")
	var result = regex.search(s)
	if not result or result.get_string() != s:
		return false
	return true


func _on_BackButton_pressed():
	# clear room resources if needed
	if Globals.is_host:
		Server.request_room_close(Globals.room_id)

