extends Control

var current_scene
var drag_position = null
var teams_parent
var teams_rect_nodes
onready var bird_name = get_node("VBoxContainer/PlayerName").text

func _ready():
	yield(get_tree(),"idle_frame")
	current_scene = get_tree().get_current_scene()
	current_scene.all_lobby_birds.append(self)
	teams_parent = get_tree().get_current_scene().get_node('VBoxContainer/Teams')
	teams_rect_nodes = [current_scene.get_node('VBoxContainer/Teams/Team1'),
						current_scene.get_node('VBoxContainer/Teams/Team2'), 
						current_scene.get_node('VBoxContainer/Unassigned')]


func drag_lobby_bird(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# the point in the window where we clicked 
			# (so the top left corner of the object won't move to the mouse pos)
			drag_position = get_global_mouse_position() - rect_global_position
		else:
			# end dragging & move to relevant container
			var team_name_to_move_to = get_parent().get_parent().name
			for team_node in teams_rect_nodes:
				# check if a valid place to move to
				if team_node.name != team_name_to_move_to and is_control_inside_control(self.get_node("VBoxContainer/CenterContainer/Control"), team_node):
					team_name_to_move_to = team_node.name
					# notify the server of a bird move
					Server.multicast_lobby_bird_move(bird_name, team_name_to_move_to)
					break
			
			# create a bird and remove this one (other method causes bugs)
			current_scene.add_birds_to_teams({team_name_to_move_to: [bird_name]})
			current_scene.all_lobby_birds.erase(self)
			if bird_name == Globals.player_name:
				Globals.player_team = team_name_to_move_to
			queue_free()

	if drag_position and event is InputEventMouseMotion:
		rect_global_position = get_global_mouse_position() - drag_position


func is_control_inside_control(c1, c2):
	# check if a control is inside another control's rectangle, at least partially (visually)
	# i.e., if c1's top-left corner position is between c2's top-left and right-bottom corners.
	# Note: in Godot y-axis if inveresed (i.e., down -> y is bigger)
	var c1_top_left = c1.rect_global_position
	var c2_top_left = c2.rect_global_position
	var c2_buttom_right = Vector2(c2_top_left.x + c2.get_size().x, c2_top_left.y + c2.get_size().y)
	var is_inside = c1_top_left.x > c2_top_left.x and c1_top_left.x < c2_buttom_right.x and c1_top_left.y > c2_top_left.y and c1_top_left.y < c2_buttom_right.y
	return is_inside


func _on_LobbyBird_gui_input(event):
	drag_lobby_bird(event)


func _on_Control_gui_input(event):
	drag_lobby_bird(event)
