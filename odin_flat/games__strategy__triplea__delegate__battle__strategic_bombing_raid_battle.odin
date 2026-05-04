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

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#getBattleType
//
//   inherited from AbstractBattle: returns the battle_type field set by the
//   constructor (BOMBING_RAID).
strategic_bombing_raid_battle_get_battle_type :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
) -> I_Battle_Battle_Type {
	return self.battle_type
}

// Java: lambda$getTarget$2(Unit attacker)
//   () -> new IllegalStateException(MessageFormat.format(
//       "Unit {0} has no target", attacker.getType().getName()))
// Captured `attacker` becomes the parameter. Odin lacks exceptions, so this
// returns the formatted message string the caller can use to panic.
strategic_bombing_raid_battle_lambda__get_target__2 :: proc(attacker: ^Unit) -> string {
	type_name := ""
	t := unit_get_type(attacker)
	if t != nil {
		type_name = default_named_get_name(&t.named_attachable.default_named)
	}
	return fmt.aprintf("Unit %s has no target", type_name)
}

// Java: lambda$fight$5(Map.Entry<Unit, Set<Unit>> entry)
//   entry -> entry.getKey().getUnitAttachment().isAaForBombingThisUnitOnly()
// The Map.Entry is split into key + value at the Odin call site; only the
// key is used by the predicate.
strategic_bombing_raid_battle_lambda__fight__5 :: proc(
	entry_key: ^Unit,
	entry_value: map[^Unit]struct{},
) -> bool {
	_ = entry_value
	return unit_attachment_is_aa_for_bombing_this_unit_only(unit_get_unit_attachment(entry_key))
}

