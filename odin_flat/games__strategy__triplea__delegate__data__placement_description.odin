package game

Placement_Description :: struct {
	using abstract_move_description: Abstract_Move_Description,
	territory: ^Territory,
}

placement_description_new :: proc(units: []^Unit, territory: ^Territory) -> ^Placement_Description {
	self := new(Placement_Description)
	self.abstract_move_description = make_Abstract_Move_Description(units)
	self.territory = territory
	return self
}
