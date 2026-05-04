package game

End_Turn_Delegate :: struct {
	using abstract_end_turn_delegate: Abstract_End_Turn_Delegate,
}

end_turn_delegate_lambda_static_0 :: proc(ra: ^Rules_Attachment) -> bool {
	return ra.uses != 0
}

// games.strategy.triplea.delegate.EndTurnDelegate#<init>()
// Java has no explicit constructor; the implicit one chains to
// AbstractEndTurnDelegate's no-arg constructor which sets the field
// initializers (needToInitialize = true, hasPostedTurnSummary = false).
end_turn_delegate_new :: proc() -> ^End_Turn_Delegate {
	self := new(End_Turn_Delegate)
	parent := abstract_end_turn_delegate_new()
	self.abstract_end_turn_delegate = parent^
	free(parent)
	return self
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#getRandomTerritory(
//     GameState data, Collection<Territory> territories, IDelegateBridge bridge)
//
// Java:
//   if (territories.size() == 1) return CollectionUtils.getAny(territories);
//   if (PbemMessagePoster.gameDataHasPlayByEmailOrForumMessengers(data))
//     Interruptibles.sleep(100);
//   final List<Territory> list = new ArrayList<>(territories);
//   final int random = bridge.getRandom(
//       list.size(), null, DiceType.ENGINE,
//       "Random territory selection for creating units");
//   return list.get(random);
// ---------------------------------------------------------------------------
end_turn_delegate_get_random_territory :: proc(
	data: ^Game_State,
	territories: [dynamic]^Territory,
	bridge: ^I_Delegate_Bridge,
) -> ^Territory {
	if len(territories) == 1 {
		return territories[0]
	}
	// Crypted random source can stall when many rolls fire back-to-back during
	// a PBEM/forum game; the engine inserts a small pause to space them out.
	if pbem_message_poster_game_data_has_play_by_email_or_forum_messengers(data) {
		interruptibles_sleep(100)
	}
	list: [dynamic]^Territory
	for t in territories {
		append(&list, t)
	}
	random := i_delegate_bridge_get_random(
		bridge,
		i32(len(list)),
		1,
		nil,
		I_Random_Stats_Dice_Type.ENGINE,
		"Random territory selection for creating units",
	)
	// ZERO BASED.
	return list[random[0]]
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#testNationalObjectivesAndTriggers(
//     GamePlayer player, GameState data, IDelegateBridge bridge,
//     Set<TriggerAttachment> triggers, List<RulesAttachment> objectives)
//
// Mutates `triggers` and `objectives` (Java passes them in empty so
// callers can inspect the collected sets after the call). Returns the
// Map<ICondition, Boolean> of tested conditions, or an empty map when
// nothing needs testing.
// ---------------------------------------------------------------------------
End_Turn_Delegate_Ctx_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

// Body of the AND-chained Predicate<TriggerAttachment>:
//   availableUses
//     .and(whenOrDefaultMatch(null, null))
//     .and(resourceMatch())
end_turn_delegate_lambda_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^End_Turn_Delegate_Ctx_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	return trigger_attachment_lambda_resource_match(t)
}

end_turn_delegate_test_national_objectives_and_triggers :: proc(
	player: ^Game_Player,
	data: ^Game_State,
	bridge: ^I_Delegate_Bridge,
	triggers: ^map[^Trigger_Attachment]struct {},
	objectives: ^[dynamic]^Rules_Attachment,
) -> map[^I_Condition]bool {
	all_conditions_needed := make(map[^I_Condition]struct {})
	use_triggers := properties_get_triggers(game_state_get_properties(data))
	if use_triggers {
		// Build the per-call AND ctx whose `when_pred` is whenOrDefaultMatch(null, null).
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
		match_ctx := new(End_Turn_Delegate_Ctx_trigger_match)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx
		players_set := make(map[^Game_Player]struct {})
		players_set[player] = {}
		new_triggers := trigger_attachment_collect_for_all_triggers_matching(
			players_set,
			end_turn_delegate_lambda_trigger_match,
			rawptr(match_ctx),
		)
		delete(players_set)
		for t in new_triggers {
			triggers[t] = {}
		}
		// allConditionsNeeded.addAll(getAllConditionsRecursive(new HashSet<>(triggers), null))
		trig_conds := make(map[^I_Condition]struct {})
		for t in triggers {
			trig_conds[cast(^I_Condition)rawptr(t)] = {}
		}
		recursed := abstract_conditions_attachment_get_all_conditions_recursive(
			trig_conds,
			nil,
		)
		for c in recursed {
			all_conditions_needed[c] = {}
		}
		delete(trig_conds)
	}

	// objectives.addAll(getMatches(getNationalObjectives(player), availableUses))
	for ra in rules_attachment_get_national_objectives(player) {
		if end_turn_delegate_lambda_static_0(ra) {
			append(objectives, ra)
		}
	}

	// allConditionsNeeded.addAll(getAllConditionsRecursive(new HashSet<>(objectives), null))
	obj_conds := make(map[^I_Condition]struct {})
	for ra in objectives {
		obj_conds[cast(^I_Condition)rawptr(ra)] = {}
	}
	recursed_obj := abstract_conditions_attachment_get_all_conditions_recursive(
		obj_conds,
		nil,
	)
	for c in recursed_obj {
		all_conditions_needed[c] = {}
	}
	delete(obj_conds)

	if len(all_conditions_needed) == 0 {
		return make(map[^I_Condition]bool)
	}
	return abstract_conditions_attachment_test_all_conditions_recursive(
		all_conditions_needed,
		nil,
		bridge,
	)
}
