package game

// Port of games.strategy.triplea.attachments.TerritoryEffectAttachment.
// An attachment for instances of TerritoryEffect.
Territory_Effect_Attachment :: struct {
	using default_attachment: Default_Attachment,
	combat_defense_effect: Integer_Map,
	combat_offense_effect: Integer_Map,
	movement_cost_modifier: map[^Unit_Type]f64,
	no_blitz:              [dynamic]^Unit_Type,
	units_not_allowed:     [dynamic]^Unit_Type,
}

