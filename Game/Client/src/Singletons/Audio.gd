extends Node

onready var bg_menu_music = get_node('BgMenuMusic')
onready var bg_menu_tween = bg_menu_music.get_node('BgMenuTween')
onready var bg_game_music = get_node('BgGameMusic')
onready var bg_game_tween = bg_game_music.get_node('BgGameTween')
onready var catch_sfx = get_node('PlayerEliminationSFX')
onready var hit_wall_sfx = get_node('HitWall')


func play_sfx(_event):
	pass
	"""
	if event == 'catch':
		catch_sfx._set_playing(true)
		
	elif event == 'hit_wall':
		hit_wall_sfx._set_playing(true)
	"""


func play_music(game_state):
	bg_menu_tween.stop_all()
	bg_game_tween.stop_all()
	match game_state:
		'menu':
			if not bg_menu_music.is_playing():
				# fade-out
				bg_game_tween.interpolate_property(bg_game_music, 'volume_db', bg_game_music.volume_db, -55, 3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				bg_game_tween.start()
				# fade-in
				bg_menu_music._set_playing(true)
				bg_menu_tween.interpolate_property(bg_menu_music, 'volume_db', bg_menu_music.volume_db, -28, 3, Tween.TRANS_QUART, Tween.EASE_OUT, 0.5)
				bg_menu_tween.start()
	
		'game':
			if not bg_game_music.is_playing():
				# fade-out
				bg_menu_tween.interpolate_property(bg_menu_music, 'volume_db', bg_menu_music.volume_db, -55, 3, Tween.TRANS_LINEAR, Tween.EASE_OUT)
				bg_menu_tween.start()
				# fade-in
				bg_game_music._set_playing(true)
				bg_game_tween.interpolate_property(bg_game_music, 'volume_db', bg_game_music.volume_db, -32, 3, Tween.TRANS_QUART, Tween.EASE_OUT, 0.5)
				bg_game_tween.start()


func _on_BgMenuTween_tween_completed(_object, _key):
	if bg_menu_music.volume_db == -55:
		bg_menu_music._set_playing(false)


func _on_BgGameTween_tween_completed(_object, _key):
	if bg_game_music.volume_db == -55:
		bg_game_music._set_playing(false)

