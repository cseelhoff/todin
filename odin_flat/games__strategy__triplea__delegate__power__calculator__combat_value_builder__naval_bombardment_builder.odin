package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.power.calculator.CombatValueBuilder$NavalBombardmentBuilder

Combat_Value_Builder_Naval_Bombardment_Builder :: struct {
	enemy_units:          [dynamic]^Unit,
	friendly_units:       [dynamic]^Unit,
	support_attachments:  [dynamic]^Unit_Support_Attachment,
	lhtr_heavy_bombers:   bool,
	game_dice_sides:      int,
	territory_effects:    [dynamic]^Territory_Effect,
}
