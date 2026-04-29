package game

// games.strategy.engine.data.Unit
//
// One battlefield unit. Field set mirrors GameStateJsonSerializer.serializeUnit.

Unit_Property_Name :: enum {
	Transported_By,
	Unloaded,
	Loaded_This_Turn,
	Unloaded_To,
	Unloaded_In_Combat_Phase,
	Already_Moved,
	Bonus_Movement,
	Submerged,
	Was_In_Combat,
	Loaded_After_Combat,
	Unloaded_Amphibious,
	Originated_From,
	Was_Scrambled,
	Max_Scramble_Count,
	Was_In_Air_Battle,
	Launched,
	Airborne,
	Charged_Flat_Fuel_Cost,
}

Unit :: struct {
	using game_data_component:    Game_Data_Component,
	id:                           Uuid,
	type:                         ^Unit_Type,
	owner:                        ^Game_Player,
	hits:                         i32,
	transported_by:               ^Unit,
	unloaded:                     [dynamic]^Unit,
	was_loaded_this_turn:         bool,
	unloaded_to:                  ^Territory,
	was_unloaded_in_combat_phase: bool,
	already_moved:                f64,
	bonus_movement:               i32,
	unit_damage:                  i32,
	submerged:                    bool,
	original_owner:               ^Game_Player,
	was_in_combat:                bool,
	was_loaded_after_combat:      bool,
	was_amphibious:               bool,
	originated_from:              ^Territory,
	was_scrambled:                bool,
	max_scramble_count:           i32,
	was_in_air_battle:            bool,
	disabled:                     bool,
	launched:                     i32,
	airborne:                     bool,
	charged_flat_fuel_cost:       bool,
}

Unit_Deserialization_Error_Lazy_Message :: struct {
	shown_error: bool,
}
