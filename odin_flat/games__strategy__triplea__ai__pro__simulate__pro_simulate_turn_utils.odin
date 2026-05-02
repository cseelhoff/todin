package game

Pro_Simulate_Turn_Utils :: struct {}

// games.strategy.triplea.ai.pro.simulate.ProSimulateTurnUtils#transferUnit(Unit, Map<Unit,Territory>, List<Unit>, GameState, GamePlayer)
//
// Java:
//   private static @Nullable Unit transferUnit(
//       final Unit u,
//       final Map<Unit, Territory> unitTerritoryMap,
//       final List<Unit> usedUnits,
//       final GameState toData,
//       final GamePlayer player) {
//     final Territory unitTerritory = unitTerritoryMap.get(u);
//     final List<Unit> toUnits =
//         toData.getMap().getTerritoryOrNull(unitTerritory.getName()).getMatches(
//             ProMatches.unitIsOwnedAndMatchesTypeAndNotTransporting(player, u.getType()));
//     for (final Unit toUnit : toUnits) {
//       if (!usedUnits.contains(toUnit)) {
//         usedUnits.add(toUnit);
//         return toUnit;
//       }
//     }
//     return null;
//   }
pro_simulate_turn_utils_transfer_unit :: proc(
	u: ^Unit,
	unit_territory_map: map[^Unit]^Territory,
	used_units: ^[dynamic]^Unit,
	to_data: ^Game_State,
	player: ^Game_Player,
) -> ^Unit {
	unit_territory := unit_territory_map[u]
	to_territory := game_map_get_territory_or_null(
		game_state_get_map(to_data),
		default_named_get_name(&unit_territory.named_attachable.default_named),
	)
	pred, ctx := pro_matches_unit_is_owned_and_matches_type_and_not_transporting(
		player,
		unit_get_type(u),
	)
	uc := territory_get_unit_collection(to_territory)
	for to_unit in uc.units {
		if !pred(ctx, to_unit) {
			continue
		}
		// usedUnits.contains(toUnit) — reference identity scan
		found := false
		for used in used_units^ {
			if used == to_unit {
				found = true
				break
			}
		}
		if !found {
			append(used_units, to_unit)
			return to_unit
		}
	}
	return nil
}

