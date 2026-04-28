package game

// games.strategy.engine.data.Unit
//
// One battlefield unit. Field set mirrors GameStateJsonSerializer.serializeUnit.

Unit :: struct {
	id:                          Uuid,
	type:                        ^Unit_Type,
	owner:                       ^Game_Player,
	hits:                        i32,
	transported_by:              ^Unit,
	unloaded:                    [dynamic]^Unit,
	was_loaded_this_turn:        bool,
	unloaded_to:                 ^Territory,
	was_unloaded_in_combat_phase: bool,
	already_moved:               f64,
	bonus_movement:              i32,
	unit_damage:                 i32,
	submerged:                   bool,
	original_owner:              ^Game_Player,
	was_in_combat:               bool,
	was_loaded_after_combat:     bool,
	was_amphibious:              bool,
	originated_from:             ^Territory,
	was_scrambled:               bool,
	max_scramble_count:          i32,
	was_in_air_battle:           bool,
	disabled:                    bool,
	launched:                    i32,
	airborne:                    bool,
	charged_flat_fuel_cost:      bool,
}
