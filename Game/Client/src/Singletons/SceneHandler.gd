extends Node

func handle_scene_change(event):
	var scene_path
	if event == 'login_success':
		print('hola')
		call_deferred('_deferred_change_scene', 'res://src/UI/GameLobby.tscn')
		
	elif event == 'game_created':
		call_deferred('_deferred_change_scene', 'res://src/UI/PlayerLogin.tscn')


func _deferred_change_scene(new_scene_path):
	var root = get_tree().get_root()
	var current_scene = root.get_child(root.get_child_count() - 1)
	current_scene.free()
	current_scene = load(new_scene_path).instance()
	root.add_child(current_scene)
	get_tree().set_current_scene(current_scene)
