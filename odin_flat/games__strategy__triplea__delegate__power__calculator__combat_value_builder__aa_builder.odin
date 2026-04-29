package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$AaBuilder

Combat_Value_Builder_Aa_Builder :: struct {
	enemy_units:         [dynamic]^Unit,
	friendly_units:      [dynamic]^Unit,
	side:                Battle_State_Side,
	support_attachments: [dynamic]^Unit_Support_Attachment,
}
