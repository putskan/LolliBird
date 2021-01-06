extends MarginContainer

onready var win_announcement_label = get_node("CenterContainer/VBoxContainer/WinAnnouncement")
onready var play_again_node = get_node("CenterContainer/VBoxContainer/VBoxContainer/PlayAgain")
onready var back_node = get_node("CenterContainer/VBoxContainer/VBoxContainer/BackButton")


func _ready():
	Audio.play_music('menu')
	if Globals.team_won == 'Draw':
		win_announcement_label.text = win_announcement_label.text % (Globals.team_won + '!')
	else:
		win_announcement_label.text = win_announcement_label.text % (Globals.team_won + ' Won!')
	
	HelperFunctions.prepare_for_rematch()


func _on_BackButton_pressed():
	disable_buttons()


func _on_PlayAgain_pressed():
	disable_buttons()
	Server.request_player_creation(Globals.player_name, Globals.room_id, Globals.player_team)


func disable_buttons():
	play_again_node.disabled = true
	back_node.disabled = true

