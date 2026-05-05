package game

Technology_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	tech_cost:          i32,
	techs:              map[^Game_Player][dynamic]^Tech_Advance,
	tech_category:      ^Technology_Frontier,
	need_to_initialize: bool,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TechnologyDelegate

// games.strategy.triplea.delegate.TechnologyDelegate#<init>()
// Java has an explicit empty no-arg constructor; field initializers set
// `needToInitialize = true`. Other fields default to their zero values
// (techCost = 0, techs = null, techCategory = null) and the embedded
// BaseTripleADelegate / AbstractDelegate state is zero-initialized.
technology_delegate_new :: proc() -> ^Technology_Delegate {
	self := new(Technology_Delegate)
	self.need_to_initialize = true
	return self
}

// games.strategy.triplea.delegate.TechnologyDelegate#saveState()
// Builds a TechnologyExtendedDelegateState whose superState is the
// BaseTripleADelegate state, then copies needToInitialize and the techs
// map. Java returns `Serializable`; the Odin port returns the concrete
// state pointer (callers downcast in `loadState`).
technology_delegate_save_state :: proc(
	self: ^Technology_Delegate,
) -> ^Technology_Extended_Delegate_State {
	state := technology_extended_delegate_state_new()
	state.super_state = base_triple_a_delegate_save_state(&self.base_triple_a_delegate)
	state.need_to_initialize = self.need_to_initialize
	state.techs = self.techs
	return state
}

// games.strategy.triplea.delegate.TechnologyDelegate#initialize(String, String)
// Calls super.initialize(name, displayName), then allocates the per-player
// tech-advance map and resets techCost to -1 (matching Java).
technology_delegate_initialize :: proc(self: ^Technology_Delegate, name: string, display_name: string) {
	abstract_delegate_initialize(&self.abstract_delegate, name, display_name)
	self.techs = make(map[^Game_Player][dynamic]^Tech_Advance)
	self.tech_cost = -1
}

// games.strategy.triplea.delegate.TechnologyDelegate#getAdvances(GamePlayer)
// Returns the advances list mapped to the given player, or nil when the
// techs map has not been initialized or has no entry for the player.
// Java: `techs == null ? null : techs.get(player)`.
technology_delegate_get_advances :: proc(self: ^Technology_Delegate, player: ^Game_Player) -> [dynamic]^Tech_Advance {
	if self.techs == nil {
		return nil
	}
	return self.techs[player]
}

// games.strategy.triplea.delegate.TechnologyDelegate#clearAdvances(GamePlayer)
// Removes any advances entry for the given player when the techs map is
// initialized. No-op otherwise.
technology_delegate_clear_advances :: proc(self: ^Technology_Delegate, player: ^Game_Player) {
	if self.techs != nil {
		delete_key(&self.techs, player)
	}
}

// games.strategy.triplea.delegate.TechnologyDelegate#getRemoteType()
// Java returns `Class<ITechDelegate>`; Odin returns the corresponding
// `typeid`, mirroring how the other delegates expose their remote types.
technology_delegate_get_remote_type :: proc(self: ^Technology_Delegate) -> typeid {
	return I_Tech_Delegate
}

// games.strategy.triplea.delegate.TechnologyDelegate#loadState(java.io.Serializable)
// Java casts the Serializable to TechnologyExtendedDelegateState, chains
// super.loadState with its superState, then restores needToInitialize and
// the techs map.
technology_delegate_load_state :: proc(
	self: ^Technology_Delegate,
	state: ^Technology_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
	self.techs = state.techs
}

// games.strategy.triplea.delegate.TechnologyDelegate#delegateCurrentlyRequiresUserInput()
// Mirrors the Java guard chain: tech development must be enabled, the
// player must hold enough capitals to produce, then either the WW2v3 tech
// token branch (if any tokens are held) or the PUs-vs-techCost check —
// possibly summing in PUs from helpPayTechCost players when the player
// alone cannot afford a roll. Constants.TECH_TOKENS / Constants.PUS
// resolve to the literals "techTokens" / "PUs" (see battle_tracker.odin
// and resource_collection.odin for the same convention).
technology_delegate_delegate_currently_requires_user_input :: proc(
	self: ^Technology_Delegate,
) -> bool {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if !properties_get_tech_development(game_data_get_properties(data)) {
		return false
	}
	if !territory_attachment_do_we_have_enough_capitals_to_produce(
		self.player,
		game_data_get_map(data),
	) {
		return false
	}
	if properties_get_ww2_v3_tech_model(game_data_get_properties(data)) {
		tech_tokens := resource_list_get_resource_optional(
			game_data_get_resource_list(data),
			"techTokens",
		)
		if tech_tokens != nil &&
		   resource_collection_get_quantity(game_player_get_resources(self.player), tech_tokens) >
			   0 {
			return true
		}
	}
	tech_cost := tech_tracker_get_tech_cost(self.player)
	money := resource_collection_get_quantity_by_name(
		game_player_get_resources(self.player),
		"PUs",
	)
	if money < tech_cost {
		pa := player_attachment_get(self.player)
		if pa == nil {
			return false
		}
		help_pay := player_attachment_get_help_pay_tech_cost(pa)
		if len(help_pay) == 0 {
			return false
		}
		for p in help_pay {
			money += resource_collection_get_quantity_by_name(
				game_player_get_resources(p),
				"PUs",
			)
		}
		return money >= tech_cost
	}
	return true
}

