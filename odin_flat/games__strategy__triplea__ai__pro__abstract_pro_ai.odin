package game

Abstract_Pro_Ai :: struct {
	using abstract_ai: Abstract_Ai,

	calc:     ^Pro_Odds_Calculator,
	pro_data: ^Pro_Data,

	// Phases
	combat_move_ai:     ^Pro_Combat_Move_Ai,
	non_combat_move_ai: ^Pro_Non_Combat_Move_Ai,
	purchase_ai:        ^Pro_Purchase_Ai,
	retreat_ai:         ^Pro_Retreat_Ai,
	scramble_ai:        ^Pro_Scramble_Ai,
	politics_ai:        ^Pro_Politics_Ai,

	// Data shared across phases
	stored_combat_move_map:      map[^Territory]^Pro_Territory,
	stored_factory_move_map:     map[^Territory]^Pro_Territory,
	stored_purchase_territories: map[^Territory]^Pro_Purchase_Territory,
	stored_political_actions:    [dynamic]^Political_Action_Attachment,
	stored_strafing_territories: [dynamic]^Territory,
}

abstract_pro_ai_get_pro_data :: proc(self: ^Abstract_Pro_Ai) -> ^Pro_Data {
	return self.pro_data
}

abstract_pro_ai_get_calc :: proc(self: ^Abstract_Pro_Ai) -> ^Pro_Odds_Calculator {
	return self.calc
}

abstract_pro_ai_set_stored_strafing_territories :: proc(self: ^Abstract_Pro_Ai, strafing_territories: [dynamic]^Territory) {
	self.stored_strafing_territories = strafing_territories
}

abstract_pro_ai_has_non_combat_move :: proc(self: ^Abstract_Pro_Ai, steps: [dynamic]^Game_Step) -> bool {
	for s in steps {
		if game_step_is_non_combat_move_step_name(s.name) {
			return true
		}
	}
	return false
}
