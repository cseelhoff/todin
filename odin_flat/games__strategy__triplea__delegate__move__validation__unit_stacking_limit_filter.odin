package game

Unit_Stacking_Limit_Filter :: struct {}

UNIT_STACKING_LIMIT_FILTER_MOVEMENT_LIMIT :: "movementLimit"
UNIT_STACKING_LIMIT_FILTER_ATTACKING_LIMIT :: "attackingLimit"
UNIT_STACKING_LIMIT_FILTER_PLACEMENT_LIMIT :: "placementLimit"

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.move.validation.UnitStackingLimitFilter

// games.strategy.triplea.delegate.move.validation.UnitStackingLimitFilter#getMaximumNumberOfThisUnitTypeToReachStackingLimit
// Java:
//   private static int getMaximumNumberOfThisUnitTypeToReachStackingLimit(
//       UnitType ut, Territory t, GamePlayer owner,
//       @Nullable Tuple<Integer, String> stackingLimit,
//       Set<Triple<Integer, String, Set<UnitType>>> playerStackingLimits,
//       Collection<Unit> pendingUnits) {
//     int max = Integer.MAX_VALUE;
//     UnitAttachment ua = ut.getUnitAttachment();
//     var existingUnits = Iterables.concat(t.getUnits(), pendingUnits);
//     for (var limit : playerStackingLimits) {
//       var unitTypes = limit.getThird();
//       if (!unitTypes.contains(ut)) continue;
//       String stackingType = limit.getSecond();
//       Predicate<Unit> stackingMatch = Matches.unitIsOfTypes(unitTypes);
//       if (stackingType.equals("owned"))      stackingMatch = stackingMatch.and(Matches.unitIsOwnedBy(owner));
//       else if (stackingType.equals("allied")) stackingMatch = stackingMatch.and(Matches.alliedUnit(owner));
//       int totalInTerritory = CollectionUtils.countMatches(existingUnits, stackingMatch);
//       max = Math.min(max, limit.getFirst() - totalInTerritory);
//     }
//     if (stackingLimit != null) {
//       Predicate<Unit> stackingMatch;
//       String stackingType = stackingLimit.getSecond();
//       switch (stackingType) {
//         case "owned":  stackingMatch = Matches.unitIsOfType(ut).and(Matches.unitIsOwnedBy(owner)); break;
//         case "allied": stackingMatch = Matches.unitIsOfType(ut).and(Matches.isUnitAllied(owner)); break;
//         default:       stackingMatch = Matches.unitIsOfType(ut); break;
//       }
//       int totalInTerritory = CollectionUtils.countMatches(existingUnits, stackingMatch);
//       max = Math.min(max, ua.getStackingLimitMax(stackingLimit) - totalInTerritory);
//     }
//     return Math.max(0, max);
//   }
unit_stacking_limit_filter_get_maximum_number_of_this_unit_type_to_reach_stacking_limit :: proc(
	ut: ^Unit_Type,
	t: ^Territory,
	owner: ^Game_Player,
	stacking_limit: ^Tuple(i32, string),
	player_stacking_limits: map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {},
	pending_units: [dynamic]^Unit,
) -> i32 {
	INT_MAX :: i32(2147483647)
	max_val: i32 = INT_MAX
	ua := unit_type_get_unit_attachment(ut)
	// Iterables.concat(t.getUnits(), pendingUnits) — we iterate both ranges
	// in turn rather than materialize a copy.
	existing := unit_collection_get_units(territory_get_unit_collection(t))
	defer delete(existing)

	for limit, _ in player_stacking_limits {
		unit_types := triple_get_third(limit)
		if _, ok := unit_types[ut]; !ok {
			continue
		}
		stacking_type := triple_get_second(limit)
		total_in_territory: i32 = 0
		// Predicate: Matches.unitIsOfTypes(unitTypes) [.and(unitIsOwnedBy / alliedUnit)]
		count_pred :: proc(u: ^Unit, unit_types: map[^Unit_Type]struct {}, stacking_type: string, owner: ^Game_Player) -> bool {
			if unit_types == nil || len(unit_types) == 0 {
				return false
			}
			if _, ok := unit_types[unit_get_type(u)]; !ok {
				return false
			}
			if stacking_type == "owned" {
				return unit_is_owned_by(u, owner)
			} else if stacking_type == "allied" {
				if unit_is_owned_by(u, owner) {
					return true
				}
				return game_player_is_allied(owner, unit_get_owner(u))
			}
			return true
		}
		for u in existing {
			if count_pred(u, unit_types, stacking_type, owner) {
				total_in_territory += 1
			}
		}
		for u in pending_units {
			if count_pred(u, unit_types, stacking_type, owner) {
				total_in_territory += 1
			}
		}
		limit_max := triple_get_first(limit)
		candidate := limit_max - total_in_territory
		if candidate < max_val {
			max_val = candidate
		}
	}

	if stacking_limit != nil {
		stacking_type := tuple_get_second(stacking_limit)
		total_in_territory: i32 = 0
		// Predicate: Matches.unitIsOfType(ut) [.and(unitIsOwnedBy / isUnitAllied)]
		// Note: the "allied" arm uses Matches.isUnitAllied (player.isAllied(u.getOwner())),
		// NOT Matches.alliedUnit; the difference is intentional in Java.
		match_pred :: proc(u: ^Unit, ut: ^Unit_Type, stacking_type: string, owner: ^Game_Player) -> bool {
			if unit_get_type(u) != ut {
				return false
			}
			switch stacking_type {
			case "owned":
				return unit_is_owned_by(u, owner)
			case "allied":
				return game_player_is_allied(owner, unit_get_owner(u))
			}
			return true
		}
		for u in existing {
			if match_pred(u, ut, stacking_type, owner) {
				total_in_territory += 1
			}
		}
		for u in pending_units {
			if match_pred(u, ut, stacking_type, owner) {
				total_in_territory += 1
			}
		}
		candidate := unit_attachment_get_stacking_limit_max(ua, stacking_limit) - total_in_territory
		if candidate < max_val {
			max_val = candidate
		}
	}

	if max_val < 0 {
		return 0
	}
	return max_val
}

