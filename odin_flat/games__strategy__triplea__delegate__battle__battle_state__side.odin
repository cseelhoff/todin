package game

Battle_State_Side :: enum {
	OFFENSE,
	DEFENSE,
}

// Java: Side(final IBattle.WhoWon whoWon) { this.whoWon = whoWon; }
// Odin port: the per-variant whoWon mapping is encoded as the side-table
// switch inside battle_state_side_get_who_won. Constructing a Side value
// is therefore just selecting the enum variant.
battle_state_side_new :: proc(who_won: I_Battle_Who_Won) -> Battle_State_Side {
	switch who_won {
	case .ATTACKER:
		return .OFFENSE
	case .DEFENDER:
		return .DEFENSE
	case .NOT_FINISHED, .DRAW:
		return .OFFENSE
	}
	return .OFFENSE
}

// Java: public Side getOpposite() { return this == OFFENSE ? DEFENSE : OFFENSE; }
battle_state_side_get_opposite :: proc(self: Battle_State_Side) -> Battle_State_Side {
	if self == .OFFENSE {
		return .DEFENSE
	}
	return .OFFENSE
}

// Java: @Getter on `private final IBattle.WhoWon whoWon` with
//   OFFENSE(IBattle.WhoWon.ATTACKER), DEFENSE(IBattle.WhoWon.DEFENDER).
battle_state_side_get_who_won :: proc(self: Battle_State_Side) -> I_Battle_Who_Won {
	switch self {
	case .OFFENSE:
		return .ATTACKER
	case .DEFENSE:
		return .DEFENDER
	}
	return .NOT_FINISHED
}
// One file per Java class. Replace this header when the
// class's structs and procs are fully ported.
// Java owners covered by this file:
//   - games.strategy.triplea.delegate.battle.BattleState$Side

