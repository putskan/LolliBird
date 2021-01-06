extends Node2D
var off_tab_clock = OS.get_system_time_msecs()


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
	Globals.first_round_start = false


func prepare_for_rematch():
	Globals.round_number = 1
	Globals.catchers_team = 'Team1'
	Globals.captures = {}
	Globals.team_won = null
	Globals.teams_players = null
	Globals.first_round_start = false


func check_return_from_tab_switch():
	# return true if player was off-tab for more than 0.3 sec, false otherwise
	# update the clock anyway
	if Globals.off_tab_clock + 300 < OS.get_system_time_msecs():
		Globals.off_tab_clock = OS.get_system_time_msecs()
		return true
	Globals.off_tab_clock = OS.get_system_time_msecs()
	return false

