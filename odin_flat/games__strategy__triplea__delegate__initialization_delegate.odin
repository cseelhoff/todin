package game

import "core:fmt"

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

// games.strategy.triplea.delegate.InitializationDelegate#resetUnitState()
// Instance method. The Java sibling helper initTransportedLandUnits has
// side effects on unit state; this resets those by applying
// MoveDelegate.getResetUnitStateChange. Emits a history event and queues
// the change only when the produced change is non-empty.
initialization_delegate_reset_unit_state :: proc(self: ^Initialization_Delegate) {
	change := move_delegate_get_reset_unit_state_change(
		abstract_delegate_get_data(&self.abstract_delegate),
	)
	if !change_is_empty(change) {
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(self.bridge),
			"Cleaning up unit state.",
		)
		i_delegate_bridge_add_change(self.bridge, change)
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initSkipUnusedBids(games.strategy.engine.data.GameState)
// Static helper. Walks every step in the game's sequence and zeroes the
// max-run-count of bid steps whose owning player has no bid available,
// avoiding the per-VM UI churn Java's comment calls out.
//
// Java's `step.getDelegate() instanceof BidPlaceDelegate
// || step.getDelegate() instanceof BidPurchaseDelegate` is rendered using
// the established suffix-matchers on the step's name (see
// game_step_is_bid_place_step_name / game_step_is_bid_step_name); the
// codebase consistently identifies bid delegates by step-name suffix
// rather than by runtime type.
initialization_delegate_init_skip_unused_bids :: proc(data: ^Game_State) {
	gd := cast(^Game_Data)data
	for step in game_data_get_sequence(gd).steps {
		name := game_step_get_name(step)
		if (game_step_is_bid_place_step_name(name) || game_step_is_bid_step_name(name)) &&
			!bid_purchase_delegate_does_player_have_bid(data, game_step_get_player_id(step)) {
			game_step_set_max_run_count(step, 0)
		}
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#lambda$initAiStartingBonusIncome$0(IDelegateBridge, GamePlayer)
// Synthetic lambda backing the per-player forEach inside
// initAiStartingBonusIncome:
//   player -> BonusIncomeUtils.addBonusIncome(
//                player.getResources().getResourcesCopy(), bridge, player)
// `bridge` is the captured outer parameter; `player` is the iteration
// element. The Java return type is void, so the String result of
// addBonusIncome is discarded.
initialization_delegate_lambda_init_ai_starting_bonus_income_0 :: proc(
	bridge: ^I_Delegate_Bridge,
	player: ^Game_Player,
) {
	bonus_income_utils_add_bonus_income(
		resource_collection_get_resources_copy(game_player_get_resources(player)),
		bridge,
		player,
	)
}

// games.strategy.triplea.delegate.InitializationDelegate#initDeleteAssetsOfDisabledPlayers(IDelegateBridge)
// Static helper. When the "delete disabled players' assets" property is
// on, for every disabled non-null player: zero out every resource they
// own, remove every unit they hold, and remove every unit they own from
// every territory. Emit one history event per affected player and apply
// the composite change via the bridge.
initialization_delegate_init_delete_assets_of_disabled_players :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	if !properties_get_disabled_players_assets_deleted(game_data_get_properties(data)) {
		return
	}
	for player in player_list_get_players(game_data_get_player_list(data)) {
		if game_player_is_null(player) || !game_player_get_is_disabled(player) {
			continue
		}
		change := composite_change_new()
		// Zero every resource the player currently owns.
		resources_copy := resource_collection_get_resources_copy(game_player_get_resources(player))
		for r, _ in resources_copy {
			deleted := resource_collection_get_quantity(game_player_get_resources(player), r)
			if deleted != 0 {
				composite_change_add(
					change,
					change_factory_change_resources_change(player, r, -deleted),
				)
			}
		}
		delete(resources_copy)
		// Remove every unit the player is the holder of.
		held_units := unit_holder_get_units(cast(^Unit_Holder)player)
		if len(held_units) > 0 {
			composite_change_add(
				change,
				change_factory_remove_units(cast(^Unit_Holder)player, held_units),
			)
		}
		// For every territory, remove the units owned by this player.
		owned_pred, owned_ctx := matches_unit_is_owned_by(player)
		for t in game_map_get_territories(game_data_get_map(data)) {
			all_units := unit_holder_get_units(cast(^Unit_Holder)t)
			defer delete(all_units)
			terr_units := make([dynamic]^Unit, 0, len(all_units))
			for u in all_units {
				if owned_pred(owned_ctx, u) {
					append(&terr_units, u)
				}
			}
			if len(terr_units) > 0 {
				composite_change_add(
					change,
					change_factory_remove_units(cast(^Unit_Holder)t, terr_units),
				)
			}
		}
		if !composite_change_is_empty(change) {
			msg := fmt.aprintf(
				"Remove all resources and units from: %s",
				default_named_get_name(&player.named_attachable.default_named),
			)
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				msg,
			)
			i_delegate_bridge_add_change(bridge, &change.change)
		}
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initTransportedLandUnits(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. Walks every water territory and, for each land unit
// present, finds the first sea transport with enough free capacity and
// queues a load-transport change. Java's IllegalStateException becomes
// `panic` here; the catch around loadTransportChange (which only logged
// in Java) is dropped since Odin has no exceptions and the per-call
// success/failure branching of the original is preserved by Java setting
// `found = true` regardless of the catch.
initialization_delegate_init_transported_land_units :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	history_item_created := false
	land_pred, land_ctx := matches_unit_is_land()
	transport_pred, transport_ctx := matches_unit_is_sea_transport()
	for current in game_map_get_territories(game_data_get_map(data)) {
		if !territory_is_water(current) {
			continue
		}
		units := unit_holder_get_units(cast(^Unit_Holder)current)
		defer delete(units)
		if len(units) == 0 {
			continue
		}
		any_land := false
		for u in units {
			if land_pred(land_ctx, u) {
				any_land = true
				break
			}
		}
		if !any_land {
			continue
		}
		transports := make([dynamic]^Unit, 0)
		defer delete(transports)
		land := make([dynamic]^Unit, 0)
		defer delete(land)
		for u in units {
			if transport_pred(transport_ctx, u) {
				append(&transports, u)
			}
			if land_pred(land_ctx, u) {
				append(&land, u)
			}
		}
		for to_load in land {
			ua := unit_get_unit_attachment(to_load)
			cost := unit_attachment_get_transport_cost(ua)
			if cost == -1 {
				panic("Non transportable unit in sea")
			}
			found := false
			for transport in transports {
				capacity := transport_tracker_get_available_capacity(transport)
				if capacity >= cost {
					if !history_item_created {
						i_delegate_history_writer_start_event(
							i_delegate_bridge_get_history_writer(bridge),
							"Initializing Units in Transports",
						)
						history_item_created = true
					}
					i_delegate_bridge_add_change(
						bridge,
						transport_tracker_load_transport_change(transport, to_load),
					)
					found = true
					break
				}
			}
			if !found {
				panic(
					"Cannot load all land units in sea transports. Please make sure you have enough transports. You may need to re-order the xml's placement of transports and land units, as the engine will try to fill them in the order they are given.",
				)
			}
		}
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initTwoHitBattleship(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. Reconciles the user-selected "two hit battleships" game
// property with the battleship unit type's hit-point default by emitting a
// hitPoints attachment-property change (1 or 2) and a history event when
// the two disagree. No-op when no battleship unit type is defined.
initialization_delegate_init_two_hit_battleship :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	user_enabled := properties_get_two_hit_battleships(game_data_get_properties(data))
	battleship_unit_type := unit_type_list_get_unit_type(
		game_data_get_unit_type_list(data),
		"battleship",
	)
	if battleship_unit_type == nil {
		return
	}
	battleship_attachment := unit_type_get_unit_attachment(battleship_unit_type)
	default_enabled := unit_attachment_get_hit_points(battleship_attachment) > 1
	if user_enabled != default_enabled {
		msg := fmt.aprintf("TwoHitBattleships: %v", user_enabled)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			msg,
		)
		new_value := new(i32)
		new_value^ = user_enabled ? 2 : 1
		i_delegate_bridge_add_change(
			bridge,
			change_factory_attachment_property_change(
				cast(^I_Attachment)rawptr(battleship_attachment),
				rawptr(new_value),
				"hitPoints",
			),
		)
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initTech(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. For each player, fetch their currently-owned tech
// advances against the global technology frontier; if any, emit a
// history event and call advance.perform(player, bridge) for each.
initialization_delegate_init_tech :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	players := player_list_get_players(game_data_get_player_list(data))
	for player in players {
		advances := tech_tracker_get_current_tech_advances(
			player,
			game_data_get_technology_frontier(data),
		)
		defer delete(advances)
		if len(advances) > 0 {
			i_delegate_history_writer_start_event(
				i_delegate_bridge_get_history_writer(bridge),
				fmt.aprintf(
					"Initializing %s with tech advances",
					default_named_get_name(&player.named_attachable.default_named),
				),
			)
			for advance in advances {
				tech_advance_perform(advance, player, bridge)
			}
		}
	}
}

// games.strategy.triplea.delegate.InitializationDelegate#initOriginalOwner(games.strategy.engine.delegate.IDelegateBridge)
// Static helper. For each map territory with a non-null owner: if its
// TerritoryAttachment has no original owner yet, record the territory's
// current owner as the original owner; then record the current owner as
// the original owner of every infrastructure unit in the territory.
// Emits a single "Adding original owners" history event with the
// accumulated CompositeChange.
initialization_delegate_init_original_owner :: proc(bridge: ^I_Delegate_Bridge) {
	data := i_delegate_bridge_get_data(bridge)
	changes := composite_change_new()
	infra_pred, infra_ctx := matches_unit_is_infrastructure()
	for current in game_map_get_territories(game_data_get_map(data)) {
		if !game_player_is_null(territory_get_owner(current)) {
			territory_attachment := territory_attachment_get_or_throw(current)
			if territory_attachment_get_original_owner(territory_attachment) == nil {
				composite_change_add(
					changes,
					original_owner_tracker_add_original_owner_change_territory(
						current,
						territory_get_owner(current),
					),
				)
			}
			factory_and_infrastructure := territory_get_matches(current, infra_pred, infra_ctx)
			composite_change_add(
				changes,
				original_owner_tracker_add_original_owner_change_units(
					factory_and_infrastructure,
					territory_get_owner(current),
				),
			)
		}
	}
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(bridge),
		"Adding original owners",
	)
	i_delegate_bridge_add_change(bridge, &changes.change)
}

