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
