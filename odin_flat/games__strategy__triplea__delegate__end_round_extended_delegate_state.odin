package game

End_Round_Extended_Delegate_State :: struct {
	super_state: rawptr,
	game_over:   bool,
	winners:     [dynamic]^Game_Player,
}

