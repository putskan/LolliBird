extends Node

func handle_scene_change(event):
	if event == 'start_join_game':
		call_deferred('_deferred_change_scene', 'res://src/UI/JoinRoom.tscn')
		
	elif event == 'get_player_prefs':
		call_deferred('_deferred_change_scene', 'res://src/UI/UserPrefs.tscn')
		
	# after choosing nickname and such
	elif event == 'GoToLobby':
		call_deferred('_deferred_change_scene', 'res://src/UI/GameLobby.tscn')
	
	elif event == 'StartGameScene':
		call_deferred('_deferred_change_scene', 'res://src/Game/Game.tscn')
	
	elif event == 'BackButtonPress':
		call_deferred('_deferred_change_scene', 'res://src/UI/MainMenu.tscn')
	
	elif event == 'GameOver':
		call_deferred('_deferred_change_scene', 'res://src/UI/GameOver.tscn')


func _deferred_change_scene(new_scene_path):
	print(new_scene_path)
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	current_scene.free()
	current_scene = load(new_scene_path).instance()
	root.add_child(current_scene)
	get_tree().set_current_scene(current_scene)
