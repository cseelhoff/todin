package game

Firing_Group_Splitter_Aa :: struct {
	side: Battle_State_Side,
}

firing_group_splitter_aa_new :: proc(side: Battle_State_Side) -> ^Firing_Group_Splitter_Aa {
	self := new(Firing_Group_Splitter_Aa)
	self.side = side
	return self
}

// Static constructor: @Value(staticConstructor = "of") on FiringGroupSplitterAa.
firing_group_splitter_aa_of :: proc(side: Battle_State_Side) -> ^Firing_Group_Splitter_Aa {
	return firing_group_splitter_aa_new(side)
}

