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

// games.strategy.triplea.delegate.battle.AirBattle#updateDefendingUnits
//
// Java:
//   if (isBombingRun) {
//     defendingUnits = battleSite.getMatches(
//         defendingBombingRaidInterceptors(battleSite, attacker, gameData));
//   } else {
//     defendingUnits = battleSite.getMatches(
//         defendingGroundSeaBattleInterceptors(attacker, gameData));
//   }
air_battle_update_defending_units :: proc(self: ^Air_Battle) {
	if self.is_bombing_run {
		pred, ctx := air_battle_defending_bombing_raid_interceptors(
			self.battle_site,
			self.attacker,
			&self.game_data.game_state,
		)
		self.defending_units = territory_get_matches(self.battle_site, pred, ctx)
	} else {
		pred, ctx := air_battle_defending_ground_sea_battle_interceptors(
			self.attacker,
			&self.game_data.game_state,
		)
		self.defending_units = territory_get_matches(self.battle_site, pred, ctx)
	}
}

// games.strategy.triplea.delegate.battle.AirBattle#territoryCouldPossiblyHaveAirBattleDefenders
//
// Java: see source — determines if `territory` could possibly host air-battle
// defenders for `attacker`, taking into account scrambling distance from
// neighbouring territories when air-battle scrambling is enabled.
air_battle_territory_could_possibly_have_air_battle_defenders :: proc(
	territory: ^Territory,
	attacker: ^Game_Player,
	data: ^Game_State,
	bombing: bool,
) -> bool {
	can_scramble_to_air_battle := properties_get_can_scramble_into_air_battles(
		game_state_get_properties(data),
	)
	defending_air_match:     proc(rawptr, ^Unit) -> bool
	defending_air_match_ctx: rawptr
	if bombing {
		defending_air_match, defending_air_match_ctx =
			air_battle_defending_bombing_raid_interceptors(territory, attacker, data)
	} else {
		defending_air_match, defending_air_match_ctx =
			air_battle_defending_ground_sea_battle_interceptors(attacker, data)
	}
	max_scramble_distance: i32 = 0
	if can_scramble_to_air_battle {
		for ut, _ in unit_type_list_get_all_unit_types(game_state_get_unit_type_list(data)) {
			ua := unit_type_get_unit_attachment(ut)
			if unit_attachment_can_scramble(ua) &&
				max_scramble_distance < unit_attachment_get_max_scramble_distance(ua) {
				max_scramble_distance = unit_attachment_get_max_scramble_distance(ua)
			}
		}
	} else {
		return territory_any_units_match(territory, defending_air_match, defending_air_match_ctx)
	}
	if territory_any_units_match(territory, defending_air_match, defending_air_match_ctx) {
		return true
	}
	thm_pred, thm_ctx := matches_territory_has_units_that_match(
		defending_air_match,
		defending_air_match_ctx,
	)
	for n, _ in game_map_get_neighbors_distance(
		game_state_get_map(data),
		territory,
		max_scramble_distance,
	) {
		if thm_pred(thm_ctx, n) {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.battle.AirBattle#<init>(
//     Territory, IBattle$BattleType, GameData, GamePlayer, BattleTracker)
//
// Java:
//   AirBattle(Territory battleSite, BattleType battleType, GameData data,
//             GamePlayer attacker, BattleTracker battleTracker) {
//     super(battleSite, attacker, battleTracker, battleType, data);
//     isAmphibious = false;
//     maxRounds = Properties.getAirBattleRounds(data.getProperties());
//     updateDefendingUnits();
//   }
//
// Mirrors AbstractBattle's constructor inline (we can't call
// abstract_battle_new because it allocates a separate Abstract_Battle;
// here the embedded base lives inside Air_Battle).
air_battle_new :: proc(
	battle_site: ^Territory,
	battle_type: I_Battle_Battle_Type,
	data: ^Game_Data,
	attacker: ^Game_Player,
	battle_tracker: ^Battle_Tracker,
) -> ^Air_Battle {
	self := new(Air_Battle)
	// super(battleSite, attacker, battleTracker, battleType, data)
	self.battle_id = uuid_random_uuid()
	self.headless = false
	self.round = 1
	self.is_over = false
	self.who_won = .NOT_FINISHED
	self.attacker_lost_tuv = 0
	self.defender_lost_tuv = 0
	self.dependent_units = make(map[^Unit][dynamic]^Unit)
	self.attacking_units = make([dynamic]^Unit)
	self.defending_units = make([dynamic]^Unit)
	self.amphibious_land_attackers = make([dynamic]^Unit)
	self.bombarding_units = make([dynamic]^Unit)
	self.battle_tracker = battle_tracker
	self.attacker = attacker
	self.battle_site = battle_site
	self.territory_effects = territory_effect_helper_get_effects(battle_site)
	self.is_bombing_run = i_battle_battle_type_is_bombing_run(battle_type)
	self.battle_type = battle_type
	self.game_data = data
	self.defender = abstract_battle_find_defender(battle_site, attacker, &data.game_state)
	// AirBattle's own fields:
	//   protected final ExecutionStack stack = new ExecutionStack();
	//   protected final Collection<Unit> defendingWaitingToDie = new ArrayList<>();
	//   protected final Collection<Unit> attackingWaitingToDie = new ArrayList<>();
	//   protected boolean intercept = false;
	self.stack = Execution_Stack {
		current_step = nil,
		deque        = make([dynamic]^I_Executable),
	}
	self.defending_waiting_to_die = make([dynamic]^Unit)
	self.attacking_waiting_to_die = make([dynamic]^Unit)
	self.intercept = false
	// isAmphibious = false
	self.is_amphibious = false
	// maxRounds = Properties.getAirBattleRounds(data.getProperties())
	self.max_rounds = properties_get_air_battle_rounds(
		game_state_get_properties(&data.game_state),
	)
	// updateDefendingUnits()
	air_battle_update_defending_units(self)
	return self
}

