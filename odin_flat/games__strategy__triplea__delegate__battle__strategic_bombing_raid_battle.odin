package game

import "core:fmt"

// Port of games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle.
// Implements interface BattleStepStrings (constants only; not modeled).

Strategic_Bombing_Raid_Battle :: struct {
	using abstract_battle: Abstract_Battle,
	targets: map[^Unit]map[^Unit]struct{},
	stack: ^Execution_Stack,
	steps: [dynamic]string,
	defending_aa: [dynamic]^Unit,
	aa_types: [dynamic]string,
	bombing_raid_total: i32,
	bombing_raid_damage: Integer_Map,
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#isEmpty
strategic_bombing_raid_battle_is_empty :: proc(self: ^Strategic_Bombing_Raid_Battle) -> bool {
	return len(self.attacking_units) == 0
}

// Java: lambda$removeUnitsThatNoLongerExist$0(Unit)
//   unit -> !battleSite.getUnits().contains(unit)
// `battleSite` is captured; passed explicitly here.
strategic_bombing_raid_battle_lambda_remove_units_that_no_longer_exist_0 :: proc(
	battle_site: ^Territory,
	unit: ^Unit,
) -> bool {
	return !unit_collection_contains(battle_site.unit_collection, unit)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#removeUnitsThatNoLongerExist
//
//   if (headless) return;
//   defendingUnits.retainAll(battleSite.getUnits());
//   attackingUnits.retainAll(battleSite.getUnits());
//   targets.keySet().removeIf(unit -> !battleSite.getUnits().contains(unit));
strategic_bombing_raid_battle_remove_units_that_no_longer_exist :: proc(self: ^Strategic_Bombing_Raid_Battle) {
	if self.headless {
		return
	}
	// retainAll for defending/attacking matches the parent body exactly.
	abstract_battle_remove_units_that_no_longer_exist(&self.abstract_battle)
	// targets.keySet().removeIf(...)
	keys_to_remove: [dynamic]^Unit
	for key in self.targets {
		if strategic_bombing_raid_battle_lambda_remove_units_that_no_longer_exist_0(self.battle_site, key) {
			append(&keys_to_remove, key)
		}
	}
	for k in keys_to_remove {
		inner := self.targets[k]
		delete(inner)
		delete_key(&self.targets, k)
	}
	delete(keys_to_remove)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#removeAttackers
//
//   attackingUnits.removeAll(units);
//   for each target key: currentAttackers.removeAll(units);
//     if currentAttackers.isEmpty() && removeTarget: targetIter.remove();
strategic_bombing_raid_battle_remove_attackers :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
	units: [dynamic]^Unit,
	remove_target: bool,
) {
	// attackingUnits.removeAll(units)
	kept: [dynamic]^Unit
	for u in self.attacking_units {
		found := false
		for r in units {
			if u == r {
				found = true
				break
			}
		}
		if !found {
			append(&kept, u)
		}
	}
	delete(self.attacking_units)
	self.attacking_units = kept

	// Iterate target keys; mutate inner sets, collecting keys whose set
	// becomes empty (and removeTarget is true) for deletion afterwards.
	keys_to_remove: [dynamic]^Unit
	for key in self.targets {
		inner := self.targets[key]
		for r in units {
			delete_key(&inner, r)
		}
		// Map header is a handle; write back is unnecessary, but reflect
		// the current state in the map entry to be safe.
		self.targets[key] = inner
		if len(inner) == 0 && remove_target {
			append(&keys_to_remove, key)
		}
	}
	for k in keys_to_remove {
		inner := self.targets[k]
		delete(inner)
		delete_key(&self.targets, k)
	}
	delete(keys_to_remove)
}

// Java: lambda$getTarget$1(Unit, Map.Entry<Unit, Set<Unit>>)
//   e -> e.getValue().contains(attacker)
// `attacker` captured; entry split into key + value for the Odin call.
strategic_bombing_raid_battle_lambda_get_target_1 :: proc(
	attacker: ^Unit,
	entry_key: ^Unit,
	entry_value: map[^Unit]struct{},
) -> bool {
	_ = entry_key
	return attacker in entry_value
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#getTarget
//
//   return targets.entrySet().stream()
//       .filter(e -> e.getValue().contains(attacker))
//       .map(Entry::getKey)
//       .findAny()
//       .orElseThrow(() -> new IllegalStateException(
//           MessageFormat.format("Unit {0} has no target", attacker.getType().getName())));
strategic_bombing_raid_battle_get_target :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
	attacker: ^Unit,
) -> ^Unit {
	for key, value in self.targets {
		if strategic_bombing_raid_battle_lambda_get_target_1(attacker, key, value) {
			return key
		}
	}
	type_name := ""
	t := unit_get_type(attacker)
	if t != nil {
		type_name = default_named_get_name(&t.named_attachable.default_named)
	}
	panic(fmt.aprintf("Unit %s has no target", type_name))
}

// Java: lambda$addAttackChange$3(Unit)
//   i -> new HashSet<>()  (computeIfAbsent value supplier)
strategic_bombing_raid_battle_lambda_add_attack_change_3 :: proc(key: ^Unit) -> map[^Unit]struct{} {
	_ = key
	return make(map[^Unit]struct{})
}

// Java: lambda$addAttackChange$4(Unit, Set<Unit>)
//   (target, targetAttackers) -> {
//     final Set<Unit> currentAttackers =
//         this.targets.computeIfAbsent(target, i -> new HashSet<>());
//     currentAttackers.addAll(targetAttackers);
//   }
// `this.targets` is captured; passed explicitly as `self`.
strategic_bombing_raid_battle_lambda_add_attack_change_4 :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
	target: ^Unit,
	target_attackers: map[^Unit]struct{},
) {
	if !(target in self.targets) {
		self.targets[target] = strategic_bombing_raid_battle_lambda_add_attack_change_3(target)
	}
	current := self.targets[target]
	for u, _ in target_attackers {
		current[u] = struct{}{}
	}
	self.targets[target] = current
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#addAttackChange
//
//   attackingUnits.addAll(units);
//   if (targets == null) return ChangeFactory.EMPTY_CHANGE;
//   targets.forEach((target, targetAttackers) -> { ...lambda$4... });
//   return ChangeFactory.EMPTY_CHANGE;
strategic_bombing_raid_battle_add_attack_change :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
	route: ^Route,
	units: [dynamic]^Unit,
	targets: ^map[^Unit]map[^Unit]struct{},
) -> ^Change {
	_ = route
	for u in units {
		append(&self.attacking_units, u)
	}
	empty := new(Change_Factory_1)
	empty.kind = .Change_Factory_1
	if targets == nil {
		return &empty.change
	}
	for target, target_attackers in targets^ {
		strategic_bombing_raid_battle_lambda_add_attack_change_4(self, target, target_attackers)
	}
	return &empty.change
}