// games.strategy.triplea.delegate.move.validation.UnitStackingLimitFilter#filterUnits(Collection<Unit>, String, GamePlayer, Territory, Collection<Unit>)
// Java:
//   public static List<Unit> filterUnits(
//       Collection<Unit> units, String limitType, GamePlayer owner,
//       Territory t, Collection<Unit> existingUnitsToBePlaced) {
//     PlayerAttachment pa = PlayerAttachment.get(owner);
//     Function<UnitAttachment, Optional<Tuple<Integer, String>>> stackingLimitGetter;
//     Set<Triple<Integer, String, Set<UnitType>>> playerStackingLimits;
//     switch (limitType) {
//       case MOVEMENT_LIMIT:  stackingLimitGetter = UnitAttachment::getMovementLimit;  ...
//       case ATTACKING_LIMIT: stackingLimitGetter = UnitAttachment::getAttackingLimit; ...
//       case PLACEMENT_LIMIT: stackingLimitGetter = UnitAttachment::getPlacementLimit; ...
//       default: throw new IllegalArgumentException(...);
//     }
//     var unitsAllowedSoFar = new ArrayList<>(existingUnitsToBePlaced);
//     var forbiddenTypes = TerritoryEffectHelper.getUnitTypesForUnitsNotAllowedIntoTerritory(t);
//     for (Unit unit : units) {
//       UnitType ut = unit.getType();
//       if (forbiddenTypes.contains(ut)) continue;
//       int maxAllowed = getMaximumNumberOfThisUnitTypeToReachStackingLimit(
//           ut, t, owner, stackingLimitGetter.apply(ut.getUnitAttachment()).orElse(null),
//           playerStackingLimits, unitsAllowedSoFar);
//       if (maxAllowed > 0) unitsAllowedSoFar.add(unit);
//     }
//     unitsAllowedSoFar.subList(0, existingUnitsToBePlaced.size()).clear();
//     return unitsAllowedSoFar;
//   }
unit_stacking_limit_filter_filter_units :: proc(
	units: [dynamic]^Unit,
	limit_type: string,
	owner: ^Game_Player,
	t: ^Territory,
	existing_units_to_be_placed: [dynamic]^Unit,
) -> [dynamic]^Unit {
	pa := player_attachment_get(owner)

	stacking_limit_getter: proc(^Unit_Attachment) -> ^Tuple(i32, string)
	player_stacking_limits: map[^Triple(i32, string, map[^Unit_Type]struct {})]struct {}

	switch limit_type {
	case UNIT_STACKING_LIMIT_FILTER_MOVEMENT_LIMIT:
		stacking_limit_getter = unit_attachment_get_movement_limit
		if pa != nil {
			player_stacking_limits = player_attachment_get_movement_limit(pa)
		}
	case UNIT_STACKING_LIMIT_FILTER_ATTACKING_LIMIT:
		stacking_limit_getter = unit_attachment_get_attacking_limit
		if pa != nil {
			player_stacking_limits = player_attachment_get_attacking_limit(pa)
		}
	case UNIT_STACKING_LIMIT_FILTER_PLACEMENT_LIMIT:
		stacking_limit_getter = unit_attachment_get_placement_limit
		if pa != nil {
			player_stacking_limits = player_attachment_get_placement_limit(pa)
		}
	case:
		panic("Invalid limitType")
	}

	// Note: This must check each unit individually and track the ones that
	// passed in order to correctly handle stacking limits that apply to
	// multiple unit types.
	units_allowed_so_far := make([dynamic]^Unit)
	for u in existing_units_to_be_placed {
		append(&units_allowed_so_far, u)
	}
	forbidden_types := territory_effect_helper_get_unit_types_for_units_not_allowed_into_territory(t)
	defer delete(forbidden_types)

	for unit in units {
		ut := unit_get_type(unit)
		if _, ok := forbidden_types[ut]; ok {
			continue
		}
		stacking_limit := stacking_limit_getter(unit_type_get_unit_attachment(ut))
		max_allowed := unit_stacking_limit_filter_get_maximum_number_of_this_unit_type_to_reach_stacking_limit(
			ut,
			t,
			owner,
			stacking_limit,
			player_stacking_limits,
			units_allowed_so_far,
		)
		if max_allowed > 0 {
			append(&units_allowed_so_far, unit)
		}
	}

	// Remove the existing units from the front of the list before returning.
	// Don't return a sublist as it's not serializable in Java; in Odin we
	// return a freshly-allocated [dynamic]^Unit so callers can safely free it.
	n := len(existing_units_to_be_placed)
	result := make([dynamic]^Unit)
	for i := n; i < len(units_allowed_so_far); i += 1 {
		append(&result, units_allowed_so_far[i])
	}
	delete(units_allowed_so_far)
	return result
}

