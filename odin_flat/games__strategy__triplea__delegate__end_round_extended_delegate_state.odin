package game

End_Round_Extended_Delegate_State :: struct {
	super_state: rawptr,
	game_over:   bool,
	winners:     [dynamic]^Game_Player,
}

end_round_extended_delegate_state_new :: proc() -> ^End_Round_Extended_Delegate_State {
	self := new(End_Round_Extended_Delegate_State)
	self.super_state = nil
	self.game_over = false
	self.winners = make([dynamic]^Game_Player)
	return self
}

