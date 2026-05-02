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


