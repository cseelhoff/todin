package game

Base_Triple_A_Delegate :: struct {
	using abstract_delegate: Abstract_Delegate,
	start_base_steps_finished: bool,
	end_base_steps_finished:   bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.BaseTripleADelegate

// games.strategy.triplea.delegate.BaseTripleADelegate#<init>()
// Java's implicit no-arg constructor. All fields default to their zero
// value (false for the two finished flags); the embedded
// Abstract_Delegate is also zero-initialized.
base_triple_a_delegate_new :: proc() -> ^Base_Triple_A_Delegate {
	self := new(Base_Triple_A_Delegate)
	return self
}

// games.strategy.triplea.delegate.BaseTripleADelegate#saveState()
// Builds a Base_Delegate_State capturing the start/end "finished" flags.
base_triple_a_delegate_save_state :: proc(self: ^Base_Triple_A_Delegate) -> ^Base_Delegate_State {
	state := base_delegate_state_new()
	state.start_base_steps_finished = self.start_base_steps_finished
	state.end_base_steps_finished = self.end_base_steps_finished
	return state
}

base_triple_a_delegate_load_state :: proc(self: ^Base_Triple_A_Delegate, state: ^Base_Delegate_State) {
	self.start_base_steps_finished = state.start_base_steps_finished
	self.end_base_steps_finished = state.end_base_steps_finished
}

// games.strategy.triplea.delegate.BaseTripleADelegate#triggerWhenTriggerAttachments(String)
//
// Java body:
//   GameState data = getData();
//   if (Properties.getTriggers(data.getProperties())) {
//       String stepName = data.getSequence().getStep().getName();
//       Predicate<TriggerAttachment> baseDelegateWhenTriggerMatch =
//           TriggerAttachment.availableUses.and(
//               TriggerAttachment.whenOrDefaultMatch(beforeOrAfter, stepName));
//       TriggerAttachment.collectAndFireTriggers(
//           new HashSet<>(data.getPlayerList().getPlayers()),
//           baseDelegateWhenTriggerMatch,
//           bridge, beforeOrAfter, stepName);
//   }
//   PoliticsDelegate.chainAlliancesTogether(bridge);
//
// The AND-combined predicate follows the standard pair-with-ctx
// convention (see end_turn_delegate_lambda_trigger_match): the bare
// non-capturing `availableUses` (lambda_static_0) is short-circuited
// first, then the capturing whenOrDefaultMatch predicate is invoked
// through the carried (proc, rawptr) pair.
Base_Triple_A_Delegate_Ctx_trigger_when_trigger_attachments :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

base_triple_a_delegate_lambda_trigger_when_trigger_attachments :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Base_Triple_A_Delegate_Ctx_trigger_when_trigger_attachments)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	return ctx.when_pred(ctx.when_ctx, t)
}

base_triple_a_delegate_trigger_when_trigger_attachments :: proc(
	self: ^Base_Triple_A_Delegate,
	before_or_after: string,
) {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if properties_get_triggers(game_data_get_properties(data)) {
		step_name := game_step_get_name(game_sequence_get_step(game_data_get_sequence(data)))
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match(
			before_or_after,
			step_name,
		)
		match_ctx := new(Base_Triple_A_Delegate_Ctx_trigger_when_trigger_attachments)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx

		players_set := make(map[^Game_Player]struct {})
		defer delete(players_set)
		for p in player_list_get_players(game_data_get_player_list(data)) {
			players_set[p] = {}
		}

		trigger_attachment_collect_and_fire_triggers(
			players_set,
			base_triple_a_delegate_lambda_trigger_when_trigger_attachments,
			rawptr(match_ctx),
			self.bridge,
			before_or_after,
			step_name,
		)
	}
	politics_delegate_chain_alliances_together(self.bridge)
}

// games.strategy.triplea.delegate.BaseTripleADelegate#start()
// Java body:
//   super.start();
//   if (!startBaseStepsFinished) {
//     startBaseStepsFinished = true;
//     triggerWhenTriggerAttachments(TriggerAttachment.BEFORE);
//   }
base_triple_a_delegate_start :: proc(self: ^Base_Triple_A_Delegate) {
	abstract_delegate_start(&self.abstract_delegate)
	if !self.start_base_steps_finished {
		self.start_base_steps_finished = true
		base_triple_a_delegate_trigger_when_trigger_attachments(self, "before")
	}
}

// games.strategy.triplea.delegate.BaseTripleADelegate#end()
// Java body:
//   super.end();
//   if (!endBaseStepsFinished) {
//     endBaseStepsFinished = true;
//     triggerWhenTriggerAttachments(TriggerAttachment.AFTER);
//   }
//   startBaseStepsFinished = false;
//   endBaseStepsFinished = false;
base_triple_a_delegate_end :: proc(self: ^Base_Triple_A_Delegate) {
	abstract_delegate_end(&self.abstract_delegate)
	if !self.end_base_steps_finished {
		self.end_base_steps_finished = true
		base_triple_a_delegate_trigger_when_trigger_attachments(self, "after")
	}
	self.start_base_steps_finished = false
	self.end_base_steps_finished = false
}

