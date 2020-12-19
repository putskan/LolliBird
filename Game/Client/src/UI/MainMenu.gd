extends MarginContainer

func _on_CreateGame_pressed():
	$VBoxContainer/CreateGame.disabled = true
	SceneHandler.handle_scene_change('start_game_creation')


