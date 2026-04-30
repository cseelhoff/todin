package game

Firing_Group_Splitter_Aa :: struct {
	side: Battle_State_Side,
}

firing_group_splitter_aa_new :: proc(side: Battle_State_Side) -> ^Firing_Group_Splitter_Aa {
	self := new(Firing_Group_Splitter_Aa)
	self.side = side
	return self
}

