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

// Java: public AbstractProAi(String name, IBattleCalculator battleCalculator,
//                            ProData proData, String playerLabel)
abstract_pro_ai_new :: proc(
	name: string,
	battle_calculator: ^I_Battle_Calculator,
	pro_data: ^Pro_Data,
	player_label: string,
) -> ^Abstract_Pro_Ai {
	self := new(Abstract_Pro_Ai)
	// super(name, playerLabel)
	self.name = name
	self.player_label = player_label
	self.pro_data = pro_data
	self.calc = pro_odds_calculator_new(battle_calculator)
	self.combat_move_ai = pro_combat_move_ai_new(self)
	self.non_combat_move_ai = pro_non_combat_move_ai_new(self)
	self.purchase_ai = pro_purchase_ai_new(self)
	self.retreat_ai = pro_retreat_ai_new(self)
	self.scramble_ai = pro_scramble_ai_new(self)
	self.politics_ai = pro_politics_ai_new(self)
	self.stored_combat_move_map = nil
	self.stored_factory_move_map = nil
	self.stored_purchase_territories = nil
	self.stored_political_actions = nil
	self.stored_strafing_territories = make([dynamic]^Territory)
	return self
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
		if abstract_pro_ai_lambda__has_non_combat_move__0(s) {
			return true
		}
	}
	return false
}

// Java: s -> GameStep.isNonCombatMoveStepName(s.getName())
abstract_pro_ai_lambda__has_non_combat_move__0 :: proc(s: ^Game_Step) -> bool {
	return game_step_is_non_combat_move_step_name(s.name)
}

// Java: private static List<GameStep> getGameStepsForPlayer(
//           GameData gameData, GamePlayer gamePlayer, int startStep)
abstract_pro_ai_get_game_steps_for_player :: proc(
	game_data: ^Game_Data,
	game_player: ^Game_Player,
	start_step: i32,
) -> [dynamic]^Game_Step {
	step_index: i32 = 0
	game_steps: [dynamic]^Game_Step
	for game_step in game_sequence_iterator(game_data_get_sequence(game_data)) {
		if step_index >= start_step && game_player == game_step_get_player_id(game_step) {
			append(&game_steps, game_step)
		}
		step_index += 1
	}
	return game_steps
}

// Java: public boolean shouldBomberBomb(final Territory territory) {
//           return combatMoveAi.isBombing(); }
abstract_pro_ai_should_bomber_bomb :: proc(self: ^Abstract_Pro_Ai, territory: ^Territory) -> bool {
	return pro_combat_move_ai_is_bombing(self.combat_move_ai)
}
