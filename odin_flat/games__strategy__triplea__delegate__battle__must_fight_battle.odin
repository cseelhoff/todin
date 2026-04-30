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

