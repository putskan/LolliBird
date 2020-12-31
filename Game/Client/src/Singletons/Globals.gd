extends Node

# general vars
const ROOM_ID_LENGTH = 4
const TEAM_1_NOTATION = 'Team1'
const TEAM_2_NOTATION = 'Team2'
const UNASSIGNED_TEAM_NOTATION = 'Unassigned'

const CATCHERS_COLLISION_BIT = 1
const RUNNERS_COLLISION_BIT = 2
const END_OF_MAP_COLLISION_BIT = 3

# player related
var round_number = 1
var total_rounds = 6
var player_id
var player_name
var player_team = 'Unassigned'
var room_id
var is_host
var catchers_team = 'Team1'
var teams_players = null
var captures = {}
var small_dynamic_font_res = preload("res://src/UI/themes/main_font_small_size.tres")
