package game

Add_Available_Tech :: struct {
	using change: Change,
	tech: ^Tech_Advance,
	frontier: ^Technology_Frontier,
	player: ^Game_Player,
}

add_available_tech_new :: proc(front: ^Technology_Frontier, tech: ^Tech_Advance, player: ^Game_Player) -> ^Add_Available_Tech {
	assert(front != nil)
	assert(tech != nil)
	self := new(Add_Available_Tech)
	self.tech = tech
	self.frontier = front
	self.player = player
	return self
}
