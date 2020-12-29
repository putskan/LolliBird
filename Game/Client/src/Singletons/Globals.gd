extends Node

# general vars
const ROOM_ID_LENGTH = 4
const TEAM_1_NOTATION = 'Team1'
const TEAM_2_NOTATION = 'Team2'
const UNASSIGNED_TEAM_NOTATION = 'Unassigned'

# player related
var player_id
var player_name
var player_team = 'Unassigned'
var room_id
var is_host
var catchers_team = 'Team1'
# var room_players_dict = {}
var teams_players = null
