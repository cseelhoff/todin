package game

Conduct_Bombing_2 :: struct {
	using i_executable: I_Executable,
	this_0:             ^Strategic_Bombing_Raid_Battle_Conduct_Bombing,
}

conduct_bombing_2_new :: proc(outer: ^Strategic_Bombing_Raid_Battle_Conduct_Bombing) -> ^Conduct_Bombing_2 {
	self := new(Conduct_Bombing_2)
	self.this_0 = outer
	return self
}
