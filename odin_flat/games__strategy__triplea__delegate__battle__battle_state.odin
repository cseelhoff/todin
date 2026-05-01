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

