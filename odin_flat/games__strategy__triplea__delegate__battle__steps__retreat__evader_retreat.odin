package game

Evader_Retreat :: struct {}

Evader_Retreat_Parameters :: struct {
	battle_state:   ^Battle_State,
	battle_actions: ^Battle_Actions,
	side:           Battle_State_Side,
	bridge:         ^I_Delegate_Bridge,
	units:          [dynamic]^Unit,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.steps.retreat.EvaderRetreat

