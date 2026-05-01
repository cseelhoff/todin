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

// games.strategy.triplea.attachments.TerritoryEffectAttachment#get(TerritoryEffect, String)
//   static TerritoryEffectAttachment get(TerritoryEffect te, String nameOfAttachment) {
//       return getAttachment(te, nameOfAttachment, TerritoryEffectAttachment.class);
//   }
// `Territory_Effect` embeds `Named_Attachable`, whose attachment map stores
// `^I_Attachment` values keyed by name. Java's `getAttachment` would
// `Optional.orElseThrow` on a missing key; this port returns nil, matching
// the convention used by `relationship_type_attachment_get` and other
// sibling static accessors.
territory_effect_attachment_get :: proc(te: ^Territory_Effect, name_of_attachment: string) -> ^Territory_Effect_Attachment {
	return cast(^Territory_Effect_Attachment)named_attachable_get_attachment(&te.named_attachable, name_of_attachment)
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getCombatDefenseEffect()
//   private IntegerMap<UnitType> getCombatDefenseEffect() {
//       return getIntegerMapProperty(combatDefenseEffect);
//   }
// Java's `getIntegerMapProperty` substitutes a fresh empty IntegerMap when
// the field is null. The Odin field is an `Integer_Map` value (not a
// nullable pointer), so the unset state is already a zero-valued struct
// with a nil inner map — semantically equivalent to "empty" for reads.
territory_effect_attachment_get_combat_defense_effect :: proc(self: ^Territory_Effect_Attachment) -> Integer_Map {
	return self.combat_defense_effect
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getCombatOffenseEffect()
//   private IntegerMap<UnitType> getCombatOffenseEffect() {
//       return getIntegerMapProperty(combatOffenseEffect);
//   }
// See note on getCombatDefenseEffect — same passthrough rationale.
territory_effect_attachment_get_combat_offense_effect :: proc(self: ^Territory_Effect_Attachment) -> Integer_Map {
	return self.combat_offense_effect
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getMovementCostModifier()
//   public Map<UnitType, BigDecimal> getMovementCostModifier() {
//       return getMapProperty(movementCostModifier);
//   }
// `default_attachment_get_map_property` returns the map as-is (a nil map
// iterates as empty in Odin), matching Java's null→empty substitution.
territory_effect_attachment_get_movement_cost_modifier :: proc(self: ^Territory_Effect_Attachment) -> map[^Unit_Type]f64 {
	return default_attachment_get_map_property(self.movement_cost_modifier)
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getNoBlitz()
//   public List<UnitType> getNoBlitz() { return getListProperty(noBlitz); }
territory_effect_attachment_get_no_blitz :: proc(self: ^Territory_Effect_Attachment) -> [dynamic]^Unit_Type {
	return default_attachment_get_list_property(self.no_blitz)
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getUnitsNotAllowed()
//   public List<UnitType> getUnitsNotAllowed() { return getListProperty(unitsNotAllowed); }
territory_effect_attachment_get_units_not_allowed :: proc(self: ^Territory_Effect_Attachment) -> [dynamic]^Unit_Type {
	return default_attachment_get_list_property(self.units_not_allowed)
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#get(TerritoryEffect)
//   public static TerritoryEffectAttachment get(TerritoryEffect te) {
//       return get(te, Constants.TERRITORYEFFECT_ATTACHMENT_NAME);
//   }
// `Constants.TERRITORYEFFECT_ATTACHMENT_NAME` is the literal
// `"territoryEffectAttachment"` (Constants.java line 38). The 2-arg
// overload `territory_effect_attachment_get` already covers the lookup;
// this single-arg form just supplies the canonical attachment name.
// Suffix `_1` distinguishes this 1-arg overload from the 2-arg sibling
// already defined above in this file.
territory_effect_attachment_get_1 :: proc(te: ^Territory_Effect) -> ^Territory_Effect_Attachment {
	return territory_effect_attachment_get(te, "territoryEffectAttachment")
}

// games.strategy.triplea.attachments.TerritoryEffectAttachment#getCombatEffect(UnitType, boolean)
//   public int getCombatEffect(final UnitType type, final boolean defending) {
//       return defending
//           ? getCombatDefenseEffect().getInt(type)
//           : getCombatOffenseEffect().getInt(type);
//   }
// `Integer_Map.map_values` is keyed by `rawptr`; cast the `^Unit_Type`
// to `rawptr` for lookup. `integer_map_get_int` returns 0 for absent
// keys, matching Java's `IntegerMap.getInt` contract.
territory_effect_attachment_get_combat_effect :: proc(self: ^Territory_Effect_Attachment, type: ^Unit_Type, defending: bool) -> i32 {
	if defending {
		def := territory_effect_attachment_get_combat_defense_effect(self)
		return integer_map_get_int(&def, cast(rawptr)type)
	}
	off := territory_effect_attachment_get_combat_offense_effect(self)
	return integer_map_get_int(&off, cast(rawptr)type)
}

