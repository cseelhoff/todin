package game

Move_Performer_3 :: struct {
	using i_executable: I_Executable,
	outer: ^Move_Performer,
	game_player: ^Game_Player,
	units: [dynamic]^Unit,
	route: ^Route,
	units_to_transports: map[^Unit]^Unit,
}

move_performer_3_new :: proc(this0: ^Move_Performer, player: ^Game_Player, collection: [dynamic]^Unit, route: ^Route, the_map: map[^Unit]^Unit) -> ^Move_Performer_3 {
	self := new(Move_Performer_3)
	self.outer = this0
	self.game_player = player
	self.units = collection
	self.route = route
	self.units_to_transports = the_map
	return self
}

