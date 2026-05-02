package game

Retreater_General :: struct {
	using retreater: Retreater,
	battle_state: ^Battle_State,
}
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral

retreater_general_new :: proc(battle_state: ^Battle_State) -> ^Retreater_General {
	self := new(Retreater_General)
	self.battle_state = battle_state
	return self
}

retreater_general_get_retreat_type :: proc(self: ^Retreater_General) -> Must_Fight_Battle_Retreat_Type {
	return .DEFAULT
}

// games.strategy.triplea.delegate.battle.steps.retreat.RetreaterGeneral#getPossibleRetreatSites(java.util.Collection)
// Java:
//   final Collection<Territory> allRetreatTerritories = battleState.getAttackerRetreatTerritories();
//   return retreatUnits.stream().anyMatch(Matches.unitIsSea())
//       ? CollectionUtils.getMatches(allRetreatTerritories, Matches.territoryIsWater())
//       : new ArrayList<>(allRetreatTerritories);
retreater_general_get_possible_retreat_sites :: proc(
	self: ^Retreater_General,
	retreat_units: [dynamic]^Unit,
) -> [dynamic]^Territory {
	all_retreat_territories := battle_state_get_attacker_retreat_territories(self.battle_state)

	sea_pred, sea_ctx := matches_unit_is_sea()
	any_sea := false
	for u in retreat_units {
		if sea_pred(sea_ctx, u) {
			any_sea = true
			break
		}
	}

	result: [dynamic]^Territory
	if any_sea {
		water_pred, water_ctx := matches_territory_is_water()
		for t in all_retreat_territories {
			if water_pred(water_ctx, t) {
				append(&result, t)
			}
		}
	} else {
		for t in all_retreat_territories {
			append(&result, t)
		}
	}
	return result
}

