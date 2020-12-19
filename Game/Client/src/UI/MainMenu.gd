extends MarginContainer

func _ready():
	pass


func _on_CreateGame_pressed():
	Server.request_game_creation()
	$VBoxContainer/CreateGame.disabled = true
	pass # Replace with function body.
