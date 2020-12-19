extends Node2D

var room_id
var state = 'Lobby'
var current_round = 1
var total_rounds = 5
# the room's creator
var host_id
# consists Player objects for each team. 0 group is unassigned players
var teams = {
	0: [],
	1: [],
	2: []
}