// games.strategy.triplea.delegate.TechnologyDelegate#getAvailableTechs(GamePlayer, TechnologyFrontier)
// Java: CollectionUtils.difference(allAdvances, currentAdvances) where
// allAdvances = TechAdvance.getTechAdvances(frontier, player) and
// currentAdvances = TechTracker.getCurrentTechAdvances(player, frontier).
// Inlined as a typed difference (collection_utils_difference is rawptr-only)
// to keep ^Tech_Advance throughout. The result is a fresh dynamic array; the
// two source lists are owned and freed here.
technology_delegate_get_available_techs :: proc(
	player: ^Game_Player,
	technology_frontier: ^Technology_Frontier,
) -> [dynamic]^Tech_Advance {
	current_advances := tech_tracker_get_current_tech_advances(player, technology_frontier)
	defer delete(current_advances)
	all_advances := tech_advance_get_tech_advances(technology_frontier, player)
	defer delete(all_advances)
	result := make([dynamic]^Tech_Advance, 0)
	for ta in all_advances {
		in_current := false
		for c in current_advances {
			if c == ta {
				in_current = true
				break
			}
		}
		if in_current {
			continue
		}
		already := false
		for r in result {
			if r == ta {
				already = true
				break
			}
		}
		if !already {
			append(&result, ta)
		}
	}
	return result
}

// games.strategy.triplea.delegate.TechnologyDelegate#end()
// Java body:
//   super.end();
//   needToInitialize = true;
technology_delegate_end :: proc(self: ^Technology_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	self.need_to_initialize = true
}

// AND-chained Predicate<TriggerAttachment> used by start():
//   availableUses
//     .and(whenOrDefaultMatch(null, null))
//     .and(techAvailableMatch())
// `availableUses` and `techAvailableMatch` are non-capturing bare procs;
// `whenOrDefaultMatch` carries a captured (proc, rawptr) pair stashed in
// the per-call ctx. The AND chain is inlined to honor Java's short-circuit
// evaluation order.
Technology_Delegate_Ctx_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

technology_delegate_lambda_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Technology_Delegate_Ctx_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	return trigger_attachment_lambda_tech_available_match(t)
}

// games.strategy.triplea.delegate.TechnologyDelegate#start()
// Java body:
//   super.start();
//   if (!needToInitialize) return;
//   if (Properties.getTriggers(getData().getProperties())) {
//     final Predicate<TriggerAttachment> technologyDelegateTriggerMatch =
//         AbstractTriggerAttachment.availableUses
//             .and(AbstractTriggerAttachment.whenOrDefaultMatch(null, null))
//             .and(TriggerAttachment.techAvailableMatch());
//     final Set<TriggerAttachment> toFirePossible =
//         TriggerAttachment.collectForAllTriggersMatching(
//             Set.of(player), technologyDelegateTriggerMatch);
//     if (!toFirePossible.isEmpty()) {
//       final Map<ICondition, Boolean> testedConditions =
//           TriggerAttachment.collectTestsForAllTriggers(toFirePossible, bridge);
//       final List<TriggerAttachment> toFireTestedAndSatisfied =
//           CollectionUtils.getMatches(toFirePossible,
//               AbstractTriggerAttachment.isSatisfiedMatch(testedConditions));
//       TriggerAttachment.triggerAvailableTechChange(
//           new HashSet<>(toFireTestedAndSatisfied), bridge,
//           new FireTriggerParams(null, null, true, true, true, true));
//     }
//   }
//   needToInitialize = false;
technology_delegate_start :: proc(self: ^Technology_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	if !self.need_to_initialize {
		return
	}
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if properties_get_triggers(game_data_get_properties(data)) {
		when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
		match_ctx := new(Technology_Delegate_Ctx_trigger_match)
		match_ctx.when_pred = when_pred
		match_ctx.when_ctx = when_ctx

		players_set := make(map[^Game_Player]struct {})
		defer delete(players_set)
		players_set[self.player] = {}

		to_fire_possible := trigger_attachment_collect_for_all_triggers_matching(
			players_set,
			technology_delegate_lambda_trigger_match,
			rawptr(match_ctx),
		)
		if len(to_fire_possible) > 0 {
			tested_conditions := trigger_attachment_collect_tests_for_all_triggers_simple(
				to_fire_possible,
				self.bridge,
			)
			satisfied_pred, satisfied_ctx := abstract_trigger_attachment_is_satisfied_match(
				tested_conditions,
			)
			to_fire_tested_and_satisfied := make(map[^Trigger_Attachment]struct {})
			defer delete(to_fire_tested_and_satisfied)
			for t in to_fire_possible {
				if satisfied_pred(satisfied_ctx, t) {
					to_fire_tested_and_satisfied[t] = {}
				}
			}
			params := fire_trigger_params_new("", "", true, true, true, true)
			trigger_attachment_trigger_available_tech_change(
				to_fire_tested_and_satisfied,
				self.bridge,
				params,
			)
		}
	}
	self.need_to_initialize = false
}

