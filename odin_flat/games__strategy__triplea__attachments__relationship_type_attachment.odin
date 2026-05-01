package game

import "core:fmt"
import "core:strings"

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

// games.strategy.triplea.attachments.RelationshipTypeAttachment#get(RelationshipType)
//   public static RelationshipTypeAttachment get(final RelationshipType pr) {
//       return get(pr, Constants.RELATIONSHIPTYPE_ATTACHMENT_NAME);
//   }
// `Constants.RELATIONSHIPTYPE_ATTACHMENT_NAME` is the literal
// "relationshipTypeAttachment" (see references in `my_formatter.odin` and
// `xml_game_element_mapper.odin`); inlined here as the `Constants` shim
// does not yet export the field.
relationship_type_attachment_get_1 :: proc(pr: ^Relationship_Type) -> ^Relationship_Type_Attachment {
	return relationship_type_attachment_get(pr, "relationshipTypeAttachment")
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#setArcheType(String)
//   final String lowerArcheType = archeType.toLowerCase(Locale.ROOT);
//   switch (lowerArcheType) {
//     case ARCHETYPE_WAR, ARCHETYPE_ALLIED, ARCHETYPE_NEUTRAL ->
//         this.archeType = lowerArcheType.intern();
//     default -> throw new GameParseException("archeType must be ...");
//   }
// Java raises GameParseException on an invalid value; the Odin port
// follows the project's `canal_attachment_set_land_territories`
// convention and `panicf`s with the same message. On a valid match the
// canonical constant string is stored (Java's `intern()` is unnecessary
// in Odin).
relationship_type_attachment_set_arche_type :: proc(self: ^Relationship_Type_Attachment, arche_type: string) {
	lower := strings.to_lower(arche_type)
	defer delete(lower)
	switch lower {
	case RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR:
		self.arche_type = RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR
	case RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED:
		self.arche_type = RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED
	case RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL:
		self.arche_type = RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL
	case:
		err := default_attachment_this_error_msg(&self.default_attachment)
		defer delete(err)
		fmt.panicf(
			"archeType must be %s,%s or %s for %s",
			RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_WAR,
			RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_ALLIED,
			RELATIONSHIP_TYPE_ATTACHMENT_ARCHETYPE_NEUTRAL,
			err,
		)
	}
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canMoveAirUnitsOverOwnedLand()
//   if (canMoveAirUnitsOverOwnedLand.equals(PROPERTY_DEFAULT)) {
//       return isWar() || isAllied();
//   }
//   return canMoveAirUnitsOverOwnedLand.equals(PROPERTY_TRUE);
relationship_type_attachment_can_move_air_units_over_owned_land :: proc(self: ^Relationship_Type_Attachment) -> bool {
	if self.can_move_air_units_over_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return relationship_type_attachment_is_war(self) || relationship_type_attachment_is_allied(self)
	}
	return self.can_move_air_units_over_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canMoveLandUnitsOverOwnedLand()
//   if (canMoveLandUnitsOverOwnedLand.equals(PROPERTY_DEFAULT)) {
//       return isWar() || isAllied();
//   }
//   return canMoveLandUnitsOverOwnedLand.equals(PROPERTY_TRUE);
relationship_type_attachment_can_move_land_units_over_owned_land :: proc(self: ^Relationship_Type_Attachment) -> bool {
	if self.can_move_land_units_over_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return relationship_type_attachment_is_war(self) || relationship_type_attachment_is_allied(self)
	}
	return self.can_move_land_units_over_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canLandAirUnitsOnOwnedLand()
//   if (canLandAirUnitsOnOwnedLand.equals(PROPERTY_DEFAULT)) { return isAllied(); }
//   return canLandAirUnitsOnOwnedLand.equals(PROPERTY_TRUE);
relationship_type_attachment_can_land_air_units_on_owned_land :: proc(self: ^Relationship_Type_Attachment) -> bool {
	if self.can_land_air_units_on_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return relationship_type_attachment_is_allied(self)
	}
	return self.can_land_air_units_on_owned_land == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canTakeOverOwnedTerritory()
//   if (canTakeOverOwnedTerritory.equals(PROPERTY_DEFAULT)) { return isWar(); }
//   return canTakeOverOwnedTerritory.equals(PROPERTY_TRUE);
relationship_type_attachment_can_take_over_owned_territory :: proc(self: ^Relationship_Type_Attachment) -> bool {
	if self.can_take_over_owned_territory == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return relationship_type_attachment_is_war(self)
	}
	return self.can_take_over_owned_territory == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canAlliancesChainTogether()
//   return !alliancesCanChainTogether.equals(PROPERTY_DEFAULT)
//       && !isWar()
//       && !isNeutral()
//       && alliancesCanChainTogether.equals(PROPERTY_TRUE);
relationship_type_attachment_can_alliances_chain_together :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.alliances_can_chain_together != RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT &&
		!relationship_type_attachment_is_war(self) &&
		!relationship_type_attachment_is_neutral(self) &&
		self.alliances_can_chain_together == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#isDefaultWarPosition()
//   return !isDefaultWarPosition.equals(PROPERTY_DEFAULT)
//       && !isAllied()
//       && !isNeutral()
//       && isDefaultWarPosition.equals(PROPERTY_TRUE);
relationship_type_attachment_is_default_war_position :: proc(self: ^Relationship_Type_Attachment) -> bool {
	return self.is_default_war_position != RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT &&
		!relationship_type_attachment_is_allied(self) &&
		!relationship_type_attachment_is_neutral(self) &&
		self.is_default_war_position == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}

// games.strategy.triplea.attachments.RelationshipTypeAttachment#canMoveThroughCanals()
//   if (canMoveThroughCanals.equals(PROPERTY_DEFAULT)) { return isAllied(); }
//   return canMoveThroughCanals.equals(PROPERTY_TRUE);
relationship_type_attachment_can_move_through_canals :: proc(self: ^Relationship_Type_Attachment) -> bool {
	if self.can_move_through_canals == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_DEFAULT {
		return relationship_type_attachment_is_allied(self)
	}
	return self.can_move_through_canals == RELATIONSHIP_TYPE_ATTACHMENT_PROPERTY_TRUE
}
