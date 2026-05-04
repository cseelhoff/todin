package game

// Java owner: games.strategy.triplea.delegate.InitializationDelegate

Initialization_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize: bool,
}

// games.strategy.triplea.delegate.InitializationDelegate#<init>()
// Java's implicit no-arg constructor. The only declared field
// `needToInitialize` has the Java initializer `= true`; embedded
// Base_Triple_A_Delegate is zero-initialized.
initialization_delegate_new :: proc() -> ^Initialization_Delegate {
	self := new(Initialization_Delegate)
	self.need_to_initialize = true
	return self
}

// games.strategy.triplea.delegate.InitializationDelegate#saveState()
// Builds an InitializationExtendedDelegateState. `superState` is the
// parent delegate's save_state (Base_Triple_A_Delegate has no
// override; this resolves to base_triple_a_delegate_save_state).
// `super_state` on the state struct is rawptr so a
// Base_Delegate_State pointer can be packed in.
initialization_delegate_save_state :: proc(self: ^Initialization_Delegate) -> ^Initialization_Extended_Delegate_State {
	state := initialization_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.need_to_initialize = self.need_to_initialize
	return state
}

// games.strategy.triplea.delegate.InitializationDelegate#getRemoteType()
// Java returns `null` (no remote interface). Odin mirrors that with the
// zero `typeid` value.
initialization_delegate_get_remote_type :: proc(self: ^Initialization_Delegate) -> typeid {
	return nil
}

// games.strategy.triplea.delegate.InitializationDelegate#loadState(java.io.Serializable)
// Restores delegate state from an InitializationExtendedDelegateState.
// Mirrors the Java cast-and-assign, then forwards `superState` to the
// parent delegate's loadState (BaseTripleADelegate has no override, so
// this resolves to AbstractDelegate's via Base_Triple_A_Delegate.load_state).
initialization_delegate_load_state :: proc(
	self: ^Initialization_Delegate,
	state: ^Initialization_Extended_Delegate_State,
) {
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)state.super_state,
	)
	self.need_to_initialize = state.need_to_initialize
}

