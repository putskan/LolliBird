extends Node

# general vars
const ROOM_ID_LENGTH = 4
const TEAM_1_NOTATION = 'Team1'
const TEAM_2_NOTATION = 'Team2'
const UNASSIGNED_TEAM_NOTATION = 'Unassigned'
const TEAMS_MAX_PLAYERS = {'Team1': 8, 'Team2': 8, 'Unassigned': 16}
const MAX_NAME_LENGTH = 12
const MAP_COLLISION_BIT = 0
const CATCHERS_COLLISION_BIT = 1
const RUNNERS_COLLISION_BIT = 2
const END_OF_MAP_COLLISION_BIT = 3
const INTERPOLATION_OFFSET = 100
var small_dynamic_font_res = preload("res://src/UI/themes/main_font_small_size.tres")
var client_clock = 0
var player_id

# first assigned in HelperFunctions:
var round_number
var total_rounds
var player_name
var player_team
var room_id
var is_host
var host_name
var catchers_team
var teams_players
var captures
var team_won
# used for off-tab sync
var first_round_start
