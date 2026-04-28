package game

Aa_In_Move_Util :: struct {
	bridge:          ^I_Delegate_Bridge,
	player:          ^Game_Player,
	casualties:      [dynamic]^Unit,
	execution_stack: ^Execution_Stack,
}

