package game

Move_Performer_1 :: struct {
	using i_executable: I_Executable,
	outer:        ^Move_Performer,
	route:        ^Route,
	units:        [dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.MovePerformer$1

move_performer_1_new :: proc(this0: ^Move_Performer, route: ^Route, collection: [dynamic]^Unit) -> ^Move_Performer_1 {
	self := new(Move_Performer_1)
	self.outer = this0
	self.route = route
	self.units = collection
	return self
}

