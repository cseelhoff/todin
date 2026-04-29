package game

Abstract_Battle :: struct {
	battle_id: Uuid,
	headless: bool,
	battle_site: ^Territory,
	attacker: ^Game_Player,
	defender: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
	round: i32,
	is_bombing_run: bool,
	is_amphibious: bool,
	battle_type: I_Battle_Battle_Type,
	is_over: bool,
	dependent_units: map[^Unit][dynamic]^Unit,
	attacking_units: [dynamic]^Unit,
	defending_units: [dynamic]^Unit,
	amphibious_land_attackers: [dynamic]^Unit,
	bombarding_units: [dynamic]^Unit,
	territory_effects: [dynamic]^Territory_Effect,
	battle_result_description: Battle_Record_Battle_Result_Description,
	who_won: I_Battle_Who_Won,
	attacker_lost_tuv: i32,
	defender_lost_tuv: i32,
	game_data: ^Game_Data,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.AbstractBattle

