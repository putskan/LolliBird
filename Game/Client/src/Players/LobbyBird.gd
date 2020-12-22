extends Control


var drag_position = null
var teams_parent
var teams_rect_nodes
var latest_pos


func _ready():
	yield(get_tree(),"idle_frame")
	var current_scene = get_tree().get_current_scene()
	print(current_scene.name)
	teams_parent = get_tree().get_current_scene().get_node('VBoxContainer/Teams')
	teams_rect_nodes = [current_scene.get_node('VBoxContainer/Teams/Team1'),
						current_scene.get_node('VBoxContainer/Teams/Team2'), 
						current_scene.get_node('VBoxContainer/Unassigned')]
	latest_pos = rect_global_position



func drag_lobby_bird(event):
	if event is InputEventMouseButton:
		if event.pressed:
			# the point in the window where we clicked 
			# (so the top left corner of the object won't move to the mouse pos)
			drag_position = get_global_mouse_position() - rect_global_position
		else:
			# end dragging & move to relevant team
			for team_node in teams_rect_nodes:
				# check if a valid place to move to
				if self.get_parent().get_parent() != team_node and is_control_inside_control(self.get_node("VBoxContainer/CenterContainer/Control"), team_node):
					get_parent().remove_child(self)
					team_node.get_node('BirdsContainer').add_child(self)
					print(self.get_parent().name)
					print(self.get_parent().get_parent().name)
					latest_pos = rect_global_position
					drag_position = null
					return

			# if not a valid spot to move to, restore to previous position
			print('b4: %s' % rect_global_position)
			rect_global_position = latest_pos
			print('after: %s' % rect_global_position)
			print('restoring')
			drag_position = null

	if event is InputEventMouseMotion and drag_position:
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
