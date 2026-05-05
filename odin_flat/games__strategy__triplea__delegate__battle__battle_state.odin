package game

// Battle_State is the Java BattleState interface. The only concrete
// impl in the AI snapshot slice is MustFightBattle, so the thunks
// below cast self to ^Must_Fight_Battle and forward. This pattern
// mirrors the I_Battle → Abstract_Battle thunk file. The bootstrap
// (auto_implement_trivial_methods.py) auto-marks all 17 BattleState
// methods is_implemented=1 at layer 0 but does not emit Odin thunks;
// thunks are added here on-demand as orchestrator-owned
// infrastructure (same status as JDK shims) when a layer-N method
// genuinely needs them.
Battle_State :: struct {}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.BattleState

// games.strategy.triplea.delegate.battle.BattleState#filterUnits
battle_state_filter_units :: proc(
	self: ^Battle_State,
	filter: ^Battle_State_Unit_Battle_Filter,
	sides: ..Battle_State_Side,
) -> [dynamic]^Unit {
	return must_fight_battle_filter_units(cast(^Must_Fight_Battle)self, filter, ..sides)
}

// games.strategy.triplea.delegate.battle.BattleState#getAttackerRetreatTerritories
// Forward-refs must_fight_battle_get_attacker_retreat_territories,
// which lives at method_layer 4 — by Phase C compile time it will
// be implemented.
battle_state_get_attacker_retreat_territories :: proc(
	self: ^Battle_State,
) -> [dynamic]^Territory {
	return must_fight_battle_get_attacker_retreat_territories(cast(^Must_Fight_Battle)self)
}

// games.strategy.triplea.delegate.battle.BattleState#getPlayer(Side)
battle_state_get_player :: proc(self: ^Battle_State, side: Battle_State_Side) -> ^Game_Player {
	return must_fight_battle_get_player(cast(^Must_Fight_Battle)self, side)
}

// games.strategy.triplea.delegate.battle.BattleState#getBattleSite
battle_state_get_battle_site :: proc(self: ^Battle_State) -> ^Territory {
	return (cast(^Must_Fight_Battle)self).battle_site
}

// games.strategy.triplea.delegate.battle.BattleState#getStatus
battle_state_get_status :: proc(self: ^Battle_State) -> ^Battle_State_Battle_Status {
	return must_fight_battle_get_status(cast(^Must_Fight_Battle)self)
}

// games.strategy.triplea.delegate.battle.BattleState#getGameData
battle_state_get_game_data :: proc(self: ^Battle_State) -> ^Game_Data {
	return (cast(^Must_Fight_Battle)self).game_data
}

// games.strategy.triplea.delegate.battle.BattleState#getTerritoryEffects
battle_state_get_territory_effects :: proc(self: ^Battle_State) -> [dynamic]^Territory_Effect {
	return (cast(^Must_Fight_Battle)self).territory_effects
}


// games.strategy.triplea.delegate.battle.BattleState#getBattleId
battle_state_get_battle_id :: proc(self: ^Battle_State) -> Uuid {
	return (cast(^Must_Fight_Battle)self).battle_id
}

// games.strategy.triplea.delegate.battle.BattleState#getDependentUnits(Collection<Unit>)
//   Forwarder to AbstractBattle (the only concrete inheritor in the
//   AI snapshot slice is MustFightBattle, which itself extends
//   AbstractBattle and inherits the impl unchanged).
battle_state_get_dependent_units :: proc(self: ^Battle_State, units: [dynamic]^Unit) -> [dynamic]^Unit {
	return abstract_battle_get_dependent_units(cast(^Abstract_Battle)self, units)
}

// games.strategy.triplea.delegate.battle.BattleState#removeNonCombatants(Side)
//   Forwarder to MustFightBattle's implementation; returns the units
//   that were filtered out (matches the Java return-type Collection<Unit>).
battle_state_remove_non_combatants :: proc(self: ^Battle_State, side: Battle_State_Side) -> [dynamic]^Unit {
	return must_fight_battle_remove_non_combatants(cast(^Must_Fight_Battle)self, side)
}

// games.strategy.triplea.delegate.battle.BattleState#getBombardingUnits()
//   Forwarder; bombarding_units lives on Abstract_Battle.
battle_state_get_bombarding_units :: proc(self: ^Battle_State) -> [dynamic]^Unit {
	return (cast(^Abstract_Battle)self).bombarding_units
}

// games.strategy.triplea.delegate.battle.BattleState#getStepStrings()
//   Forwarder to MustFightBattle's step_strings field.
battle_state_get_step_strings :: proc(self: ^Battle_State) -> [dynamic]string {
	return (cast(^Must_Fight_Battle)self).step_strings
}

// games.strategy.triplea.delegate.battle.BattleState#findStepNameForFiringUnits(Collection<Unit>)
//   Forwarder; impl on MustFightBattle scans step_firing_units.
//   Java returns Optional<String>; Odin returns ("", false) for absent.
battle_state_find_step_name_for_firing_units :: proc(
	self: ^Battle_State,
	firing_units: [dynamic]^Unit,
) -> (string, bool) {
	mfb := cast(^Must_Fight_Battle)self
	for name, units in mfb.step_firing_units {
		all_in := true
		for f in firing_units {
			found := false
			for u in units {
				if u == f {
					found = true
					break
				}
			}
			if !found {
				all_in = false
				break
			}
		}
		if all_in {
			return name, true
		}
	}
	return "", false
}

// games.strategy.triplea.delegate.battle.BattleState#getTransportDependents(Collection<Unit>)
//   Forwarder to AbstractBattle implementation.
battle_state_get_transport_dependents :: proc(
	self: ^Battle_State,
	transports: [dynamic]^Unit,
) -> [dynamic]^Unit {
	return abstract_battle_get_transport_dependents(cast(^Abstract_Battle)self, transports)
}

// games.strategy.triplea.delegate.battle.BattleState#getDependentBattles()
//   Forwarder to MustFightBattle implementation.
battle_state_get_dependent_battles :: proc(self: ^Battle_State) -> map[^I_Battle]struct{} {
	return must_fight_battle_get_dependent_battles(cast(^Must_Fight_Battle)self)
}

// games.strategy.triplea.delegate.battle.BattleState#retreatUnits(Side, Collection<Unit>)
//   Forwarder.
battle_state_retreat_units :: proc(
	self: ^Battle_State,
	side: Battle_State_Side,
	units: [dynamic]^Unit,
) {
	must_fight_battle_retreat_units(cast(^Must_Fight_Battle)self, side, units)
}

// games.strategy.triplea.delegate.battle.BattleState#markCasualties(Collection<Unit>, Side)
//   Forwarder.
battle_state_mark_casualties :: proc(
	self: ^Battle_State,
	casualties: [dynamic]^Unit,
	side: Battle_State_Side,
) {
	must_fight_battle_mark_casualties(cast(^Must_Fight_Battle)self, casualties, side)
}
