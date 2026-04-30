package game

// Ported from games.strategy.triplea.ai.pro.ProCombatMoveAi (Phase A: type only).

Pro_Combat_Move_Ai :: struct {
	ai:                ^Abstract_Pro_Ai,
	pro_data:          ^Pro_Data,
	calc:              ^Pro_Odds_Calculator,
	data:              ^Game_Data,
	player:            ^Game_Player,
	territory_manager: ^Pro_Territory_Manager,
	is_defensive:      bool,
	is_bombing:        bool,
}

pro_combat_move_ai_is_bombing :: proc(self: ^Pro_Combat_Move_Ai) -> bool {
	return self.is_bombing
}

