package game

Air_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	stack: Execution_Stack,
	steps: [dynamic]string,
	defending_waiting_to_die: [dynamic]^Unit,
	attacking_waiting_to_die: [dynamic]^Unit,
	intercept: bool,
	max_rounds: i32,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.AirBattle

// games.strategy.triplea.delegate.battle.AirBattle#attackingGroundSeaBattleEscorts
air_battle_attacking_ground_sea_battle_escorts :: proc() -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	return matches_unit_can_air_battle()
}

// games.strategy.triplea.delegate.battle.AirBattle#getDefendingUnits
air_battle_get_defending_units :: proc(self: ^Air_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_defending_units(&self.abstract_battle)
}

// games.strategy.triplea.delegate.battle.AirBattle#defendingGroundSeaBattleInterceptors
//
// Java:
//   PredicateBuilder.of(Matches.unitCanAirBattle())
//       .and(Matches.unitIsEnemyOf(attacker))
//       .and(Matches.unitWasInAirBattle().negate())
//       .andIf(!Properties.getCanScrambleIntoAirBattles(data.getProperties()),
//              Matches.unitWasScrambled().negate())
//       .build();
Air_Battle_Ctx_defending_ground_sea_battle_interceptors :: struct {
	attacker:                ^Game_Player,
	apply_not_was_scrambled: bool,
}

air_battle_pred_defending_ground_sea_battle_interceptors :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Air_Battle_Ctx_defending_ground_sea_battle_interceptors)ctx_ptr
	cab_p, cab_c := matches_unit_can_air_battle()
	if !cab_p(cab_c, u) {
		return false
	}
	eo_p, eo_c := matches_unit_is_enemy_of(c.attacker)
	if !eo_p(eo_c, u) {
		return false
	}
	wia_p, wia_c := matches_unit_was_in_air_battle()
	if wia_p(wia_c, u) {
		return false
	}
	if c.apply_not_was_scrambled {
		ws_p, ws_c := matches_unit_was_scrambled()
		if ws_p(ws_c, u) {
			return false
		}
	}
	return true
}

air_battle_defending_ground_sea_battle_interceptors :: proc(
	attacker: ^Game_Player,
	data: ^Game_State,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Air_Battle_Ctx_defending_ground_sea_battle_interceptors)
	ctx.attacker = attacker
	ctx.apply_not_was_scrambled =
		!properties_get_can_scramble_into_air_battles(game_state_get_properties(data))
	return air_battle_pred_defending_ground_sea_battle_interceptors, rawptr(ctx)
}

// games.strategy.triplea.delegate.battle.AirBattle#defendingBombingRaidInterceptors
//
// Java:
//   final Predicate<Unit> canIntercept =
//       PredicateBuilder.of(Matches.unitCanIntercept())
//           .and(Matches.unitIsEnemyOf(attacker))
//           .and(Matches.unitWasInAirBattle().negate())
//           .andIf(!Properties.getCanScrambleIntoAirBattles(data.getProperties()),
//                  Matches.unitWasScrambled().negate())
//           .build();
//   final Predicate<Unit> airbasesCanIntercept =
//       Matches.unitIsEnemyOf(attacker)
//           .and(Matches.unitIsAirBase())
//           .and(Matches.unitIsNotDisabled())
//           .and(Matches.unitIsBeingTransported().negate());
//   return u -> canIntercept.test(u)
//       && (!Matches.unitRequiresAirBaseToIntercept().test(u)
//           || Matches.territoryHasUnitsThatMatch(airbasesCanIntercept).test(territory));
Air_Battle_Ctx_defending_bombing_raid_interceptors :: struct {
	territory:               ^Territory,
	attacker:                ^Game_Player,
	apply_not_was_scrambled: bool,
}

Air_Battle_Ctx_airbases_can_intercept :: struct {
	attacker: ^Game_Player,
}

air_battle_pred_airbases_can_intercept :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Air_Battle_Ctx_airbases_can_intercept)ctx_ptr
	eo_p, eo_c := matches_unit_is_enemy_of(c.attacker)
	if !eo_p(eo_c, u) {
		return false
	}
	ab_p, ab_c := matches_unit_is_air_base()
	if !ab_p(ab_c, u) {
		return false
	}
	nd_p, nd_c := matches_unit_is_not_disabled()
	if !nd_p(nd_c, u) {
		return false
	}
	bt_p, bt_c := matches_unit_is_being_transported()
	if bt_p(bt_c, u) {
		return false
	}
	return true
}

air_battle_pred_defending_bombing_raid_interceptors :: proc(ctx_ptr: rawptr, u: ^Unit) -> bool {
	c := cast(^Air_Battle_Ctx_defending_bombing_raid_interceptors)ctx_ptr
	ci_p, ci_c := matches_unit_can_intercept()
	if !ci_p(ci_c, u) {
		return false
	}
	eo_p, eo_c := matches_unit_is_enemy_of(c.attacker)
	if !eo_p(eo_c, u) {
		return false
	}
	wia_p, wia_c := matches_unit_was_in_air_battle()
	if wia_p(wia_c, u) {
		return false
	}
	if c.apply_not_was_scrambled {
		ws_p, ws_c := matches_unit_was_scrambled()
		if ws_p(ws_c, u) {
			return false
		}
	}
	rab_p, rab_c := matches_unit_requires_air_base_to_intercept()
	if !rab_p(rab_c, u) {
		return true
	}
	abi_ctx := new(Air_Battle_Ctx_airbases_can_intercept)
	abi_ctx.attacker = c.attacker
	thm_p, thm_c := matches_territory_has_units_that_match(
		air_battle_pred_airbases_can_intercept,
		rawptr(abi_ctx),
	)
	return thm_p(thm_c, c.territory)
}

air_battle_defending_bombing_raid_interceptors :: proc(
	territory: ^Territory,
	attacker: ^Game_Player,
	data: ^Game_State,
) -> (proc(rawptr, ^Unit) -> bool, rawptr) {
	ctx := new(Air_Battle_Ctx_defending_bombing_raid_interceptors)
	ctx.territory = territory
	ctx.attacker = attacker
	ctx.apply_not_was_scrambled =
		!properties_get_can_scramble_into_air_battles(game_state_get_properties(data))
	return air_battle_pred_defending_bombing_raid_interceptors, rawptr(ctx)
}

// games.strategy.triplea.delegate.battle.AirBattle#recordUnitsWereInAirBattle
//
// Java:
//   final CompositeChange wasInAirBattleChange = new CompositeChange();
//   for (final Unit u : units) {
//     wasInAirBattleChange.add(
//         ChangeFactory.unitPropertyChange(u, true, Unit.PropertyName.WAS_IN_AIR_BATTLE));
//   }
//   if (!wasInAirBattleChange.isEmpty()) {
//     bridge.addChange(wasInAirBattleChange);
//   }
air_battle_record_units_were_in_air_battle :: proc(
	units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
) {
	was_in_air_battle_change := composite_change_new()
	for u in units {
		boxed := new(bool)
		boxed^ = true
		composite_change_add(
			was_in_air_battle_change,
			change_factory_unit_property_change_property_name(
				u,
				rawptr(boxed),
				.Was_In_Air_Battle,
			),
		)
	}
	if !composite_change_is_empty(was_in_air_battle_change) {
		i_delegate_bridge_add_change(bridge, &was_in_air_battle_change.change)
	}
}

