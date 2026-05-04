package game

import "core:fmt"
import "core:slice"
import "core:strings"

Must_Fight_Battle :: struct {
	using dependent_battle: Dependent_Battle,
	attacking_waiting_to_die: [dynamic]^Unit,
	defending_waiting_to_die: [dynamic]^Unit,
	killed: [dynamic]^Unit,
	killed_during_current_round: [dynamic]^Unit,
	stack: ^Execution_Stack,
	step_strings: [dynamic]string,
	step_firing_units: map[string][dynamic]^Unit,
	defending_aa: [dynamic]^Unit,
	offensive_aa: [dynamic]^Unit,
	defending_aa_types: [dynamic]string,
	offensive_aa_types: [dynamic]string,
	attacking_units_retreated: [dynamic]^Unit,
	defending_units_retreated: [dynamic]^Unit,
	max_rounds: i32,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.MustFightBattle

// games.strategy.triplea.delegate.battle.MustFightBattle#getBattleTitle
//
//   return attacker.getName() + " attack " + defender.getName()
//       + " in " + battleSite.getName();
must_fight_battle_get_battle_title :: proc(self: ^Must_Fight_Battle) -> string {
	return fmt.aprintf(
		"%s attack %s in %s",
		self.attacker.base.name,
		self.defender.base.name,
		self.battle_site.base.name,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getPlayer(Side)
//
//   return side == OFFENSE ? getAttacker() : getDefender();
must_fight_battle_get_player :: proc(self: ^Must_Fight_Battle, side: Battle_State_Side) -> ^Game_Player {
	if side == .OFFENSE {
		return self.attacker
	}
	return self.defender
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getUnits(Side...)
//
// Private helper that returns the union of attackingUnits / defendingUnits
// for each requested side, in input order, allowing duplicates the way
// Java's `ArrayList.addAll` does.
must_fight_battle_get_units :: proc(self: ^Must_Fight_Battle, sides: ..Battle_State_Side) -> [dynamic]^Unit {
	units: [dynamic]^Unit
	for side in sides {
		switch side {
		case .OFFENSE:
			for u in self.attacking_units {
				append(&units, u)
			}
		case .DEFENSE:
			for u in self.defending_units {
				append(&units, u)
			}
		}
	}
	return units
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getWaitingToDie(Side...)
//
// Private helper mirroring `getUnits`, but for the *_waiting_to_die buckets.
must_fight_battle_get_waiting_to_die :: proc(self: ^Must_Fight_Battle, sides: ..Battle_State_Side) -> [dynamic]^Unit {
	waiting_to_die: [dynamic]^Unit
	for side in sides {
		switch side {
		case .OFFENSE:
			for u in self.attacking_waiting_to_die {
				append(&waiting_to_die, u)
			}
		case .DEFENSE:
			for u in self.defending_waiting_to_die {
				append(&waiting_to_die, u)
			}
		}
	}
	return waiting_to_die
}

// games.strategy.triplea.delegate.battle.MustFightBattle#isEmpty
//
//   return attackingUnits.isEmpty() && attackingWaitingToDie.isEmpty();
must_fight_battle_is_empty :: proc(self: ^Must_Fight_Battle) -> bool {
	return len(self.attacking_units) == 0 && len(self.attacking_waiting_to_die) == 0
}

// games.strategy.triplea.delegate.battle.MustFightBattle#lambda$addAttackChange$0(Territory)
//
// Java: `attackingFromMap.computeIfAbsent(attackingFrom, k -> new ArrayList<>())`.
// The lambda's body is `new ArrayList<>()` — i.e. a fresh empty list keyed by
// the territory `k`.
must_fight_battle_lambda_add_attack_change_0 :: proc(k: ^Territory) -> [dynamic]^Unit {
	_ = k
	return [dynamic]^Unit{}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#addAttackChange(Route, Collection<Unit>, Map<Unit, Set<Unit>>)
//
// Java: see MustFightBattle.java. Builds the CompositeChange recording the
// attack: appends `units` (filtered to the attacker's own units when
// WW2V2 is enabled) to attackingUnits and to attackingFromMap[territory
// before end of route]; flips isAmphibious / amphibiousAttackFrom when
// the route is sea→land and any attacker is land; if allied air is not
// independent, marks allied air as transportedBy on the available
// carriers and removes them from attackingUnits; finally marks the
// non-air (and, on a sea battle, non-land) attackers as having no
// movement, unless the route only walks through ignored sub/transport
// units. The `targets` parameter is required by the IBattle override
// signature but is unused in MustFightBattle's implementation.
must_fight_battle_add_attack_change :: proc(
	self: ^Must_Fight_Battle,
	route: ^Route,
	units: [dynamic]^Unit,
	targets: map[^Unit]map[^Unit]struct{},
) -> ^Change {
	_ = targets
	change := composite_change_new()
	// Filter out allied units if WW2V2.
	owned_p, owned_c := matches_unit_is_owned_by(self.attacker)
	attacking_units: [dynamic]^Unit
	if properties_get_ww2_v2(game_data_get_properties(self.game_data)) {
		for u in units {
			if owned_p(owned_c, u) {
				append(&attacking_units, u)
			}
		}
	} else {
		for u in units {
			append(&attacking_units, u)
		}
	}
	attacking_from := route_get_territory_before_end(route)
	for u in attacking_units {
		append(&self.attacking_units, u)
	}
	bucket, ok := self.attacking_from_map[attacking_from]
	if !ok {
		bucket = must_fight_battle_lambda_add_attack_change_0(attacking_from)
	}
	for u in attacking_units {
		append(&bucket, u)
	}
	self.attacking_from_map[attacking_from] = bucket
	// are we amphibious
	start := route_get_start(route)
	end := route_get_end(route)
	if territory_is_water(start) && !territory_is_water(end) {
		land_p, land_c := matches_unit_is_land()
		any_land := false
		for u in attacking_units {
			if land_p(land_c, u) {
				any_land = true
				break
			}
		}
		if any_land {
			append(&self.amphibious_attack_from, route_get_territory_before_end(route))
			self.is_amphibious = true
		}
	}
	if !properties_get_allied_air_independent(game_data_get_properties(self.game_data)) {
		// allied air can not participate in the battle so set transportedBy
		// on each allied air unit and remove them from the attacking units.
		allied_air_transport_change := transport_tracker_mark_transported_by_for_allied_air_on_carrier(units, self.attacker)
		composite_change_add(change, &allied_air_transport_change.change.change)
		air_set: map[^Unit]struct{}
		defer delete(air_set)
		for u in allied_air_transport_change.allied_air {
			air_set[u] = {}
		}
		for i := len(self.attacking_units) - 1; i >= 0; i -= 1 {
			if _, found := air_set[self.attacking_units[i]]; found {
				ordered_remove(&self.attacking_units, i)
			}
		}
	}
	// mark units with no movement for all but air
	not_air_p, not_air_c := matches_unit_is_not_air()
	non_air: [dynamic]^Unit
	for u in attacking_units {
		if not_air_p(not_air_c, u) {
			append(&non_air, u)
		}
	}
	// we don't want to change the movement of transported land units if this
	// is a sea battle so restrict non-air to remove land units.
	if territory_is_water(self.battle_site) {
		not_land_p, not_land_c := matches_unit_is_not_land()
		filtered: [dynamic]^Unit
		for u in non_air {
			if not_land_p(not_land_c, u) {
				append(&filtered, u)
			}
		}
		delete(non_air)
		non_air = filtered
	}
	// If attacker stops in an occupied territory, movement stops (battle is
	// optional).
	move_validator := move_validator_new(self.game_data, false)
	if move_validator_only_ignored_units_on_path(move_validator, route, self.attacker, false) {
		return &change.change
	}
	composite_change_add(change, change_factory_mark_no_movement_change_collection(non_air))
	return &change.change
}

// games.strategy.triplea.delegate.battle.MustFightBattle#markCasualties(Collection<Unit>, Side)
//
//   if (casualties.isEmpty()) return;
//   if (side == DEFENSE) { defendingWaitingToDie.addAll(casualties); defendingUnits.removeAll(casualties); }
//   else                 { attackingWaitingToDie.addAll(casualties); attackingUnits.removeAll(casualties); }
must_fight_battle_mark_casualties :: proc(self: ^Must_Fight_Battle, casualties: [dynamic]^Unit, side: Battle_State_Side) {
	if len(casualties) == 0 {
		return
	}

	// Use a set for O(n) removal of all members of `casualties`.
	casualty_set: map[^Unit]struct{}
	defer delete(casualty_set)
	for u in casualties {
		casualty_set[u] = {}
	}

	if side == .DEFENSE {
		for u in casualties {
			append(&self.defending_waiting_to_die, u)
		}
		for i := len(self.defending_units) - 1; i >= 0; i -= 1 {
			if _, ok := casualty_set[self.defending_units[i]]; ok {
				ordered_remove(&self.defending_units, i)
			}
		}
	} else {
		for u in casualties {
			append(&self.attacking_waiting_to_die, u)
		}
		for i := len(self.attacking_units) - 1; i >= 0; i -= 1 {
			if _, ok := casualty_set[self.attacking_units[i]]; ok {
				ordered_remove(&self.attacking_units, i)
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#retreatUnits(Side, Collection<Unit>)
//
//   final Collection<Unit> units            = side == DEFENSE ? defendingUnits            : attackingUnits;
//   final Collection<Unit> unitsRetreated   = side == DEFENSE ? defendingUnitsRetreated   : attackingUnitsRetreated;
//   units.removeAll(retreatingUnits);
//   unitsRetreated.addAll(retreatingUnits);
must_fight_battle_retreat_units :: proc(self: ^Must_Fight_Battle, side: Battle_State_Side, retreating_units: [dynamic]^Unit) {
	retreat_set: map[^Unit]struct{}
	defer delete(retreat_set)
	for u in retreating_units {
		retreat_set[u] = {}
	}

	units: ^[dynamic]^Unit
	units_retreated: ^[dynamic]^Unit
	if side == .DEFENSE {
		units = &self.defending_units
		units_retreated = &self.defending_units_retreated
	} else {
		units = &self.attacking_units
		units_retreated = &self.attacking_units_retreated
	}

	for i := len(units^) - 1; i >= 0; i -= 1 {
		if _, ok := retreat_set[units^[i]]; ok {
			ordered_remove(units, i)
		}
	}
	for u in retreating_units {
		append(units_retreated, u)
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#setAttackingFromMap(Map<Territory, Collection<Unit>>)
//
//   this.attackingFromMap = attackingFromMap;
must_fight_battle_set_attacking_from_map :: proc(self: ^Must_Fight_Battle, attacking_from_map: map[^Territory][dynamic]^Unit) {
	self.attacking_from_map = attacking_from_map
}

// games.strategy.triplea.delegate.battle.MustFightBattle#setUnits(Collection, Collection, Collection, GamePlayer, Collection)
//
//   defendingUnits   = new ArrayList<>(defending);
//   attackingUnits   = new ArrayList<>(attacking);
//   bombardingUnits  = new ArrayList<>(bombarding);
//   this.defender    = defender;
//   this.territoryEffects = territoryEffects;
must_fight_battle_set_units :: proc(
	self: ^Must_Fight_Battle,
	defending: [dynamic]^Unit,
	attacking: [dynamic]^Unit,
	bombarding: [dynamic]^Unit,
	defender: ^Game_Player,
	territory_effects: [dynamic]^Territory_Effect,
) {
	clear(&self.defending_units)
	for u in defending {
		append(&self.defending_units, u)
	}
	clear(&self.attacking_units)
	for u in attacking {
		append(&self.attacking_units, u)
	}
	clear(&self.bombarding_units)
	for u in bombarding {
		append(&self.bombarding_units, u)
	}
	self.defender = defender
	clear(&self.territory_effects)
	for te in territory_effects {
		append(&self.territory_effects, te)
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#resetDefendingUnits(GamePlayer)
//
//   defendingUnits.clear();
//   defendingUnits.addAll(battleSite.getMatches(Matches.enemyUnit(attacker)));
must_fight_battle_reset_defending_units :: proc(self: ^Must_Fight_Battle, attacker: ^Game_Player) {
	clear(&self.defending_units)
	en_p, en_c := matches_enemy_unit(attacker)
	uc := territory_get_unit_collection(self.battle_site)
	if uc == nil {
		return
	}
	for u in uc.units {
		if en_p(en_c, u) {
			append(&self.defending_units, u)
		}
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getDependentBattles
//
//   return battleTracker.getBlocked(this);
must_fight_battle_get_dependent_battles :: proc(self: ^Must_Fight_Battle) -> map[^I_Battle]struct{} {
	return battle_tracker_get_blocked(self.battle_tracker, cast(^I_Battle)self)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getUnits(UnitBattleStatus, Side...)
//
//   switch (status) {
//     case ALIVE:            return Collections.unmodifiableCollection(getUnits(sides));
//     case CASUALTY:         return Collections.unmodifiableCollection(getWaitingToDie(sides));
//     case REMOVED_CASUALTY: return Collections.unmodifiableCollection(killed);
//     default:               return List.of();
//   }
must_fight_battle_get_units_by_status :: proc(
	self: ^Must_Fight_Battle,
	status: Battle_State_Unit_Battle_Status,
	sides: ..Battle_State_Side,
) -> [dynamic]^Unit {
	switch status {
	case .Alive:
		return must_fight_battle_get_units(self, ..sides)
	case .Casualty:
		return must_fight_battle_get_waiting_to_die(self, ..sides)
	case .Removed_Casualty:
		result: [dynamic]^Unit
		for u in self.killed {
			append(&result, u)
		}
		return result
	}
	return [dynamic]^Unit{}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#filterUnits(UnitBattleFilter, Side...)
//
//   return filter.getFilter().stream()
//       .flatMap(status -> getUnits(status, sides).stream())
//       .collect(Collectors.toList());
must_fight_battle_filter_units :: proc(
	self: ^Must_Fight_Battle,
	filter: ^Battle_State_Unit_Battle_Filter,
	sides: ..Battle_State_Side,
) -> [dynamic]^Unit {
	result: [dynamic]^Unit
	for status, _ in battle_state_unit_battle_filter_get_filter(filter) {
		bucket := must_fight_battle_get_units_by_status(self, status, ..sides)
		for u in bucket {
			append(&result, u)
		}
		delete(bucket)
	}
	return result
}

// games.strategy.triplea.delegate.battle.MustFightBattle#lambda$getAttackerRetreatTerritories$2(Territory)
//
// The Predicate<Territory> argument to CollectionUtils.getMatches in the
// WW2V2/WW2V3 branch of getAttackerRetreatTerritories:
//   t -> {
//     final Collection<Unit> units = attackingFromMap.get(t);
//     return units.isEmpty() || !units.stream().allMatch(Matches.unitIsAir());
//   }
// Captures `attackingFromMap` from the enclosing MustFightBattle instance,
// so we use the rawptr+ctx convention with `self` as the context.
must_fight_battle_lambda_get_attacker_retreat_territories_2 :: proc(ctx: rawptr, t: ^Territory) -> bool {
	self := cast(^Must_Fight_Battle)ctx
	units, ok := self.attacking_from_map[t]
	if !ok || len(units) == 0 {
		return true
	}
	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	return !all_air
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeFromDependentBattles(Collection<Unit>, IDelegateBridge, Collection<IBattle>)
must_fight_battle_remove_from_dependent_battles :: proc(
	units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	dependents: [dynamic]^I_Battle,
) {
	for dependent in dependents {
		i_battle_units_lost_in_preceding_battle(dependent, units, bridge, false)
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#addRoundResetStep(List<IExecutable>)
//
// Java constructs two anonymous IExecutables: an inner `loop` (which calls
// `pushFightLoopOnStack()`) and an outer step (which bumps `round`, validates
// against MAX_ROUNDS, refreshes step strings, broadcasts them, and pushes the
// loop back onto the stack). The Odin port mirrors Java by constructing the
// already-defined inner-class structs (`Must_Fight_Battle_28` is the loop,
// `Must_Fight_Battle_29` is the outer step) and appending the outer step's
// embedded I_Executable to the supplied list. The execute method bodies for
// the two inner classes live on the inner structs themselves and are tracked
// as separate method_keys.
must_fight_battle_add_round_reset_step :: proc(
	self: ^Must_Fight_Battle,
	steps: ^[dynamic]^I_Executable,
) {
	loop := must_fight_battle_28_new(self)
	outer := must_fight_battle_29_new(self, &loop.i_executable)
	append(steps, &outer.i_executable)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#cleanupKilledUnits(IDelegateBridge, Side, Collection<Unit>, Collection<Unit>)
//
// Java:
//   final Collection<IBattle> dependentBattles = battleTracker.getBlocked(this);
//   if (!dependentBattles.isEmpty()) {
//     removeFromDependentBattles(killedUnits, bridge, dependentBattles);
//   }
//   this.killed.addAll(killedUnits);
//   if (side == DEFENSE) {
//     defendingUnits.addAll(transformedUnits);
//     defendingUnits.removeAll(killedUnits);
//     defendingWaitingToDie.removeAll(killedUnits);
//   } else { /* mirror with attacking */ }
must_fight_battle_cleanup_killed_units :: proc(
	self: ^Must_Fight_Battle,
	bridge: ^I_Delegate_Bridge,
	side: Battle_State_Side,
	killed_units: [dynamic]^Unit,
	transformed_units: [dynamic]^Unit,
) {
	dependent_battles := battle_tracker_get_blocked(self.battle_tracker, cast(^I_Battle)self)
	defer delete(dependent_battles)
	if len(dependent_battles) > 0 {
		for dependent in dependent_battles {
			i_battle_units_lost_in_preceding_battle(dependent, killed_units, bridge, false)
		}
	}

	for u in killed_units {
		append(&self.killed, u)
	}

	killed_set: map[^Unit]struct{}
	defer delete(killed_set)
	for u in killed_units {
		killed_set[u] = {}
	}

	if side == .DEFENSE {
		for u in transformed_units {
			append(&self.defending_units, u)
		}
		for i := len(self.defending_units) - 1; i >= 0; i -= 1 {
			if _, ok := killed_set[self.defending_units[i]]; ok {
				ordered_remove(&self.defending_units, i)
			}
		}
		for i := len(self.defending_waiting_to_die) - 1; i >= 0; i -= 1 {
			if _, ok := killed_set[self.defending_waiting_to_die[i]]; ok {
				ordered_remove(&self.defending_waiting_to_die, i)
			}
		}
	} else {
		for u in transformed_units {
			append(&self.attacking_units, u)
		}
		for i := len(self.attacking_units) - 1; i >= 0; i -= 1 {
			if _, ok := killed_set[self.attacking_units[i]]; ok {
				ordered_remove(&self.attacking_units, i)
			}
		}
		for i := len(self.attacking_waiting_to_die) - 1; i >= 0; i -= 1 {
			if _, ok := killed_set[self.attacking_waiting_to_die[i]]; ok {
				ordered_remove(&self.attacking_waiting_to_die, i)
			}
		}
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getRemainingAttackingUnits
//
// Java:
//   final Set<Unit> remaining = new HashSet<>(attackingUnitsRetreated);
//   final Collection<Unit> unitsLeftInTerritory = new ArrayList<>(battleSite.getUnits());
//   unitsLeftInTerritory.removeAll(killed);
//   remaining.addAll(getMatches(unitsLeftInTerritory,
//       getWhoWon() != WhoWon.DEFENDER
//           ? Matches.unitIsOwnedBy(attacker)
//           : Matches.unitIsOwnedBy(attacker)
//                 .and(Matches.unitIsAir())
//                 .and(Matches.unitIsNotInfrastructure())));
//   return remaining;
must_fight_battle_get_remaining_attacking_units :: proc(self: ^Must_Fight_Battle) -> [dynamic]^Unit {
	remaining: [dynamic]^Unit
	seen: map[^Unit]struct{}
	defer delete(seen)
	for u in self.attacking_units_retreated {
		if _, ok := seen[u]; !ok {
			seen[u] = {}
			append(&remaining, u)
		}
	}

	killed_set: map[^Unit]struct{}
	defer delete(killed_set)
	for u in self.killed {
		killed_set[u] = {}
	}

	site_units := unit_collection_get_units(self.battle_site.unit_collection)
	defer delete(site_units)

	defender_won := self.who_won == .DEFENDER
	own_p, own_c := matches_unit_is_owned_by(self.attacker)
	air_p, air_c := matches_unit_is_air()
	ni_p, ni_c := matches_unit_is_not_infrastructure()

	for u in site_units {
		if _, k := killed_set[u]; k {
			continue
		}
		matched: bool
		if !defender_won {
			matched = own_p(own_c, u)
		} else {
			matched = own_p(own_c, u) && air_p(air_c, u) && ni_p(ni_c, u)
		}
		if matched {
			if _, ok := seen[u]; !ok {
				seen[u] = {}
				append(&remaining, u)
			}
		}
	}
	return remaining
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getRemainingDefendingUnits
//
// Java:
//   final Set<Unit> remaining = new HashSet<>(defendingUnitsRetreated);
//   remaining.addAll(defendingUnits);
//   if (getWhoWon() != WhoWon.ATTACKER || attackingUnits.stream().allMatch(Matches.unitIsAir())) {
//     final var unitsLeftInTerritory = new HashSet<>(getMatches(battleSite.getUnits(),
//         Matches.unitIsOwnedBy(defender).or(Matches.enemyUnit(attacker))));
//     unitsLeftInTerritory.removeAll(killed);
//     remaining.addAll(unitsLeftInTerritory);
//   }
//   return remaining;
must_fight_battle_get_remaining_defending_units :: proc(self: ^Must_Fight_Battle) -> [dynamic]^Unit {
	remaining: [dynamic]^Unit
	seen: map[^Unit]struct{}
	defer delete(seen)
	for u in self.defending_units_retreated {
		if _, ok := seen[u]; !ok {
			seen[u] = {}
			append(&remaining, u)
		}
	}
	for u in self.defending_units {
		if _, ok := seen[u]; !ok {
			seen[u] = {}
			append(&remaining, u)
		}
	}

	air_p, air_c := matches_unit_is_air()
	all_air := true
	for u in self.attacking_units {
		if !air_p(air_c, u) {
			all_air = false
			break
		}
	}
	if self.who_won != .ATTACKER || all_air {
		killed_set: map[^Unit]struct{}
		defer delete(killed_set)
		for u in self.killed {
			killed_set[u] = {}
		}

		site_units := unit_collection_get_units(self.battle_site.unit_collection)
		defer delete(site_units)

		own_def_p, own_def_c := matches_unit_is_owned_by(self.defender)
		en_atk_p, en_atk_c := matches_enemy_unit(self.attacker)
		// Track territory-side dedup so removeAll(killed) and addAll match Java semantics.
		territory_seen: map[^Unit]struct{}
		defer delete(territory_seen)
		for u in site_units {
			if !(own_def_p(own_def_c, u) || en_atk_p(en_atk_c, u)) {
				continue
			}
			if _, k := killed_set[u]; k {
				continue
			}
			if _, ts := territory_seen[u]; ts {
				continue
			}
			territory_seen[u] = {}
			if _, ok := seen[u]; !ok {
				seen[u] = {}
				append(&remaining, u)
			}
		}
	}
	return remaining
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getStatus
//
//   return BattleStatus.of(round, maxRounds, isOver, isAmphibious, headless);
must_fight_battle_get_status :: proc(self: ^Must_Fight_Battle) -> ^Battle_State_Battle_Status {
	return battle_state__battle_status_of(
		self.round,
		self.max_rounds,
		self.is_over,
		self.is_amphibious,
		self.headless,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#lambda$filterUnits$1(Side[], UnitBattleStatus)
//
// Java synthetic produced by `status -> getUnits(status, sides).stream()` inside
// filterUnits. Captures `this` and `sides`; the lambda parameter is `status`.
// The Odin port mirrors that as a free proc taking the captured receiver and
// sides plus the lambda parameter, returning the matching units (the Java
// stream materialised). Used to build filterUnits's flat-mapped result.
must_fight_battle_lambda_filter_units_1 :: proc(
	self: ^Must_Fight_Battle,
	sides: []Battle_State_Side,
	status: Battle_State_Unit_Battle_Status,
) -> [dynamic]^Unit {
	return must_fight_battle_get_units_by_status(self, status, ..sides)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeAirNoLongerInTerritory
//
// Java:
//   if (headless) return;
//   final Predicate<Unit> airNotInTerritory = Matches.unitIsInTerritory(battleSite).negate();
//   attackingUnits.removeAll(getMatches(attackingUnits, airNotInTerritory));
// (i.e. retain only attacking units still in battleSite.)
must_fight_battle_remove_air_no_longer_in_territory :: proc(self: ^Must_Fight_Battle) {
	if self.headless {
		return
	}
	in_p, in_c := matches_unit_is_in_territory(self.battle_site)
	for i := len(self.attacking_units) - 1; i >= 0; i -= 1 {
		if !in_p(in_c, self.attacking_units[i]) {
			ordered_remove(&self.attacking_units, i)
		}
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeDisabledUnits
//
// Java:
//   defendingUnits = CollectionUtils.getMatches(defendingUnits, Matches.unitIsNotDisabled());
//   attackingUnits = CollectionUtils.getMatches(attackingUnits, Matches.unitIsNotDisabled());
must_fight_battle_remove_disabled_units :: proc(self: ^Must_Fight_Battle) {
	nd_p, nd_c := matches_unit_is_not_disabled()
	for i := len(self.defending_units) - 1; i >= 0; i -= 1 {
		if !nd_p(nd_c, self.defending_units[i]) {
			ordered_remove(&self.defending_units, i)
		}
	}
	for i := len(self.attacking_units) - 1; i >= 0; i -= 1 {
		if !nd_p(nd_c, self.attacking_units[i]) {
			ordered_remove(&self.attacking_units, i)
		}
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeNonCombatants(Collection<Unit>, Collection<Unit>, boolean, boolean)
//
// Java private filter helper:
//   int battleRound = (removeForNextRound ? round + 1 : round);
//   return CollectionUtils.getMatches(units,
//       Matches.unitCanParticipateInCombat(attacking, attacker, battleSite, battleRound, enemyUnits));
must_fight_battle_remove_non_combatants_filter :: proc(
	self: ^Must_Fight_Battle,
	units: [dynamic]^Unit,
	enemy_units: [dynamic]^Unit,
	attacking: bool,
	remove_for_next_round: bool,
) -> [dynamic]^Unit {
	battle_round := self.round
	if remove_for_next_round {
		battle_round = self.round + 1
	}
	pred, pred_ctx := matches_unit_can_participate_in_combat(
		attacking,
		self.attacker,
		self.battle_site,
		battle_round,
		enemy_units,
	)
	result: [dynamic]^Unit
	for u in units {
		if pred(pred_ctx, u) {
			append(&result, u)
		}
	}
	return result
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeNonCombatants(BattleState.Side)
//
// Java public override:
//   if (side == DEFENSE) {
//     final List<Unit> notRemovedDefending = removeNonCombatants(defendingUnits, attackingUnits, false, true);
//     final Collection<Unit> toRemoveDefending = CollectionUtils.difference(defendingUnits, notRemovedDefending);
//     defendingUnits = notRemovedDefending;
//     return toRemoveDefending;
//   } else { /* mirror with attackers */ }
must_fight_battle_remove_non_combatants :: proc(
	self: ^Must_Fight_Battle,
	side: Battle_State_Side,
) -> [dynamic]^Unit {
	if side == .DEFENSE {
		not_removed := must_fight_battle_remove_non_combatants_filter(
			self,
			self.defending_units,
			self.attacking_units,
			false,
			true,
		)
		// difference(defendingUnits, not_removed): elements in defending_units not in not_removed.
		kept_set: map[^Unit]struct{}
		defer delete(kept_set)
		for u in not_removed {
			kept_set[u] = {}
		}
		to_remove: [dynamic]^Unit
		for u in self.defending_units {
			if _, ok := kept_set[u]; !ok {
				append(&to_remove, u)
			}
		}
		delete(self.defending_units)
		self.defending_units = not_removed
		return to_remove
	} else {
		not_removed := must_fight_battle_remove_non_combatants_filter(
			self,
			self.attacking_units,
			self.defending_units,
			true,
			true,
		)
		kept_set: map[^Unit]struct{}
		defer delete(kept_set)
		for u in not_removed {
			kept_set[u] = {}
		}
		to_remove: [dynamic]^Unit
		for u in self.attacking_units {
			if _, ok := kept_set[u]; !ok {
				append(&to_remove, u)
			}
		}
		delete(self.attacking_units)
		self.attacking_units = not_removed
		return to_remove
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#addPlayerCombatHistoryText(
//     Collection<GamePlayer>, Collection<Unit>, boolean, IDelegateHistoryWriter)
//
// Java private helper invoked from writeUnitsToHistory. For each player in
// `players`, append "<name> <verb>[ with <unitsToTextNoOwner(filtered)>]"
// (separated by "; "), where verb depends on attacking flag and whether
// the player is the lead attacker. Final concatenated event is written
// only if any units were filtered overall.
must_fight_battle_add_player_combat_history_text :: proc(
	self: ^Must_Fight_Battle,
	players: [dynamic]^Game_Player,
	units: [dynamic]^Unit,
	attacking: bool,
	history_writer: ^I_Delegate_History_Writer,
) {
	sb := strings.builder_make()
	defer strings.builder_destroy(&sb)
	all_units: [dynamic]^Unit
	defer delete(all_units)

	for current in players {
		if strings.builder_len(sb) > 0 {
			strings.write_string(&sb, "; ")
		}
		own_p, own_c := matches_unit_is_owned_by(current)
		filtered_units: [dynamic]^Unit
		defer delete(filtered_units)
		for u in units {
			if own_p(own_c, u) {
				append(&filtered_units, u)
			}
		}
		verb: string
		if !attacking {
			verb = "defend"
		} else if current == self.attacker {
			verb = "attack"
		} else {
			verb = "loiter and taunt"
		}
		strings.write_string(&sb, current.named.base.name)
		strings.write_string(&sb, " ")
		strings.write_string(&sb, verb)
		if len(filtered_units) > 0 {
			strings.write_string(&sb, " with ")
			strings.write_string(&sb, my_formatter_units_to_text_no_owner_simple(filtered_units))
		}
		for u in filtered_units {
			append(&all_units, u)
		}
	}

	if len(all_units) > 0 {
		history_writer_add_child_to_event(history_writer, strings.to_string(sb), all_units)
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#retreatQuery(
//     BattleState, Player, Collection<Territory>, boolean, String)
//
// Java private helper:
//   final Optional<Territory> optionalRetreatTo = remotePlayer.retreatQuery(
//       battleState.getBattleId(), submerge, battleState.getBattleSite(),
//       availableTerritories, text);
//   if (optionalRetreatTo.isPresent() && !availableTerritories.contains(optionalRetreatTo.get())) {
//     log.error("Invalid retreat selection: " + ... + " not in " +
//               MyFormatter.defaultNamedToTextList(availableTerritories));
//     return Optional.empty();
//   }
//   return optionalRetreatTo;
must_fight_battle_retreat_query :: proc(
	self: ^Must_Fight_Battle,
	battle_state: ^Battle_State,
	remote_player: ^Player,
	available_territories: [dynamic]^Territory,
	submerge: bool,
	text: string,
) -> ^Territory {
	optional_retreat_to := player_retreat_query(
		remote_player,
		battle_state_get_battle_id(battle_state),
		submerge,
		battle_state_get_battle_site(battle_state),
		available_territories,
		text,
	)
	if optional_retreat_to != nil {
		found := false
		for t in available_territories {
			if t == optional_retreat_to {
				found = true
				break
			}
		}
		if !found {
			named: [dynamic]^Default_Named
			defer delete(named)
			for t in available_territories {
				append(&named, &t.named_attachable.default_named)
			}
			fmt.eprintln(
				"Invalid retreat selection:",
				optional_retreat_to.named.base.name,
				"not in",
				my_formatter_default_named_to_text_list_simple(named),
			)
			return nil
		}
	}
	return optional_retreat_to
}

// games.strategy.triplea.delegate.battle.MustFightBattle#showCasualties(IDelegateBridge)
//
// Java private helper:
//   if (killed.isEmpty()) return;
//   IntegerMap<UnitType> costs = bridge.getCostsForTuv(attacker);
//   final int tuvLostAttacker = TuvUtils.getTuv(killed, attacker, costs, gameData);
//   costs = bridge.getCostsForTuv(defender);
//   final int tuvLostDefender = TuvUtils.getTuv(killed, defender, costs, gameData);
//   final int tuvChange = tuvLostDefender - tuvLostAttacker;
//   bridge.getHistoryWriter().addChildToEvent(
//       "Battle casualty summary: Battle score (TUV change) for attacker is " + tuvChange,
//       new ArrayList<>(killed));
//   attackerLostTuv += tuvLostAttacker;
//   defenderLostTuv += tuvLostDefender;
must_fight_battle_show_casualties :: proc(
	self: ^Must_Fight_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	if len(self.killed) == 0 {
		return
	}

	attacker_costs_map := i_delegate_bridge_get_costs_for_tuv(bridge, self.attacker)
	attacker_costs := new(Integer_Map_Unit_Type)
	defer free(attacker_costs)
	attacker_costs.entries = attacker_costs_map
	tuv_lost_attacker := tuv_utils_get_tuv_for_player(
		self.killed,
		self.attacker,
		attacker_costs,
		self.game_data,
	)

	defender_costs_map := i_delegate_bridge_get_costs_for_tuv(bridge, self.defender)
	defender_costs := new(Integer_Map_Unit_Type)
	defer free(defender_costs)
	defender_costs.entries = defender_costs_map
	tuv_lost_defender := tuv_utils_get_tuv_for_player(
		self.killed,
		self.defender,
		defender_costs,
		self.game_data,
	)

	tuv_change := tuv_lost_defender - tuv_lost_attacker
	writer := i_delegate_bridge_get_history_writer(bridge)
	text := fmt.aprintf(
		"Battle casualty summary: Battle score (TUV change) for attacker is %d",
		tuv_change,
	)
	killed_copy: [dynamic]^Unit
	for u in self.killed {
		append(&killed_copy, u)
	}
	history_writer_add_child_to_event(writer, text, killed_copy)
	self.attacker_lost_tuv += tuv_lost_attacker
	self.defender_lost_tuv += tuv_lost_defender
}

// games.strategy.triplea.delegate.battle.MustFightBattle#findAllies(
//     Collection<GamePlayer>, GamePlayer, RelationshipTracker)
//
// Java private static helper:
//   final Collection<GamePlayer> allies = new ArrayList<>();
//   for (final GamePlayer current : candidatePlayers) {
//     if (current.equals(player) || relationshipTracker.isAllied(player, current)) {
//       allies.add(current);
//     }
//   }
//   return allies;
must_fight_battle_find_allies :: proc(
	candidate_players: [dynamic]^Game_Player,
	player: ^Game_Player,
	relationship_tracker: ^Relationship_Tracker,
) -> [dynamic]^Game_Player {
	allies: [dynamic]^Game_Player
	for current in candidate_players {
		if current == player ||
		   relationship_tracker_is_allied(relationship_tracker, player, current) {
			append(&allies, current)
		}
	}
	return allies
}

// games.strategy.triplea.delegate.battle.MustFightBattle#markAttackingTransports(IDelegateBridge)
//
// Java:
//   if (headless) return;
//   final Collection<Unit> transports =
//       CollectionUtils.getMatches(
//           attackingUnits, Matches.unitCanTransport().and(Matches.unitIsOwnedBy(attacker)));
//   if (!transports.isEmpty()) {
//     final CompositeChange change = new CompositeChange();
//     for (final Unit unit : transports) {
//       change.add(ChangeFactory.unitPropertyChange(unit, true, Unit.PropertyName.WAS_IN_COMBAT));
//     }
//     bridge.addChange(change);
//   }
must_fight_battle_mark_attacking_transports :: proc(
	self: ^Must_Fight_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	if self.headless {
		return
	}
	can_xport_p, can_xport_c := matches_unit_can_transport()
	owned_p, owned_c := matches_unit_is_owned_by(self.attacker)
	transports: [dynamic]^Unit
	defer delete(transports)
	for u in self.attacking_units {
		if can_xport_p(can_xport_c, u) && owned_p(owned_c, u) {
			append(&transports, u)
		}
	}
	if len(transports) == 0 {
		return
	}
	change := composite_change_new()
	for unit in transports {
		boxed := new(bool)
		boxed^ = true
		composite_change_add(
			change,
			change_factory_unit_property_change_property_name(
				unit,
				rawptr(boxed),
				.Was_In_Combat,
			),
		)
	}
	i_delegate_bridge_add_change(bridge, &change.change)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#queryRetreatTerritory(
//     BattleState, IDelegateBridge, GamePlayer, Collection<Territory>, String)
//
//   return retreatQuery(
//       battleState, getRemote(retreatingPlayer, bridge), availableTerritories, false, text);
must_fight_battle_query_retreat_territory :: proc(
	self: ^Must_Fight_Battle,
	battle_state: ^Battle_State,
	bridge: ^I_Delegate_Bridge,
	retreating_player: ^Game_Player,
	available_territories: [dynamic]^Territory,
	text: string,
) -> ^Territory {
	return must_fight_battle_retreat_query(
		self,
		battle_state,
		abstract_battle_get_remote_for_player(retreating_player, bridge),
		available_territories,
		false,
		text,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#querySubmergeTerritory(
//     BattleState, IDelegateBridge, GamePlayer, Collection<Territory>, String)
//
//   return retreatQuery(
//       battleState, getRemote(retreatingPlayer, bridge), availableTerritories, true, text);
must_fight_battle_query_submerge_territory :: proc(
	self: ^Must_Fight_Battle,
	battle_state: ^Battle_State,
	bridge: ^I_Delegate_Bridge,
	retreating_player: ^Game_Player,
	available_territories: [dynamic]^Territory,
	text: string,
) -> ^Territory {
	return must_fight_battle_retreat_query(
		self,
		battle_state,
		abstract_battle_get_remote_for_player(retreating_player, bridge),
		available_territories,
		true,
		text,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getAttackerRetreatTerritories()
//
// Java public:
//   - If attacker is all planes (or headless, or RetreatingUnitsRemainInPlace),
//     return Set.of(battleSite).
//   - Otherwise compute possible from `attackingFromMap.keySet()`, filtered by
//     a `Matches.territoryHasUnitsThatMatch(enemyUnitsThatPreventRetreat).negate()`,
//     where `enemyUnitsThatPreventRetreat` ANDs:
//       enemyUnit(attacker), unitIsNotInfrastructure, !unitIsBeingTransported,
//       !unitIsSubmerged, !unitCanBeMovedThroughByEnemies, and (when
//       IgnoreTransportInMovement is on) unitIsNotSeaTransportButCouldBeCombatSeaTransport.
//   - If WW2V2 or WW2V3, further filter `possible` via the lambda that drops
//     territories whose entire attacking-from-units list is air-only.
//   - Remove territories matching
//     isTerritoryEnemyAndNotUnownedWaterOrImpassableOrRestricted(attacker) OR
//     (territoryIsWater AND territoryWasFoughtOver(battleTracker)).
//   - Remove the battle site itself.
//   - If any attacking unit is land and battleSite is not water, filter to
//     land territories. If any attacking unit is sea, filter to water.
must_fight_battle_get_attacker_retreat_territories :: proc(
	self: ^Must_Fight_Battle,
) -> [dynamic]^Territory {
	props := game_data_get_properties(self.game_data)

	all_air := false
	if len(self.attacking_units) > 0 {
		air_p, air_c := matches_unit_is_air()
		all_air = true
		for u in self.attacking_units {
			if !air_p(air_c, u) {
				all_air = false
				break
			}
		}
	}
	if self.headless || all_air || properties_get_retreating_units_remain_in_place(props) {
		out: [dynamic]^Territory
		append(&out, self.battle_site)
		return out
	}

	ignore_transport := properties_get_ignore_transport_in_movement(props)

	enemy_p, enemy_c := matches_enemy_unit(self.attacker)
	not_infra_p, not_infra_c := matches_unit_is_not_infrastructure()
	being_xported_p, being_xported_c := matches_unit_is_being_transported()
	submerged_p, submerged_c := matches_unit_is_submerged()
	moved_through_p, moved_through_c := matches_unit_can_be_moved_through_by_enemies()
	not_sea_xport_combat_p, not_sea_xport_combat_c :=
		matches_unit_is_not_sea_transport_but_could_be_combat_sea_transport()

	possible: [dynamic]^Territory
	for t, _ in self.attacking_from_map {
		has_blocker := false
		for u in t.unit_collection.units {
			if !enemy_p(enemy_c, u) {continue}
			if !not_infra_p(not_infra_c, u) {continue}
			if being_xported_p(being_xported_c, u) {continue}
			if submerged_p(submerged_c, u) {continue}
			if moved_through_p(moved_through_c, u) {continue}
			if ignore_transport && !not_sea_xport_combat_p(not_sea_xport_combat_c, u) {continue}
			has_blocker = true
			break
		}
		if !has_blocker {
			append(&possible, t)
		}
	}

	if properties_get_ww2_v2(props) || properties_get_ww2_v3(props) {
		filtered: [dynamic]^Territory
		for t in possible {
			if must_fight_battle_lambda_get_attacker_retreat_territories_2(rawptr(self), t) {
				append(&filtered, t)
			}
		}
		delete(possible)
		possible = filtered
	}

	conq_p, conq_c := matches_is_territory_enemy_and_not_unowned_water_or_impassable_or_restricted(
		self.attacker,
	)
	water_p, water_c := matches_territory_is_water()
	fought_p, fought_c := matches_territory_was_fought_over(self.battle_tracker)
	{
		filtered: [dynamic]^Territory
		for t in possible {
			cond := conq_p(conq_c, t) ||
				(water_p(water_c, t) && fought_p(fought_c, t))
			if !cond {
				append(&filtered, t)
			}
		}
		delete(possible)
		possible = filtered
	}

	// remove battle site
	{
		filtered: [dynamic]^Territory
		for t in possible {
			if t != self.battle_site {
				append(&filtered, t)
			}
		}
		delete(possible)
		possible = filtered
	}

	any_land := false
	any_sea := false
	land_p, land_c := matches_unit_is_land()
	sea_p, sea_c := matches_unit_is_sea()
	for u in self.attacking_units {
		if land_p(land_c, u) {any_land = true}
		if sea_p(sea_c, u) {any_sea = true}
	}
	if any_land && !territory_is_water(self.battle_site) {
		t_land_p, t_land_c := matches_territory_is_land()
		filtered: [dynamic]^Territory
		for t in possible {
			if t_land_p(t_land_c, t) {
				append(&filtered, t)
			}
		}
		delete(possible)
		possible = filtered
	}
	if any_sea {
		t_water_p, t_water_c := matches_territory_is_water()
		filtered: [dynamic]^Territory
		for t in possible {
			if t_water_p(t_water_c, t) {
				append(&filtered, t)
			}
		}
		delete(possible)
		possible = filtered
	}
	return possible
}

// games.strategy.triplea.delegate.battle.MustFightBattle#writeUnitsToHistory(IDelegateBridge)
must_fight_battle_write_units_to_history :: proc(
	self: ^Must_Fight_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	if self.headless {
		return
	}
	uc := territory_get_unit_collection(self.battle_site)
	players_set := unit_collection_get_players_with_units(uc)
	defer delete(players_set)

	players_with_units: [dynamic]^Game_Player
	defer delete(players_with_units)
	for p, _ in players_set {
		append(&players_with_units, p)
	}

	relationship_tracker := game_data_get_relationship_tracker(self.game_data)
	history_writer := i_delegate_bridge_get_history_writer(bridge)

	attackers := must_fight_battle_find_allies(
		players_with_units,
		self.attacker,
		relationship_tracker,
	)
	defer delete(attackers)
	must_fight_battle_add_player_combat_history_text(
		self,
		attackers,
		self.attacking_units,
		true,
		history_writer,
	)

	defenders := must_fight_battle_find_allies(
		players_with_units,
		self.defender,
		relationship_tracker,
	)
	defer delete(defenders)
	must_fight_battle_add_player_combat_history_text(
		self,
		defenders,
		self.defending_units,
		false,
		history_writer,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#checkDefendingPlanesCanLand()
must_fight_battle_check_defending_planes_can_land :: proc(self: ^Must_Fight_Battle) {
	if self.headless {
		return
	}
	if !territory_is_water(self.battle_site) {
		return
	}
	air_p, air_c := matches_unit_is_air()
	scr_p, scr_c := matches_unit_was_scrambled()

	defending_air: [dynamic]^Unit
	defer delete(defending_air)
	for u in self.defending_units {
		if air_p(air_c, u) && !scr_p(scr_c, u) {
			append(&defending_air, u)
		}
	}
	if len(defending_air) == 0 {
		return
	}

	carrier_cost := air_movement_validator_carrier_cost(defending_air[:])
	carrier_capacity := air_movement_validator_carrier_capacity(
		self.defending_units[:],
		self.battle_site,
	)

	dependent := abstract_battle_get_dependent_units(&self.abstract_battle, self.defending_units)
	defer delete(dependent)
	dependent_air: [dynamic]^Unit
	defer delete(dependent_air)
	for u in dependent {
		if air_p(air_c, u) && !scr_p(scr_c, u) {
			append(&dependent_air, u)
		}
	}
	carrier_cost += air_movement_validator_carrier_cost(dependent_air[:])

	if carrier_capacity >= carrier_cost {
		return
	}

	// recompute carrier_cost from dependent air only, then add cost of each
	// surviving defending air that fits on the available carrier capacity.
	carrier_cost = 0
	carrier_cost += air_movement_validator_carrier_cost(dependent_air[:])

	can_land_p, can_land_c := matches_unit_can_land_on_carrier()

	// iterate over a snapshot of defending_air, modifying defending_air in place
	original: [dynamic]^Unit
	defer delete(original)
	for u in defending_air {
		append(&original, u)
	}

	for current_unit in original {
		if !can_land_p(can_land_c, current_unit) {
			for i := 0; i < len(defending_air); i += 1 {
				if defending_air[i] == current_unit {
					ordered_remove(&defending_air, i)
					break
				}
			}
			continue
		}
		ua := unit_get_unit_attachment(current_unit)
		carrier_cost += unit_attachment_get_carrier_cost(ua)
		if carrier_capacity >= carrier_cost {
			for i := 0; i < len(defending_air); i += 1 {
				if defending_air[i] == current_unit {
					ordered_remove(&defending_air, i)
					break
				}
			}
		}
	}

	// pass remaining defending_air (those that cannot land) up to the battle tracker
	remaining: [dynamic]^Unit
	for u in defending_air {
		append(&remaining, u)
	}
	battle_tracker_add_to_defending_air_that_can_not_land(
		self.battle_tracker,
		remaining,
		self.battle_site,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#<init>(
//     Territory, GamePlayer, GameData, BattleTracker)
//
// Java:
//   super(battleSite, attacker, battleTracker, data);
//   defendingUnits.addAll(this.battleSite.getMatches(Matches.enemyUnit(attacker)));
//   maxRounds = battleSite.isWater()
//       ? Properties.getSeaBattleRounds(data.getProperties())
//       : Properties.getLandBattleRounds(data.getProperties());
//
// The non-final field initializers from the Java class
// (`attackingWaitingToDie = new ArrayList<>()`, etc., plus the
// `stack = new ExecutionStack()` field initializer) run before the
// constructor body in Java; we mirror them here right after the
// embedded base is set up.
must_fight_battle_new :: proc(
	battle_site: ^Territory,
	attacker: ^Game_Player,
	data: ^Game_Data,
	battle_tracker: ^Battle_Tracker,
) -> ^Must_Fight_Battle {
	base := dependent_battle_new(battle_site, attacker, battle_tracker, data)
	self := new(Must_Fight_Battle)
	self.dependent_battle = base^
	free(base)

	// Java field initializers (run before the constructor body in Java).
	self.attacking_waiting_to_die = make([dynamic]^Unit)
	self.defending_waiting_to_die = make([dynamic]^Unit)
	self.killed = make([dynamic]^Unit)
	self.killed_during_current_round = make([dynamic]^Unit)
	self.stack = execution_stack_new()
	self.step_strings = make([dynamic]string)
	self.step_firing_units = make(map[string][dynamic]^Unit)
	self.defending_aa = make([dynamic]^Unit)
	self.offensive_aa = make([dynamic]^Unit)
	self.defending_aa_types = make([dynamic]string)
	self.offensive_aa_types = make([dynamic]string)
	self.attacking_units_retreated = make([dynamic]^Unit)
	self.defending_units_retreated = make([dynamic]^Unit)

	// defendingUnits.addAll(this.battleSite.getMatches(Matches.enemyUnit(attacker)));
	en_p, en_c := matches_enemy_unit(attacker)
	uc := territory_get_unit_collection(battle_site)
	if uc != nil {
		for u in uc.units {
			if en_p(en_c, u) {
				append(&self.defending_units, u)
			}
		}
	}

	// maxRounds = battleSite.isWater() ? sea : land battle rounds
	props := game_data_get_properties(data)
	if territory_is_water(battle_site) {
		self.max_rounds = properties_get_sea_battle_rounds(props)
	} else {
		self.max_rounds = properties_get_land_battle_rounds(props)
	}
	return self
}

// games.strategy.triplea.delegate.battle.MustFightBattle#damagedChangeInto(
//     GamePlayer, Collection<Unit>, Collection<Unit>, IDelegateBridge, Side)
//
// Java:
//   final List<Unit> unitsThatMightTransform =
//       CollectionUtils.getMatches(units,
//           Matches.unitWhenHitPointsDamagedChangesInto().and(
//               Matches.unitHasTakenSomeDamage()));
//   unitsThatMightTransform.addAll(
//       CollectionUtils.getMatches(unitsKilledDuringRound,
//           Matches.unitAtMaxHitPointDamageChangesInto()));
//   final var change =
//       HistoryChangeFactory.transformDamagedUnits(
//           battleSite, unitsThatMightTransform, true);
//   change.perform(bridge);
//   final var oldUnits = List.copyOf(change.getOldUnits());
//   final var newUnits = List.copyOf(change.getNewUnits());
//   cleanupKilledUnits(bridge, side, oldUnits, newUnits);
//   bridge.getDisplayChannelBroadcaster()
//       .changedUnitsNotification(battleId, player, oldUnits, newUnits, null);
must_fight_battle_damaged_change_into :: proc(
	self: ^Must_Fight_Battle,
	player: ^Game_Player,
	units: [dynamic]^Unit,
	units_killed_during_round: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	side: Battle_State_Side,
) {
	dmg_p, dmg_c := matches_unit_when_hit_points_damaged_changes_into()
	taken_p, taken_c := matches_unit_has_taken_some_damage()
	max_p, max_c := matches_unit_at_max_hit_point_damage_changes_into()

	units_that_might_transform: [dynamic]^Unit
	for u in units {
		if dmg_p(dmg_c, u) && taken_p(taken_c, u) {
			append(&units_that_might_transform, u)
		}
	}
	for u in units_killed_during_round {
		if max_p(max_c, u) {
			append(&units_that_might_transform, u)
		}
	}

	change := history_change_factory_transform_damaged_units(
		self.battle_site,
		units_that_might_transform,
		true,
	)
	transform_damaged_units_history_change_perform(change, bridge)

	old_units := transform_damaged_units_history_change_get_old_units(change)
	new_units := transform_damaged_units_history_change_get_new_units(change)

	must_fight_battle_cleanup_killed_units(self, bridge, side, old_units, new_units)

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_changed_units_notification(
		display,
		self.battle_id,
		player,
		old_units,
		new_units,
		nil,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#getBattleExecutables()
//
// Java:
//   final List<IExecutable> steps =
//       BattleStep.getAll(this, this).stream()
//           .sorted(Comparator.comparing(BattleStep::getOrder))
//           .collect(Collectors.toList());
//   addRoundResetStep(steps);
//   return steps;
//
// `Battle_Step` does not carry a virtual `order` field in the Odin
// port (compare `Battle_Steps_Step_Entry` in battle_steps.odin), so we
// pair each freshly built step with its concrete `*_get_order` value,
// sort the pairs by the underlying `Battle_Step_Order` ordinal, then
// flatten back into the [dynamic]^I_Executable result that
// `addRoundResetStep` expects.
Must_Fight_Battle_Executable_Entry :: struct {
	order:      Battle_Step_Order,
	executable: ^I_Executable,
}

must_fight_battle_executable_entry_less :: proc(
	a, b: Must_Fight_Battle_Executable_Entry,
) -> bool {
	return int(a.order) < int(b.order)
}

must_fight_battle_get_battle_executables :: proc(
	self: ^Must_Fight_Battle,
) -> [dynamic]^I_Executable {
	bs := cast(^Battle_State)self
	ba := cast(^Battle_Actions)self

	entries := make([dynamic]Must_Fight_Battle_Executable_Entry, 0, 24)

	{
		s := offensive_aa_fire_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = offensive_aa_fire_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := defensive_aa_fire_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = defensive_aa_fire_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := submerge_subs_vs_only_air_step_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = submerge_subs_vs_only_air_step_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := remove_unprotected_units_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = remove_unprotected_units_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := naval_bombardment_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = naval_bombardment_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := clear_bombardment_casualties_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = clear_bombardment_casualties_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := land_paratroopers_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = land_paratroopers_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := offensive_subs_retreat_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = offensive_subs_retreat_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := defensive_subs_retreat_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = defensive_subs_retreat_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := offensive_first_strike_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = offensive_first_strike_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := defensive_first_strike_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = defensive_first_strike_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := clear_first_strike_casualties_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = clear_first_strike_casualties_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := offensive_general_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = offensive_general_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := defensive_general_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = defensive_general_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := clear_aa_casualties_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = clear_aa_casualties_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := remove_non_combatants_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = remove_non_combatants_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := mark_no_movement_left_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = mark_no_movement_left_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := remove_first_strike_suicide_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = remove_first_strike_suicide_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := remove_general_suicide_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = remove_general_suicide_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := offensive_general_retreat_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = offensive_general_retreat_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := clear_general_casualties_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = clear_general_casualties_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := remove_unprotected_units_general_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = remove_unprotected_units_general_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := check_general_battle_end_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = check_general_battle_end_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}
	{
		s := check_stalemate_battle_end_new(bs, ba)
		append(
			&entries,
			Must_Fight_Battle_Executable_Entry{
				order = check_stalemate_battle_end_get_order(s),
				executable = &s.battle_step.i_executable,
			},
		)
	}

	slice.sort_by(entries[:], must_fight_battle_executable_entry_less)

	out := make([dynamic]^I_Executable, 0, len(entries))
	for e in entries {
		append(&out, e.executable)
	}
	delete(entries)

	must_fight_battle_add_round_reset_step(self, &out)
	return out
}

// games.strategy.triplea.delegate.battle.MustFightBattle#determineStepStrings()
//
// Java:
//   stepStrings = new ArrayList<>();
//   stepFiringUnits = new HashMap<>();
//   for (var details : BattleSteps.builder().battleState(this).battleActions(this).build().get()) {
//     String stepName = details.getName();
//     stepStrings.add(stepName);
//     if (details.getStep() instanceof SelectCasualties) {
//       SelectCasualties step = (SelectCasualties) details.getStep();
//       stepFiringUnits.put(stepName, step.getFiringGroup().getFiringUnits());
//     }
//   }
//   return stepStrings;
//
// Note on the SelectCasualties branch: in this Odin port, `Select_Casualties`
// does NOT embed `Battle_Step` (see select_casualties.odin), and the only
// place that wraps a SelectCasualties into a `Battle_Step_Step_Details`
// (`select_casualties_get_all_step_details`) sets `step = nil` and is
// itself never reached from `battle_steps_get` — the firing-round
// sub-steps produced by `fire_round_steps_factory_create_steps` are
// untyped `^Battle_Step` allocations rather than embedded subtypes.
// Consequently the Odin equivalent of `details.getStep() instanceof
// SelectCasualties` is unreachable; we still mirror the Java loop
// structure so future architectural changes that re-introduce typed
// SelectCasualties details can fill in the population by checking the
// step pointer.
must_fight_battle_determine_step_strings :: proc(self: ^Must_Fight_Battle) -> [dynamic]string {
	delete(self.step_strings)
	self.step_strings = make([dynamic]string)
	for _, units in self.step_firing_units {
		delete(units)
	}
	clear(&self.step_firing_units)

	builder := battle_steps_builder()
	battle_steps_battle_steps_builder_battle_state(builder, cast(^Battle_State)self)
	battle_steps_battle_steps_builder_battle_actions(builder, cast(^Battle_Actions)self)
	steps := battle_steps_battle_steps_builder_build(builder)
	all_details := battle_steps_get(steps)
	defer delete(all_details)

	for details in all_details {
		step_name := battle_step_step_details_get_name(details)
		append(&self.step_strings, step_name)
		// SelectCasualties detection is unreachable in this port — see
		// the proc-level comment above. The step pointer is kept on
		// `details` for future architectural changes.
		_ = battle_step_step_details_get_step(details)
	}
	return self.step_strings
}

// games.strategy.triplea.delegate.battle.MustFightBattle#pushFightLoopOnStack()
//
// Java:
//   if (isOver) return;
//   final List<IExecutable> steps = getBattleExecutables();
//   // add in the reverse order we create them
//   Collections.reverse(steps);
//   for (final IExecutable step : steps) {
//     stack.push(step);
//   }
must_fight_battle_push_fight_loop_on_stack :: proc(self: ^Must_Fight_Battle) {
	if self.is_over {
		return
	}
	steps := must_fight_battle_get_battle_executables(self)
	defer delete(steps)
	n := len(steps)
	for i := 0; i < n / 2; i += 1 {
		steps[i], steps[n - 1 - i] = steps[n - 1 - i], steps[i]
	}
	for step in steps {
		execution_stack_push_one(self.stack, step)
	}
}

// games.strategy.triplea.delegate.battle.MustFightBattle#removeUnits(
//     Collection<Unit>, IDelegateBridge, Territory, BattleState.Side)
//
// Java:
//   if (killedUnits.isEmpty()) return;
//   // Note: dedup with a LinkedHashSet (preserves insertion order).
//   final var uniqueKilledUnits = new LinkedHashSet<>(killedUnits);
//   final RemoveUnitsHistoryChange removeUnitsHistoryChange =
//       HistoryChangeFactory.removeUnitsFromTerritory(battleSite, uniqueKilledUnits);
//   final Collection<Unit> killedUnitsIncludingDependents =
//       removeUnitsHistoryChange.getOldUnits();
//   final Collection<Unit> transformedUnits = removeUnitsHistoryChange.getNewUnits();
//   removeUnitsHistoryChange.perform(bridge);
//   cleanupKilledUnits(bridge, side, killedUnitsIncludingDependents, transformedUnits);
must_fight_battle_remove_units :: proc(
	self: ^Must_Fight_Battle,
	killed_units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	battle_site: ^Territory,
	side: Battle_State_Side,
) {
	if len(killed_units) == 0 {
		return
	}

	// new LinkedHashSet<>(killedUnits): dedup while preserving insertion order.
	seen: map[^Unit]struct{}
	defer delete(seen)
	unique_killed_units: [dynamic]^Unit
	for u in killed_units {
		if _, ok := seen[u]; !ok {
			seen[u] = {}
			append(&unique_killed_units, u)
		}
	}

	remove_units_history_change := history_change_factory_remove_units_from_territory(
		battle_site,
		unique_killed_units,
	)

	killed_units_including_dependents := remove_units_history_change_get_old_units(
		remove_units_history_change,
	)
	transformed_units := remove_units_history_change_get_new_units(remove_units_history_change)
	remove_units_history_change_perform(remove_units_history_change, bridge)

	must_fight_battle_cleanup_killed_units(
		self,
		bridge,
		side,
		killed_units_including_dependents,
		transformed_units,
	)
}

// games.strategy.triplea.delegate.battle.MustFightBattle#clearWaitingToDieAndDamagedChangesInto(IDelegateBridge, BattleState.Side...)
//
//   for (final Side side : sides) {
//     if (side == OFFENSE) {
//       Collection<Unit> killed = CollectionUtils.getMatches(
//           killedDuringCurrentRound, Matches.unitIsOwnedBy(attacker));
//       damagedChangeInto(attacker, attackingUnits, killed, bridge, side);
//       removeUnits(attackingWaitingToDie, bridge, battleSite, side);
//       attackingWaitingToDie.clear();
//     } else {
//       Collection<Unit> killed = CollectionUtils.getMatches(
//           killedDuringCurrentRound, Matches.unitIsOwnedBy(attacker).negate());
//       damagedChangeInto(defender, defendingUnits, killed, bridge, side);
//       removeUnits(defendingWaitingToDie, bridge, battleSite, side);
//       defendingWaitingToDie.clear();
//     }
//   }
//   killedDuringCurrentRound.clear();
must_fight_battle_clear_waiting_to_die_and_damaged_changes_into :: proc(
	self: ^Must_Fight_Battle,
	bridge: ^I_Delegate_Bridge,
	sides: ..Battle_State_Side,
) {
	owned_pred, owned_ctx := matches_unit_is_owned_by(self.attacker)
	for side in sides {
		if side == .OFFENSE {
			killed: [dynamic]^Unit
			for u in self.killed_during_current_round {
				if owned_pred(owned_ctx, u) {
					append(&killed, u)
				}
			}
			must_fight_battle_damaged_change_into(
				self,
				self.attacker,
				self.attacking_units,
				killed,
				bridge,
				side,
			)
			must_fight_battle_remove_units(
				self,
				self.attacking_waiting_to_die,
				bridge,
				self.battle_site,
				side,
			)
			clear(&self.attacking_waiting_to_die)
		} else {
			killed: [dynamic]^Unit
			for u in self.killed_during_current_round {
				if !owned_pred(owned_ctx, u) {
					append(&killed, u)
				}
			}
			must_fight_battle_damaged_change_into(
				self,
				self.defender,
				self.defending_units,
				killed,
				bridge,
				side,
			)
			must_fight_battle_remove_units(
				self,
				self.defending_waiting_to_die,
				bridge,
				self.battle_site,
				side,
			)
			clear(&self.defending_waiting_to_die)
		}
	}
	clear(&self.killed_during_current_round)
}