// games.strategy.triplea.delegate.InitializationDelegate#initAiStartingBonusIncome(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. Iterates every player on the bridge's data and gives
// each their AI starting bonus income via BonusIncomeUtils.
initialization_delegate_init_ai_starting_bonus_income :: proc(bridge: ^I_Delegate_Bridge) {
	players := player_list_get_players(
		game_data_get_player_list(i_delegate_bridge_get_data(bridge)),
	)
	for player in players {
		bonus_income_utils_add_bonus_income(
			resource_collection_get_resources_copy(game_player_get_resources(player)),
			bridge,
			player,
		)
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initDestroyerArtillery(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. If the game is not WW2v2 and the
// "Use Destroyers and Artillery" property is on, ensure the artillery and
// destroyer production rules (plus their industrial-technology variants)
// are present in the corresponding production frontiers, and emit a
// history event if any rule was added.
initialization_delegate_init_destroyer_artillery :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	add_artillery_and_destroyers := properties_get_use_destroyers_and_artillery(
		game_data_get_properties(data),
	)
	if !properties_get_ww2_v2(game_data_get_properties(data)) && add_artillery_and_destroyers {
		change := composite_change_new()
		artillery := production_rule_list_get_production_rule(
			game_data_get_production_rule_list(data),
			"buyArtillery",
		)
		destroyer := production_rule_list_get_production_rule(
			game_data_get_production_rule_list(data),
			"buyDestroyer",
		)
		frontier := production_frontier_list_get_production_frontier(
			game_data_get_production_frontier_list(data),
			"production",
		)
		if artillery != nil {
			frontier_rules := production_frontier_get_rules(frontier)
			contains_artillery := false
			for r in frontier_rules {
				if r == artillery {
					contains_artillery = true
					break
				}
			}
			if !contains_artillery {
				composite_change_add(change, change_factory_add_production_rule(artillery, frontier))
			}
		}
		if destroyer != nil {
			frontier_rules := production_frontier_get_rules(frontier)
			contains_destroyer := false
			for r in frontier_rules {
				if r == destroyer {
					contains_destroyer = true
					break
				}
			}
			if !contains_destroyer {
				composite_change_add(change, change_factory_add_production_rule(destroyer, frontier))
			}
		}
		artillery_industrial_technology := production_rule_list_get_production_rule(
			game_data_get_production_rule_list(data),
			"buyArtilleryIndustrialTechnology",
		)
		destroyer_industrial_technology := production_rule_list_get_production_rule(
			game_data_get_production_rule_list(data),
			"buyDestroyerIndustrialTechnology",
		)
		frontier_industrial_technology := production_frontier_list_get_production_frontier(
			game_data_get_production_frontier_list(data),
			"productionIndustrialTechnology",
		)
		if artillery_industrial_technology != nil {
			it_rules := production_frontier_get_rules(frontier_industrial_technology)
			contains_it_artillery := false
			for r in it_rules {
				if r == artillery_industrial_technology {
					contains_it_artillery = true
					break
				}
			}
			if !contains_it_artillery {
				composite_change_add(
					change,
					change_factory_add_production_rule(
						artillery_industrial_technology,
						frontier_industrial_technology,
					),
				)
			}
		}
		if destroyer_industrial_technology != nil {
			it_rules := production_frontier_get_rules(frontier_industrial_technology)
			contains_it_destroyer := false
			for r in it_rules {
				if r == destroyer_industrial_technology {
					contains_it_destroyer = true
					break
				}
			}
			if !contains_it_destroyer {
				composite_change_add(
					change,
					change_factory_add_production_rule(
						destroyer_industrial_technology,
						frontier_industrial_technology,
					),
				)
			}
		}
		if !composite_change_is_empty(change) {
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				"Adding destroyers and artillery production rules",
			)
			i_delegate_bridge_add_change(bridge, &change.change)
		}
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initShipyards(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. If the "Use Shipyards" property is on, walk the regular
// production frontier and copy every non-sea unit's production rule into
// the shipyards frontier, then emit a history event. Mirrors the Java
// loop including the always-emitted history event and always-applied change.
initialization_delegate_init_shipyards :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	use_shipyards := properties_get_use_shipyards(game_data_get_properties(data))
	if use_shipyards {
		change := composite_change_new()
		frontier_shipyards := production_frontier_list_get_production_frontier(
			game_data_get_production_frontier_list(data),
			"productionShipyards",
		)
		// Find the productionRules; if the unit is NOT a sea unit, add it
		// to the ShipYards prod rule.
		frontier_non_shipyards := production_frontier_list_get_production_frontier(
			game_data_get_production_frontier_list(data),
			"production",
		)
		rules := production_frontier_get_rules(frontier_non_shipyards)
		for rule in rules {
			// Java: rule.getAnyResultKey() returns any NamedAttachable key
			// from the rule's results map; "instanceof UnitType" filters
			// out Resource results. The equivalent Odin check is to look
			// up the name in the unit-type list and skip if not found.
			named: ^Named_Attachable = nil
			for k, _ in rule.results.map_values {
				named = cast(^Named_Attachable)k
				break
			}
			if named == nil {
				continue
			}
			unit_type := unit_type_list_get_unit_type(
				game_data_get_unit_type_list(data),
				default_named_get_name(&named.default_named),
			)
			if unit_type == nil {
				continue
			}
			ua := unit_type_get_unit_attachment(unit_type)
			is_sea := ua != nil && unit_attachment_is_sea(ua)
			if !is_sea {
				prod_rule := production_rule_list_get_production_rule(
					game_data_get_production_rule_list(data),
					default_named_get_name(&rule.default_named),
				)
				composite_change_add(
					change,
					change_factory_add_production_rule(prod_rule, frontier_shipyards),
				)
			}
		}
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			"Adding shipyard production rules - land/air units",
		)
		i_delegate_bridge_add_change(bridge, &change.change)
	}
}

