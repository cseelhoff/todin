package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TerritoryEffectHelper
//
// Utility class (private constructor) — no instance state.

Territory_Effect_Helper :: struct {}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getTerritoryCombatBonus(UnitType, Collection<TerritoryEffect>, boolean)
//   public static int getTerritoryCombatBonus(
//       final UnitType type, final Collection<TerritoryEffect> effects, final boolean defending) {
//     int combatBonus = 0;
//     for (final TerritoryEffect effect : effects) {
//       combatBonus += TerritoryEffectAttachment.get(effect).getCombatEffect(type, defending);
//     }
//     return combatBonus;
//   }
// `TerritoryEffectAttachment.get(TerritoryEffect)` is the 1-arg overload
// ported as `territory_effect_attachment_get_1`.
territory_effect_helper_get_territory_combat_bonus :: proc(
	type: ^Unit_Type,
	effects: [dynamic]^Territory_Effect,
	defending: bool,
) -> i32 {
	combat_bonus: i32 = 0
	for effect in effects {
		att := territory_effect_attachment_get_1(effect)
		combat_bonus += territory_effect_attachment_get_combat_effect(att, type, defending)
	}
	return combat_bonus
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getMovementCostModiferForUnitType(TerritoryEffect, UnitType)
//   private static BigDecimal getMovementCostModiferForUnitType(
//       final TerritoryEffect effect, final UnitType unitType) {
//     final Map<UnitType, BigDecimal> map =
//         TerritoryEffectAttachment.get(effect).getMovementCostModifier();
//     return map.getOrDefault(unitType, BigDecimal.ZERO);
//   }
// Movement-cost modifiers are stored as `f64` in this port (see
// `territory_effect_attachment_get_movement_cost_modifier`); Odin map
// indexing returns the zero value for absent keys, matching
// `getOrDefault(..., BigDecimal.ZERO)`.
territory_effect_helper_get_movement_cost_modifer_for_unit_type :: proc(
	effect: ^Territory_Effect,
	unit_type: ^Unit_Type,
) -> f64 {
	att := territory_effect_attachment_get_1(effect)
	m := territory_effect_attachment_get_movement_cost_modifier(att)
	if v, ok := m[unit_type]; ok {
		return v
	}
	return 0
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getEffects(games.strategy.engine.data.Territory)
//   public static Collection<TerritoryEffect> getEffects(final Territory location) {
//     return TerritoryAttachment.get(location)
//         .map(TerritoryAttachment::getTerritoryEffect)
//         .orElse(new ArrayList<>());
//   }
// `territory_attachment_get` returns a nullable `^Territory_Attachment`
// (nil for water territories with no attachment), which matches the
// Java `Optional` returned by `TerritoryAttachment.get`. When absent,
// return a fresh empty list, matching Java's `orElse(new ArrayList<>())`.
territory_effect_helper_get_effects :: proc(
	location: ^Territory,
) -> [dynamic]^Territory_Effect {
	att := territory_attachment_get(location)
	if att == nil {
		return make([dynamic]^Territory_Effect)
	}
	return territory_attachment_get_territory_effect(att)
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#unitTypeLoosesBlitz(UnitType, Territory)
//   private static boolean unitTypeLoosesBlitz(final UnitType type, final Territory location) {
//     checkNotNull(type);
//     checkNotNull(location);
//     for (final TerritoryEffect effect : getEffects(location)) {
//       if (TerritoryEffectAttachment.get(effect).getNoBlitz().contains(type)) {
//         return true;
//       }
//     }
//     return false;
//   }
// `checkNotNull` is enforced via Odin's typed pointer parameters at the
// call site; explicit nil checks here would be redundant.
territory_effect_helper_unit_type_looses_blitz :: proc(
	type: ^Unit_Type,
	location: ^Territory,
) -> bool {
	effects := territory_effect_helper_get_effects(location)
	for effect in effects {
		att := territory_effect_attachment_get_1(effect)
		no_blitz := territory_effect_attachment_get_no_blitz(att)
		for ut in no_blitz {
			if ut == type {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getUnitTypesThatLostBlitz(Collection<Territory>)
//   public static Set<UnitType> getUnitTypesThatLostBlitz(final Collection<Territory> steps) {
//     final Set<UnitType> unitTypes = new HashSet<>();
//     for (final Territory location : steps) {
//       for (final TerritoryEffect effect : getEffects(location)) {
//         unitTypes.addAll(TerritoryEffectAttachment.get(effect).getNoBlitz());
//       }
//     }
//     return unitTypes;
//   }
// Set<UnitType> is represented as `map[^Unit_Type]struct {}`, matching
// the pattern used by `unit_attachment_get_allowed_bombing_targets_intersection`.
territory_effect_helper_get_unit_types_that_lost_blitz :: proc(
	steps: [dynamic]^Territory,
) -> map[^Unit_Type]struct {} {
	unit_types: map[^Unit_Type]struct {}
	for location in steps {
		effects := territory_effect_helper_get_effects(location)
		for effect in effects {
			att := territory_effect_attachment_get_1(effect)
			no_blitz := territory_effect_attachment_get_no_blitz(att)
			for ut in no_blitz {
				unit_types[ut] = {}
			}
		}
	}
	return unit_types
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getUnitTypesForUnitsNotAllowedIntoTerritory(Territory)
//   public static Set<UnitType> getUnitTypesForUnitsNotAllowedIntoTerritory(
//       final Territory location) {
//     final Set<UnitType> unitTypes = new HashSet<>();
//     for (final TerritoryEffect effect : getEffects(location)) {
//       unitTypes.addAll(TerritoryEffectAttachment.get(effect).getUnitsNotAllowed());
//     }
//     return unitTypes;
//   }
territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory :: proc(
	location: ^Territory,
) -> map[^Unit_Type]struct {} {
	unit_types: map[^Unit_Type]struct {}
	effects := territory_effect_helper_get_effects(location)
	for effect in effects {
		att := territory_effect_attachment_get_1(effect)
		not_allowed := territory_effect_attachment_get_units_not_allowed(att)
		for ut in not_allowed {
			unit_types[ut] = {}
		}
	}
	return unit_types
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getMaxMovementCost(Territory, Collection<Unit>)
//   public static BigDecimal getMaxMovementCost(final Territory t, final Collection<Unit> units) {
//     if (getEffects(t).isEmpty() || units.isEmpty()) {
//       return BigDecimal.ONE;
//     }
//     BigDecimal max = new BigDecimal(Integer.MIN_VALUE);
//     for (final Unit unit : units) {
//       BigDecimal movementCost = BigDecimal.ONE;
//       for (final TerritoryEffect effect : getEffects(t)) {
//         movementCost = movementCost.add(getMovementCostModiferForUnitType(effect, unit.getType()));
//       }
//       if (movementCost.compareTo(max) > 0) {
//         max = movementCost;
//       }
//     }
//     return max;
//   }
// BigDecimal -> f64, matching `get_movement_cost_modifer_for_unit_type`.
// `Integer.MIN_VALUE` is -2147483648.
territory_effect_helper_get_max_movement_cost :: proc(
	t: ^Territory,
	units: [dynamic]^Unit,
) -> f64 {
	effects := territory_effect_helper_get_effects(t)
	if len(effects) == 0 || len(units) == 0 {
		return 1.0
	}
	max_cost: f64 = -2147483648.0
	for unit in units {
		movement_cost: f64 = 1.0
		ut := unit_get_type(unit)
		for effect in effects {
			movement_cost +=
				territory_effect_helper_get_movement_cost_modifer_for_unit_type(effect, ut)
		}
		if movement_cost > max_cost {
			max_cost = movement_cost
		}
	}
	return max_cost
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getMovementCost(Territory, Unit)
//   public static BigDecimal getMovementCost(final Territory t, final Unit unit) {
//     return getMaxMovementCost(t, Set.of(unit));
//   }
territory_effect_helper_get_movement_cost :: proc(t: ^Territory, unit: ^Unit) -> f64 {
	units: [dynamic]^Unit
	append(&units, unit)
	return territory_effect_helper_get_max_movement_cost(t, units)
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#getUnitTypesForUnitsNotAllowedIntoTerritory(Collection<Territory>)
//   public static Set<UnitType> getUnitTypesForUnitsNotAllowedIntoTerritory(
//       final Collection<Territory> steps) {
//     final Set<UnitType> unitTypes = new HashSet<>();
//     for (final Territory location : steps) {
//       unitTypes.addAll(getUnitTypesForUnitsNotAllowedIntoTerritory(location));
//     }
//     return unitTypes;
//   }
// `_1` suffix disambiguates from the single-Territory overload above
// (matches the `territory_effect_attachment_get_1` convention).
territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory_1 :: proc(
	steps: [dynamic]^Territory,
) -> map[^Unit_Type]struct {} {
	unit_types: map[^Unit_Type]struct {}
	for location in steps {
		per := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(location)
		for ut in per {
			unit_types[ut] = {}
		}
	}
	return unit_types
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#unitTypeKeepsBlitz(UnitType, Territory)
//   private static boolean unitTypeKeepsBlitz(final UnitType type, final Territory location) {
//     return !unitTypeLoosesBlitz(type, location);
//   }
territory_effect_helper_unit_type_keeps_blitz :: proc(
	type: ^Unit_Type,
	location: ^Territory,
) -> bool {
	return !territory_effect_helper_unit_type_looses_blitz(type, location)
}

// games.strategy.triplea.delegate.TerritoryEffectHelper#unitKeepsBlitz(Unit, Territory)
//   public static boolean unitKeepsBlitz(final Unit unit, final Territory location) {
//     return unitTypeKeepsBlitz(unit.getType(), location);
//   }
territory_effect_helper_unit_keeps_blitz :: proc(
	unit: ^Unit,
	location: ^Territory,
) -> bool {
	return territory_effect_helper_unit_type_keeps_blitz(unit_get_type(unit), location)
}
