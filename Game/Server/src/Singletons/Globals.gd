extends Node

const TEAM_1_NOTATION = 'Team1'
const TEAM_2_NOTATION = 'Team2'
const UNASSIGNED_TEAM_NOTATION = 'Unassigned'

var room_resource = preload('res://src/Room.tscn') 
var player_resource = preload('res://src/Player.tscn')
var running_rooms_ids = []
onready var running_rooms_node = get_tree().get_root().get_node('RunningRooms')
