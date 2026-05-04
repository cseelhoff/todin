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

