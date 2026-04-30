package game

// Java owners covered by this file:
//   - games.strategy.triplea.attachments.RelationshipTypeAttachment

Relationship_Type_Attachment :: struct {
	using default_attachment: Default_Attachment,
	arche_type: string,
	can_move_land_units_over_owned_land: string,
	can_move_air_units_over_owned_land: string,
	alliances_can_chain_together: string,
	is_default_war_position: string,
	upkeep_cost: string,
	can_land_air_units_on_owned_land: string,
	can_take_over_owned_territory: string,
	gives_back_original_territories: string,
	can_move_into_during_combat_move: string,
	can_move_through_canals: string,
	rockets_can_fly_over: string,
}

// Mirrors `Constants.RELATIONSHIP_ARCHETYPE_*` / `Constants.RELATIONSHIP_PROPERTY_*`
// used by `RelationshipTypeAttachment`.
RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL :: "neutral"
RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR :: "war"
RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED :: "allied"
RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT :: "default"
RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE :: "true"
RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_FALSE :: "false"

// games.strategy.triplea.attachments.RelationshipTypeAttachment#get(RelationshipType, String)
//   static RelationshipTypeAttachment get(RelationshipType pr, String nameOfAttachment) {
//       return getAttachment(pr, nameOfAttachment, RelationshipTypeAttachment.class);
//   }
// `DefaultAttachment.getAttachment` is a `NamedAttachable.getAttachment(name)`
// lookup followed by an `Optional.orElseThrow` cast. `Relationship_Type` embeds
// `Named_Attachable`, whose `attachments` map already holds `^I_Attachment`
// values — an unset key returns `nil`, matching Java's
// `Optional.orElseThrow(...)` only diverging in that the Odin port returns
// `nil` instead of raising IllegalStateException (the same convention every
// other ported `get(..)` static accessor in the port follows, e.g.
// `game_player.odin`'s player/rules attachment getters).
relationship_type_attachment_get :: proc(pr: ^Relationship_Type, name_of_attachment: string) -> ^Relationship_Type_Attachment {
	return cast(^Relationship_Type_Attachment)named_attachable_get_attachment(&pr.named_attachable, name_of_attachment)
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#isWar()
relationship_type_attachment_is_war :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.arche_type == RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#isAllied()
relationship_type_attachment_is_allied :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.arche_type == RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#isNeutral()
relationship_type_attachment_is_neutral :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.arche_type == RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canMoveIntoDuringCombatMove()
//   return canMoveIntoDuringCombatMove.equals(PROPERTY_DEFAULT)
//       || canMoveIntoDuringCombatMove.equals(PROPERTY_TRUE);
relationship_type_attachment_can_move_into_during_combat_move :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.can_move_into_during_combat_move == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT ||
		self.can_move_into_during_combat_move == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canRocketsFlyOver()
//   return rocketsCanFlyOver.equals(PROPERTY_DEFAULT)
//       || rocketsCanFlyOver.equals(PROPERTY_TRUE);
relationship_type_attachment_can_rockets_fly_over :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.rockets_can_fly_over == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT ||
		self.rockets_can_fly_over == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#givesBackOriginalTerritories()
//   return !givesBackOriginalTerritories.equals(PROPERTY_DEFAULT)
//       && givesBackOriginalTerritories.equals(PROPERTY_TRUE);
relationship_type_attachment_gives_back_original_territories :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.gives_back_original_territories != RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT &&
		self.gives_back_original_territories == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#getUpkeepCost()
//   if (upkeepCost.equals(PROPERTY_DEFAULT)) { return String.valueOf(0); }
//   return upkeepCost;
relationship_type_attachment_get_upkeep_cost :: proc(self: ^Relationship_Type_Attachment) -> string {
	if self.upkeep_cost == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return "0"
	}
	return self.upkeep_cost
}
