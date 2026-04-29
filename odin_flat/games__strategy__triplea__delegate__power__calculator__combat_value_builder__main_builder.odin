package game

// Lombok @Builder for CombatValueBuilder.buildMainCombatValue.
// Java owner: games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$MainBuilder

Combat_Value_Builder_Main_Builder :: struct {
	enemy_units:         [dynamic]^Unit,
	friendly_units:      [dynamic]^Unit,
	side:                Battle_State_Side,
	game_sequence:       ^Game_Sequence,
	support_attachments: [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers:  bool,
	game_dice_sides:     int,
	territory_effects:   [dynamic]^Territory_Effect,
}

