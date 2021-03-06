extends MarginContainer

func _ready():
	Audio.play_music('menu')
	HelperFunctions.init_globals()
	
func _on_CreateGame_pressed():
	_disable_buttons()
	Server.request_room_creation()
	SceneHandler.handle_scene_change('get_player_prefs')


func _on_JoinGame_pressed():
	_disable_buttons()
	SceneHandler.handle_scene_change('start_join_game')


func _disable_buttons():
	$VBoxContainer/CreateGame.disabled = true

