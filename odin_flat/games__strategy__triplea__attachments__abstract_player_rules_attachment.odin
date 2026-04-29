package game

// Port of games.strategy.triplea.attachments.AbstractPlayerRulesAttachment.
// Phase A: type only.

ABSTRACT_PLAYER_RULES_ATTACHMENT_MOVEMENT_RESTRICTION_TYPE_ALLOWED :: "allowed"
ABSTRACT_PLAYER_RULES_ATTACHMENT_MOVEMENT_RESTRICTION_TYPE_DISALLOWED :: "disallowed"

Abstract_Player_Rules_Attachment :: struct {
	using abstract_rules_attachment: Abstract_Rules_Attachment,
	movement_restriction_type: string,
	movement_restriction_territories: [dynamic]string,
	placement_any_territory: bool,
	placement_any_sea_zone: bool,
	placement_captured_territory: bool,
	unlimited_production: bool,
	placement_in_capital_restricted: bool,
	dominating_first_round_attack: bool,
	negate_dominating_first_round_attack: bool,
	production_per_x_territories: ^Integer_Map,
	placement_per_territory: i32,
	max_place_per_territory: i32,
}

