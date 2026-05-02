package game

import "core:fmt"

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


