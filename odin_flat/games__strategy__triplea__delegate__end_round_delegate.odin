package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.EndRoundDelegate

End_Round_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	game_over:    bool,
	winners:      [dynamic]^Game_Player,
}

// games.strategy.triplea.delegate.EndRoundDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
end_round_delegate_get_remote_type :: proc(self: ^End_Round_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.EndRoundDelegate#getProduction(GamePlayer)
// Java body:
//   return StreamSupport.stream(getData().getMap().spliterator(), false)
//       .filter(Matches.isTerritoryOwnedBy(gamePlayer))
//       .mapToInt(TerritoryAttachment::getProduction)
//       .sum();
// `TerritoryAttachment::getProduction` resolves to the static overload
// `TerritoryAttachment.getProduction(Territory)` (the only single-arg
// match for a Territory stream element), which returns 0 when the
// territory has no attachment. We inline that null-safe lookup here.
end_round_delegate_get_production :: proc(
	self: ^End_Round_Delegate,
	game_player: ^Game_Player,
) -> i32 {
	pred, pred_ctx := matches_is_territory_owned_by(game_player)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	territories := game_map_get_territories(game_data_get_map(data))
	sum: i32 = 0
	for t in territories {
		if !pred(pred_ctx, t) {
			continue
		}
		if t == nil || t.territory_attachment == nil {
			continue
		}
		sum += territory_attachment_get_production(t.territory_attachment)
	}
	return sum
}

// games.strategy.triplea.delegate.EndRoundDelegate#loadState(Serializable)
// Java body:
//   final EndRoundExtendedDelegateState s = (EndRoundExtendedDelegateState) state;
//   super.loadState(s.superState);
//   gameOver = s.gameOver;
//   winners = s.winners;
end_round_delegate_load_state :: proc(self: ^End_Round_Delegate, state: rawptr) {
	s := cast(^End_Round_Extended_Delegate_State)state
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)s.super_state,
	)
	self.game_over = s.game_over
	self.winners = s.winners
}

// games.strategy.triplea.delegate.EndRoundDelegate#<init>()
// Java body is empty (`public EndRoundDelegate() {}`); the implicit
// constructor only runs the field initializers `gameOver = false`
// and `winners = new ArrayList<>()`. The parent
// `BaseTripleADelegate` has no field initializers worth replaying
// here (its own state is set up by the engine after construction),
// matching the convention used by `abstract_end_turn_delegate_new`.
end_round_delegate_new :: proc() -> ^End_Round_Delegate {
	self := new(End_Round_Delegate)
	self.game_over = false
	self.winners = make([dynamic]^Game_Player)
	return self
}

// games.strategy.triplea.delegate.EndRoundDelegate#saveState()
// Java body:
//   final EndRoundExtendedDelegateState state = new EndRoundExtendedDelegateState();
//   state.superState = super.saveState();
//   state.gameOver = gameOver;
//   state.winners = winners;
//   return state;
// Java returns `Serializable`; the Odin port returns the concrete
// state pointer (callers downcast in `loadState`, mirroring the
// pattern used elsewhere in this package, e.g.
// `abstract_end_turn_delegate_save_state`).
end_round_delegate_save_state :: proc(
	self: ^End_Round_Delegate,
) -> ^End_Round_Extended_Delegate_State {
	state := end_round_extended_delegate_state_new()
	state.super_state = base_triple_a_delegate_save_state(&self.base_triple_a_delegate)
	state.game_over = self.game_over
	state.winners = self.winners
	return state
}

