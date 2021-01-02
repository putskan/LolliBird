extends Node

const TEAM_1_NOTATION = 'Team1'
const TEAM_2_NOTATION = 'Team2'
const UNASSIGNED_TEAM_NOTATION = 'Unassigned'
const ROOM_MAX_PLAYERS = 32

var room_resource = preload('res://src/Room.tscn') 
var running_rooms_ids = []
onready var running_rooms_node = get_tree().get_root().get_node('RunningRooms')
