extends Node2D

func init_globals():
	# init some of the user's global values
	Globals.round_number = 1
	Globals.total_rounds = 6
	Globals.player_name = null
	Globals.player_team = 'Unassigned'
	Globals.room_id = null
	Globals.is_host = false
	Globals.catchers_team = 'Team1'
	Globals.teams_players = null
	Globals.captures = {}
	Globals.team_won = null


func prepare_for_rematch():
	Globals.round_number = 1
	Globals.catchers_team = 'Team1'
	Globals.captures = {}
	Globals.team_won = null
	Globals.teams_players = null
