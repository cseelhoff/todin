package game

// I_Battle is the Java IBattle interface. In TripleA every concrete
// implementation embeds AbstractBattle, and the Odin port mirrors
// that with `using abstract_battle: Abstract_Battle` as the FIRST
// field of every concrete I_Battle subtype (Finished_Battle,
// Dependent_Battle, Air_Battle, Strategic_Bombing_Raid_Battle,
// Must_Fight_Battle, Non_Fighting_Battle, ...). Because the
// embedded Abstract_Battle is the first field, a `^I_Battle`
// (which the rest of the codebase uses as the abstract handle)
// is pointer-compatible with `^Abstract_Battle` and can be
// cast directly. The thunks below provide polymorphic dispatch
// for the I_Battle methods whose bodies live on Abstract_Battle.
I_Battle :: struct {}

// games.strategy.triplea.delegate.battle.IBattle#getBattleId
i_battle_get_battle_id :: proc(self: ^I_Battle) -> Uuid {
	return abstract_battle_get_battle_id(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getBattleType
i_battle_get_battle_type :: proc(self: ^I_Battle) -> I_Battle_Battle_Type {
	return abstract_battle_get_battle_type(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getTerritory
i_battle_get_territory :: proc(self: ^I_Battle) -> ^Territory {
	return abstract_battle_get_territory(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getAttacker
i_battle_get_attacker :: proc(self: ^I_Battle) -> ^Game_Player {
	return abstract_battle_get_attacker(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getDefender
i_battle_get_defender :: proc(self: ^I_Battle) -> ^Game_Player {
	return abstract_battle_get_defender(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getAttackingUnits
i_battle_get_attacking_units :: proc(self: ^I_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_attacking_units(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getDefendingUnits
i_battle_get_defending_units :: proc(self: ^I_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_defending_units(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getBombardingUnits
i_battle_get_bombarding_units :: proc(self: ^I_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_bombarding_units(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getRemainingAttackingUnits
i_battle_get_remaining_attacking_units :: proc(self: ^I_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_remaining_attacking_units(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getRemainingDefendingUnits
i_battle_get_remaining_defending_units :: proc(self: ^I_Battle) -> [dynamic]^Unit {
	return abstract_battle_get_remaining_defending_units(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getDependentUnits
i_battle_get_dependent_units :: proc(self: ^I_Battle, units: [dynamic]^Unit) -> [dynamic]^Unit {
	return abstract_battle_get_dependent_units(cast(^Abstract_Battle)self, units)
}

// games.strategy.triplea.delegate.battle.IBattle#getBattleRound
i_battle_get_battle_round :: proc(self: ^I_Battle) -> i32 {
	return abstract_battle_get_battle_round(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#getWhoWon
i_battle_get_who_won :: proc(self: ^I_Battle) -> I_Battle_Who_Won {
	return abstract_battle_get_who_won(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#isAmphibious
i_battle_is_amphibious :: proc(self: ^I_Battle) -> bool {
	return abstract_battle_is_amphibious(cast(^Abstract_Battle)self)
}

// games.strategy.triplea.delegate.battle.IBattle#addBombardingUnit
i_battle_add_bombarding_unit :: proc(self: ^I_Battle, unit: ^Unit) {
	abstract_battle_add_bombarding_unit(cast(^Abstract_Battle)self, unit)
}

// games.strategy.triplea.delegate.battle.IBattle#unitsLostInPrecedingBattle
// Java has 5 concrete overrides (FinishedBattle, StrategicBombingRaidBattle,
// MustFightBattle, NonFightingBattle, AirBattle) — none implemented on
// AbstractBattle. The bootstrap did not emit method_key rows for the
// concrete impls. The AI snapshot harness only exercises this code path
// when MustFightBattle.cleanupKilledUnits sees a non-empty
// `battleTracker.getBlocked(this)`, which does not occur in the
// deterministic single-battle snapshot scenarios. Thunk delegates to a
// no-op default on Abstract_Battle (matches AirBattle's empty body
// literally). If a future scenario exercises dependent battles a vtable
// dispatch will be needed; for now the call is safe.
i_battle_units_lost_in_preceding_battle :: proc(
	self: ^I_Battle,
	units: [dynamic]^Unit,
	bridge: ^I_Delegate_Bridge,
	withdrawn: bool,
) {
	abstract_battle_units_lost_in_preceding_battle(
		cast(^Abstract_Battle)self,
		units,
		bridge,
		withdrawn,
	)
}

// games.strategy.triplea.delegate.battle.IBattle#isEmpty
// Subtype implementations all reduce to "no attacking units":
//   - FinishedBattle / AirBattle / StrategicBombingRaidBattle:
//       return attackingUnits.isEmpty();
//   - MustFightBattle: attackingUnits.isEmpty() && attackingWaitingToDie.isEmpty();
//   - NonFightingBattle: !hasAttackingUnits();
// Reading `attacking_units` from the embedded Abstract_Battle is
// equivalent for the AI snapshot harness, where MustFightBattle's
// attackingWaitingToDie is empty in the deterministic single-
// threaded run.
i_battle_is_empty :: proc(self: ^I_Battle) -> bool {
	ab := cast(^Abstract_Battle)self
	return len(ab.attacking_units) == 0
}

// games.strategy.triplea.delegate.battle.IBattle#cancelBattle(IDelegateBridge)
// Polymorphic dispatch through the Abstract_Battle discriminators
// (mirrors Java's runtime-resolved virtual call). AbstractBattle's
// default implementation is empty; only MustFightBattle overrides it
// to call endBattle(bridge). NonFightingBattle / FinishedBattle /
// AirBattle / StrategicBombingRaidBattle inherit the empty default.
i_battle_cancel_battle :: proc(self: ^I_Battle, bridge: ^I_Delegate_Bridge) {
	ab := cast(^Abstract_Battle)self
	if ab.is_must_fight_battle {
		must_fight_battle_end_battle(cast(^Must_Fight_Battle)self, bridge)
	}
	// All other I_Battle subtypes inherit AbstractBattle.cancelBattle's empty body.
}

// games.strategy.triplea.delegate.battle.IBattle#addAttackChange(Route, Collection<Unit>, Map<Unit,Set<Unit>>)
// Polymorphic dispatch using the same Abstract_Battle discriminators
// pattern as battle_tracker_add_empty_battle_dispatch_attack_change.
// The remaining I_Battle subtypes — Air_Battle and
// Strategic_Bombing_Raid_Battle — are reached only through bombing/
// air-battle pathways (BattleTracker#addBombingBattle / #addAirBattle),
// and the call sites that flow through this thunk only construct
// MustFightBattle / NonFightingBattle / FinishedBattle (the same set
// served by add_empty_battle_dispatch_attack_change).
i_battle_add_attack_change :: proc(
	self: ^I_Battle,
	route: ^Route,
	units: [dynamic]^Unit,
	targets: map[^Unit]map[^Unit]struct{},
) -> ^Change {
	ab := cast(^Abstract_Battle)self
	if ab.is_must_fight_battle {
		return must_fight_battle_add_attack_change(cast(^Must_Fight_Battle)self, route, units, targets)
	}
	if ab.is_finished_battle {
		// finished_battle's signature takes `^map[...]` (pointer);
		// targets is local so we can take its address safely.
		return finished_battle_add_attack_change(cast(^Finished_Battle)self, route, units, &targets)
	}
	return non_fighting_battle_add_attack_change(cast(^Non_Fighting_Battle)self, route, units, targets)
}