// Java: lambda$fight$6(Collection<Unit> attackers)
//   FireAa::new — constructor reference desugared to a static helper that
//   takes the Set<Unit> entry value and constructs a FireAa for it.
//   Captures the enclosing StrategicBombingRaidBattle (`this_0`).
strategic_bombing_raid_battle_lambda__fight__6 :: proc(
	this_0: ^Strategic_Bombing_Raid_Battle,
	attackers: [dynamic]^Unit,
) -> ^Fire_Aa {
	return fire_aa_new_with_attackers(this_0, attackers)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#postBombing
//
//   @Nonnull
//   private IExecutable postBombing() {
//     return new IExecutable() { ... };  // anonymous class StrategicBombingRaidBattle$1
//   }
// The anonymous class is `Strategic_Bombing_Raid_Battle_1`. The execute body
// is a separate method_key and lives on the inner struct; this proc only
// performs the construction Java does at the postBombing call site.
strategic_bombing_raid_battle_post_bombing :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
) -> ^I_Executable {
	inner := strategic_bombing_raid_battle_1_new(self)
	return &inner.i_executable
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#end
//
//   private IExecutable end() {
//     return new IExecutable() { ... };  // anonymous class StrategicBombingRaidBattle$2
//   }
// Mirrors `postBombing`: constructs the anonymous IExecutable subtype
// (`Strategic_Bombing_Raid_Battle_2`) and returns its embedded I_Executable.
strategic_bombing_raid_battle_end :: proc(
	self: ^Strategic_Bombing_Raid_Battle,
) -> ^I_Executable {
	inner := strategic_bombing_raid_battle_2_new(self)
	return &inner.i_executable
}

// Java: lambda$notifyAaHits$7(IDelegateBridge)
//
//   () -> {
//     try {
//       final Player defender = bridge.getRemotePlayer(this.defender);
//       defender.confirmEnemyCasualties(battleId, "Press space to continue", attacker);
//     } catch (final Exception e) { /* ignore */ }
//   }
//
// Captured: this (Strategic_Bombing_Raid_Battle) and bridge (passed as arg).
strategic_bombing_raid_battle_lambda__notify_aa_hits__7 :: proc(
	self:   ^Strategic_Bombing_Raid_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	defender := i_delegate_bridge_get_remote_player(bridge, self.defender)
	if defender == nil {
		return
	}
	player_confirm_enemy_casualties(
		defender,
		self.battle_id,
		"Press space to continue",
		self.attacker,
	)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#showBattle
//
//   final String title = MessageFormat.format("Bombing raid in {0}", battleSite.getName());
//   bridge.getDisplayChannelBroadcaster().showBattle(
//       battleId, battleSite, title,
//       attackingUnits, defendingUnits,
//       List.of(), List.of(), List.of(),
//       Map.of(),
//       attacker, defender,
//       false, getBattleType(),
//       Set.of());
//   bridge.getDisplayChannelBroadcaster().listBattleSteps(battleId, steps);
strategic_bombing_raid_battle_show_battle :: proc(
	self:   ^Strategic_Bombing_Raid_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	site_name := default_named_get_name(&self.battle_site.named_attachable.default_named)
	title := fmt.aprintf("Bombing raid in %s", site_name)

	empty_units_1: [dynamic]^Unit
	empty_units_2: [dynamic]^Unit
	empty_units_3: [dynamic]^Unit
	empty_amphib:  [dynamic]^Unit
	empty_dependents := make(map[^Unit][dynamic]^Unit)

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_show_battle(
		display,
		self.battle_id,
		self.battle_site,
		title,
		self.attacking_units,
		self.defending_units,
		empty_units_1,
		empty_units_2,
		empty_units_3,
		empty_dependents,
		self.attacker,
		self.defender,
		false,
		strategic_bombing_raid_battle_get_battle_type(self),
		empty_amphib,
	)
	i_display_list_battle_steps(
		i_delegate_bridge_get_display_channel_broadcaster(bridge),
		self.battle_id,
		self.steps,
	)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#endBeforeRolling
//
//   private void endBeforeRolling(final IDelegateBridge bridge) {
//     bridge.getDisplayChannelBroadcaster().battleEnd(battleId, "Bombing raid does no damage");
//     whoWon = WhoWon.DRAW;
//     battleResultDescription = BattleRecord.BattleResultDescription.NO_BATTLE;
//     battleTracker.getBattleRecords().addResultToBattle(
//         attacker, battleId, defender, attackerLostTuv, defenderLostTuv,
//         battleResultDescription, new BattleResults(this, gameData));
//     isOver = true;
//     battleTracker.removeBattle(StrategicBombingRaidBattle.this, gameData);
//   }
strategic_bombing_raid_battle_end_before_rolling :: proc(
	self:   ^Strategic_Bombing_Raid_Battle,
	bridge: ^I_Delegate_Bridge,
) {
	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_battle_end(display, self.battle_id, "Bombing raid does no damage")
	self.who_won = .DRAW
	self.battle_result_description = .NO_BATTLE
	battle_records_add_result_to_battle(
		battle_tracker_get_battle_records(self.battle_tracker),
		self.attacker,
		self.battle_id,
		self.defender,
		self.attacker_lost_tuv,
		self.defender_lost_tuv,
		self.battle_result_description,
		battle_results_new(cast(^I_Battle)&self.abstract_battle, self.game_data),
	)
	self.is_over = true
	battle_tracker_remove_battle(
		self.battle_tracker,
		cast(^I_Battle)&self.abstract_battle,
		self.game_data,
	)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#getSbrRolls(Unit, GamePlayer)
//
//   public static int getSbrRolls(final Unit unit, final GamePlayer gamePlayer) {
//     return unit.getUnitAttachment().getAttackRolls(gamePlayer);
//   }
strategic_bombing_raid_battle_get_sbr_rolls_unit :: proc(
	unit:        ^Unit,
	game_player: ^Game_Player,
) -> i32 {
	return unit_attachment_get_attack_rolls_with_player(
		unit_get_unit_attachment(unit),
		game_player,
	)
}

// games.strategy.triplea.delegate.battle.StrategicBombingRaidBattle#notifyAaHits
//
//   private void notifyAaHits(IDelegateBridge bridge, DiceRoll dice,
//                             CasualtyDetails casualties, String currentTypeAa) {
//     bridge.getDisplayChannelBroadcaster().casualtyNotification(
//         battleId,
//         NOTIFY_PREFIX + currentTypeAa + CASUALTIES_SUFFIX,
//         dice, attacker,
//         new ArrayList<>(casualties.getKilled()),
//         new ArrayList<>(casualties.getDamaged()),
//         Map.of());
//     final Thread t = new Thread(() -> { try { ...lambda$7... } catch ... });
//     t.start();
//     final Player attacker = bridge.getRemotePlayer(this.attacker);
//     attacker.confirmOwnCasualties(battleId, "Press space to continue");
//     bridge.leaveDelegateExecution();
//     Interruptibles.join(t);
//     bridge.enterDelegateExecution();
//   }
//
// The snapshot harness is single-threaded and the I_Delegate_Bridge vtable
// does not expose leaveDelegateExecution; mirroring mark_casualties.odin we
// invoke lambda$7 inline (preserving observable order) and skip leave/enter.
strategic_bombing_raid_battle_notify_aa_hits :: proc(
	self:            ^Strategic_Bombing_Raid_Battle,
	bridge:          ^I_Delegate_Bridge,
	dice:            ^Dice_Roll,
	casualties:      ^Casualty_Details,
	current_type_aa: string,
) {
	step := fmt.aprintf(
		"%s%s%s",
		BATTLE_STEP_NOTIFY_PREFIX,
		current_type_aa,
		BATTLE_STEP_CASUALTIES_SUFFIX,
	)

	killed_copy: [dynamic]^Unit
	for u in casualties.killed {
		append(&killed_copy, u)
	}
	damaged_copy: [dynamic]^Unit
	for u in casualties.damaged {
		append(&damaged_copy, u)
	}
	empty_dependents := make(map[^Unit][dynamic]^Unit)

	display := i_delegate_bridge_get_display_channel_broadcaster(bridge)
	i_display_casualty_notification(
		display,
		self.battle_id,
		step,
		dice,
		self.attacker,
		killed_copy,
		damaged_copy,
		empty_dependents,
	)

	// Thread body — see lambda$notifyAaHits$7 above.
	strategic_bombing_raid_battle_lambda__notify_aa_hits__7(self, bridge)

	remote_attacker := i_delegate_bridge_get_remote_player(bridge, self.attacker)
	if remote_attacker != nil {
		player_confirm_own_casualties(
			remote_attacker,
			self.battle_id,
			"Press space to continue",
		)
	}
}
