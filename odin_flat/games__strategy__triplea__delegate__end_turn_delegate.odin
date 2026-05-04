package game

import "core:fmt"

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

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#createUnits(
//     Territory location, Collection<Unit> units,
//     CompositeChange change, StringBuilder endTurnReport)
//
// Java:
//   final String transcriptText =
//       player.getName() + " creates " + MyFormatter.unitsToTextNoOwner(units)
//           + " in " + location.getName();
//   bridge.getHistoryWriter().startEvent(transcriptText, units);
//   endTurnReport.append(transcriptText).append("<br />");
//   final Change place = ChangeFactory.addUnits(location, units);
//   change.add(place);
// ---------------------------------------------------------------------------
end_turn_delegate_create_units :: proc(
	self: ^End_Turn_Delegate,
	location: ^Territory,
	units: [dynamic]^Unit,
	change: ^Composite_Change,
	end_turn_report: ^String_Builder,
) {
	transcript_text := fmt.aprintf(
		"%s creates %s in %s",
		self.player.named.base.name,
		my_formatter_units_to_text_no_owner(units, nil),
		location.named.base.name,
	)
	writer := i_delegate_bridge_get_history_writer(self.bridge)
	i_delegate_history_writer_start_event(writer, transcript_text, nil)
	string_builder_append(end_turn_report, transcript_text)
	string_builder_append(end_turn_report, "<br />")
	place := change_factory_add_units(cast(^Unit_Holder)location, units)
	composite_change_add(change, place)
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#findUnitCreatedResources(
//     GamePlayer player, GameData data)
//
// Java:
//   IntegerMap<Resource> resourceTotalsMap = new IntegerMap<>();
//   Predicate<Unit> myCreatorsMatch =
//       Matches.unitIsOwnedBy(player).and(Matches.unitCreatesResources());
//   for (Territory t : data.getMap().getTerritories()) {
//     for (Unit unit : CollectionUtils.getMatches(t.getUnits(), myCreatorsMatch)) {
//       resourceTotalsMap.add(
//           unit.getUnitAttachment().getCreatesResourcesList());
//     }
//   }
//   Resource pus = new Resource(Constants.PUS, data);
//   if (resourceTotalsMap.containsKey(pus)) {
//     resourceTotalsMap.put(
//         pus, resourceTotalsMap.getInt(pus)
//             * Properties.getPuMultiplier(data.getProperties()));
//   }
//   return resourceTotalsMap;
//
// Pointer-keyed Odin maps need the canonical PUs Resource pointer; we
// look it up via game_data.getResourceList().getResourceOrThrow("PUs"),
// matching the convention used by the rest of the port (see
// resource_collection.odin, ai_utils.odin).
// ---------------------------------------------------------------------------
end_turn_delegate_find_unit_created_resources :: proc(
	player: ^Game_Player,
	data: ^Game_Data,
) -> Integer_Map_Resource {
	resource_totals_map: Integer_Map_Resource = make(Integer_Map_Resource)
	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	creates_pred, creates_ctx := matches_unit_creates_resources()
	for t in game_map_get_territories(game_data_get_map(data)) {
		coll := territory_get_unit_collection(t)
		units := unit_collection_get_units(coll)
		for u in units {
			if !owned_pred(owned_ctx, u) {
				continue
			}
			if !creates_pred(creates_ctx, u) {
				continue
			}
			generated_resources_map := unit_attachment_get_creates_resources_list(
				unit_get_unit_attachment(u),
			)
			for r, qty in generated_resources_map {
				resource_totals_map[r] = resource_totals_map[r] + qty
			}
		}
		delete(units)
	}
	pus := resource_list_get_resource_or_throw(
		game_data_get_resource_list(data),
		"PUs",
	)
	if pus in resource_totals_map {
		multiplier := properties_get_pu_multiplier(game_data_get_properties(data))
		resource_totals_map[pus] = resource_totals_map[pus] * multiplier
	}
	return resource_totals_map
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#getResourceProduction(
//     Collection<Territory> territories, GameState data)
//
// Java:
//   IntegerMap<Resource> resources = new IntegerMap<>();
//   for (Territory current : territories) {
//     TerritoryAttachment attachment = TerritoryAttachment.getOrThrow(current);
//     Optional<ResourceCollection> optionalToAdd = attachment.getResources();
//     if (optionalToAdd.isEmpty()) continue;
//     if (Matches.territoryCanCollectIncomeFrom(current.getOwner()).test(current)) {
//       resources.add(optionalToAdd.get().getResourcesCopy());
//     }
//   }
//   return resources;
//
// `data` is unused in the Java body (it is a leftover required by the
// public signature) but is kept here to mirror the API.
// ---------------------------------------------------------------------------
end_turn_delegate_get_resource_production :: proc(
	territories: [dynamic]^Territory,
	data: ^Game_State,
) -> Integer_Map_Resource {
	_ = data
	resources: Integer_Map_Resource = make(Integer_Map_Resource)
	for current in territories {
		attachment := territory_attachment_get_or_throw(current)
		optional_to_add := territory_attachment_get_resources(attachment)
		if optional_to_add == nil {
			continue
		}
		can_collect_pred, can_collect_ctx := matches_territory_can_collect_income_from(
			territory_get_owner(current),
		)
		if can_collect_pred(can_collect_ctx, current) {
			to_add := resource_collection_get_resources_copy(optional_to_add)
			for r, qty in to_add {
				resources[r] = resources[r] + qty
			}
			delete(to_add)
		}
	}
	return resources
}

// Captured-closure record for the AND-chained Predicate<Territory>:
//   Matches.isTerritoryOwnedBy(player).and(Matches.territoryIsLand())
// used by createUnits when picking a land neighbor for created land
// units that originated from a sea creator.
End_Turn_Delegate_Ctx_owned_land_match :: struct {
	owned_pred:   proc(rawptr, ^Territory) -> bool,
	owned_ctx:    rawptr,
	is_land_pred: proc(rawptr, ^Territory) -> bool,
	is_land_ctx:  rawptr,
}

end_turn_delegate_lambda_owned_land_match :: proc(
	ctx_ptr: rawptr,
	t: ^Territory,
) -> bool {
	c := cast(^End_Turn_Delegate_Ctx_owned_land_match)ctx_ptr
	return c.owned_pred(c.owned_ctx, t) && c.is_land_pred(c.is_land_ctx, t)
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#createUnits(IDelegateBridge)
//
// Iterates every territory on the map; for each territory finds units
// owned by the current player that have the "creates units" ability,
// computes the units they create, and routes them to the right
// territory (sea-only goes to a random water neighbor, land-only goes
// to a random owned-land neighbor, otherwise stays in place). Defers
// to the existing 4-arg helper `end_turn_delegate_create_units` for
// the actual unit placement and history-event emission.
//
// Suffix `_with_bridge` disambiguates this top-level public method
// from the 4-arg private helper that already owns the canonical
// `end_turn_delegate_create_units` name (Odin has no overloading);
// matches the convention used elsewhere in the port (e.g.
// `trigger_attachment_trigger_resource_change_simple`).
// ---------------------------------------------------------------------------
end_turn_delegate_create_units_with_bridge :: proc(
	self: ^End_Turn_Delegate,
	bridge: ^I_Delegate_Bridge,
) -> string {
	end_turn_report := string_builder_new()
	data := abstract_delegate_get_data(&self.abstract_delegate)
	player := game_step_get_player_id(
		game_sequence_get_step(game_state_get_sequence(&data.game_state)),
	)

	owned_pred, owned_ctx := matches_unit_is_owned_by(player)
	creates_pred, creates_ctx := matches_unit_creates_units()

	change := composite_change_new()
	for t in game_map_get_territories(game_data_get_map(data)) {
		territory_units := unit_collection_get_units(territory_get_unit_collection(t))
		my_creators: [dynamic]^Unit
		for u in territory_units {
			if owned_pred(owned_ctx, u) && creates_pred(creates_ctx, u) {
				append(&my_creators, u)
			}
		}
		delete(territory_units)

		if len(my_creators) == 0 {
			delete(my_creators)
			continue
		}

		to_add: [dynamic]^Unit
		to_add_sea: [dynamic]^Unit
		to_add_land: [dynamic]^Unit
		for u in my_creators {
			ua := unit_get_unit_attachment(u)
			creates_units_map := unit_attachment_get_creates_units_list(ua)
			for ut, qty in creates_units_map {
				ua_to_create := unit_type_get_unit_attachment(ut)
				created := unit_type_create_2(ut, qty, player)
				if unit_attachment_is_sea(ua_to_create) && !territory_is_water(t) {
					for c in created {
						append(&to_add_sea, c)
					}
				} else if !unit_attachment_is_sea(ua_to_create) &&
				   !unit_attachment_is_air(ua_to_create) &&
				   territory_is_water(t) {
					for c in created {
						append(&to_add_land, c)
					}
				} else {
					for c in created {
						append(&to_add, c)
					}
				}
				delete(created)
			}
		}
		delete(my_creators)

		if len(to_add) > 0 {
			end_turn_delegate_create_units(self, t, to_add, change, end_turn_report)
		}
		if len(to_add_sea) > 0 {
			water_pred, water_ctx := matches_territory_is_water()
			water_neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(data),
				t,
				water_pred,
				water_ctx,
			)
			if len(water_neighbors) > 0 {
				arr: [dynamic]^Territory
				for n in water_neighbors {
					append(&arr, n)
				}
				location := end_turn_delegate_get_random_territory(
					&data.game_state,
					arr,
					bridge,
				)
				end_turn_delegate_create_units(
					self,
					location,
					to_add_sea,
					change,
					end_turn_report,
				)
				delete(arr)
			}
			delete(water_neighbors)
		}
		if len(to_add_land) > 0 {
			owned_terr_pred, owned_terr_ctx := matches_is_territory_owned_by(player)
			land_pred, land_ctx := matches_territory_is_land()
			ctx_ol := new(End_Turn_Delegate_Ctx_owned_land_match)
			ctx_ol.owned_pred = owned_terr_pred
			ctx_ol.owned_ctx = owned_terr_ctx
			ctx_ol.is_land_pred = land_pred
			ctx_ol.is_land_ctx = land_ctx
			land_neighbors := game_map_get_neighbors_predicate(
				game_data_get_map(data),
				t,
				end_turn_delegate_lambda_owned_land_match,
				rawptr(ctx_ol),
			)
			if len(land_neighbors) > 0 {
				arr: [dynamic]^Territory
				for n in land_neighbors {
					append(&arr, n)
				}
				location := end_turn_delegate_get_random_territory(
					&data.game_state,
					arr,
					bridge,
				)
				end_turn_delegate_create_units(
					self,
					location,
					to_add_land,
					change,
					end_turn_report,
				)
				delete(arr)
			}
			delete(land_neighbors)
		}
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
	return string_builder_to_string(end_turn_report)
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#addUnitCreatedResources(
//     IDelegateBridge bridge)
//
// Sums up the resources produced by every unit-creator on the map (via
// findUnitCreatedResources), applies floor-at-zero, emits a history
// event per resource, accumulates the resource changes, and returns
// the report fragment.
// ---------------------------------------------------------------------------
end_turn_delegate_add_unit_created_resources :: proc(
	self: ^End_Turn_Delegate,
	bridge: ^I_Delegate_Bridge,
) -> string {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	player := game_step_get_player_id(
		game_sequence_get_step(game_state_get_sequence(&data.game_state)),
	)
	resource_totals_map := end_turn_delegate_find_unit_created_resources(player, data)
	defer delete(resource_totals_map)

	end_turn_report := string_builder_new()
	change := composite_change_new()
	for resource, qty in resource_totals_map {
		to_add := qty
		if to_add == 0 {
			continue
		}
		total :=
			resource_collection_get_quantity(game_player_get_resources(player), resource) +
			to_add
		if total < 0 {
			to_add -= total
			total = 0
		}
		resource_name := default_named_get_name(&resource.named_attachable.default_named)
		player_name := default_named_get_name(&player.named_attachable.default_named)
		transcript_text := fmt.aprintf(
			"Units generate %d %s; %s end with %d %s",
			to_add,
			resource_name,
			player_name,
			total,
			resource_name,
		)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			transcript_text,
			nil,
		)
		string_builder_append(end_turn_report, transcript_text)
		string_builder_append(end_turn_report, "<br />")
		composite_change_add(
			change,
			change_factory_change_resources_change(player, resource, to_add),
		)
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
	return string_builder_to_string(end_turn_report)
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#determineNationalObjectives(
//     IDelegateBridge bridge)
//
// Resolves and fires resource-changing triggers (when enabled by game
// properties) and applies satisfied national-objective rules: each
// adds objectiveValue * eachMultiple * PuMultiplier PUs to the player,
// decrements `uses` by one when bounded, emits a history event, and
// appends a one-line summary to the end-of-turn report.
// ---------------------------------------------------------------------------
end_turn_delegate_determine_national_objectives :: proc(
	self: ^End_Turn_Delegate,
	bridge: ^I_Delegate_Bridge,
) -> string {
	data := abstract_delegate_get_data(&self.abstract_delegate)
	player := game_step_get_player_id(
		game_sequence_get_step(game_state_get_sequence(&data.game_state)),
	)

	triggers := make(map[^Trigger_Attachment]struct {})
	objectives := make([dynamic]^Rules_Attachment)
	tested_conditions := end_turn_delegate_test_national_objectives_and_triggers(
		player,
		&data.game_state,
		bridge,
		&triggers,
		&objectives,
	)
	defer delete(tested_conditions)

	end_turn_report := string_builder_new()
	use_triggers := properties_get_triggers(game_data_get_properties(data))
	if use_triggers && len(triggers) > 0 {
		sat_pred, sat_ctx := abstract_trigger_attachment_is_satisfied_match(
			tested_conditions,
		)
		to_fire := make(map[^Trigger_Attachment]struct {})
		for t in triggers {
			if sat_pred(sat_ctx, t) {
				to_fire[t] = {}
			}
		}
		params := fire_trigger_params_new("", "", true, true, true, true)
		report := trigger_attachment_trigger_resource_change_simple(
			to_fire,
			bridge,
			params,
		)
		string_builder_append(end_turn_report, report)
		string_builder_append(end_turn_report, "<br />")
		delete(to_fire)
	}

	pus_resource := resource_list_get_resource_or_throw(
		game_data_get_resource_list(data),
		"PUs",
	)
	for rule in objectives {
		uses := rule.uses
		if uses == 0 || !rules_attachment_is_satisfied(rule, tested_conditions) {
			continue
		}
		to_add := rule.objective_value
		to_add *= properties_get_pu_multiplier(game_data_get_properties(data))
		to_add *= rule.each_multiple
		total :=
			resource_collection_get_quantity(
				game_player_get_resources(player),
				pus_resource,
			) +
			to_add
		if total < 0 {
			to_add -= total
			total = 0
		}
		i_delegate_bridge_add_change(
			bridge,
			change_factory_change_resources_change(player, pus_resource, to_add),
		)
		if uses > 0 {
			uses -= 1
			uses_str := new(string)
			uses_str^ = fmt.aprintf("%d", uses)
			i_delegate_bridge_add_change(
				bridge,
				change_factory_attachment_property_change(
					cast(^I_Attachment)rawptr(rule),
					rawptr(uses_str),
					"uses",
				),
			)
		}
		player_name := default_named_get_name(&player.named_attachable.default_named)
		pu_message := fmt.aprintf(
			"%s: %s met a national objective for an additional %d%s; end with %d%s",
			my_formatter_attachment_name_to_text(rule.name),
			player_name,
			to_add,
			my_formatter_pluralize_quantity(" PU", to_add),
			total,
			my_formatter_pluralize_quantity(" PU", total),
		)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			pu_message,
			nil,
		)
		string_builder_append(end_turn_report, pu_message)
		string_builder_append(end_turn_report, "<br />")
	}
	delete(triggers)
	delete(objectives)
	return string_builder_to_string(end_turn_report)
}

// ---------------------------------------------------------------------------
// games.strategy.triplea.delegate.EndTurnDelegate#addOtherResources(
//     IDelegateBridge bridge)
//
// Collects non-PU territory resources for every territory owned by
// the current player (`getResourceProduction`), applies floor-at-zero
// adjustments, and emits per-resource history events plus report
// lines. Overrides the base AbstractEndTurnDelegate hook so that
// non-PU resources accrue alongside the PU income computed by the
// abstract base class.
// ---------------------------------------------------------------------------
end_turn_delegate_add_other_resources :: proc(
	self: ^End_Turn_Delegate,
	bridge: ^I_Delegate_Bridge,
) -> string {
	end_turn_report := string_builder_new()
	data := i_delegate_bridge_get_data(bridge)
	change := composite_change_new()
	territories := game_map_get_territories_owned_by(
		game_data_get_map(data),
		self.player,
	)
	defer delete(territories)
	production := end_turn_delegate_get_resource_production(territories, &data.game_state)
	defer delete(production)
	player_name := default_named_get_name(&self.player.named_attachable.default_named)
	for r, qty in production {
		to_add := qty
		total :=
			resource_collection_get_quantity(
				game_player_get_resources(self.player),
				r,
			) +
			to_add
		if total < 0 {
			to_add -= total
			total = 0
		}
		resource_name := default_named_get_name(&r.named_attachable.default_named)
		resource_text := fmt.aprintf(
			"%s collects %d %s; ends with %d %s total",
			player_name,
			to_add,
			my_formatter_pluralize_quantity(resource_name, to_add),
			total,
			my_formatter_pluralize_quantity(resource_name, total),
		)
		i_delegate_history_writer_start_event(
			i_delegate_bridge_get_history_writer(bridge),
			resource_text,
			nil,
		)
		string_builder_append(end_turn_report, resource_text)
		string_builder_append(end_turn_report, "<br />")
		composite_change_add(
			change,
			change_factory_change_resources_change(self.player, r, to_add),
		)
	}
	if !composite_change_is_empty(change) {
		i_delegate_bridge_add_change(bridge, &change.change)
	}
	return string_builder_to_string(end_turn_report)
}
