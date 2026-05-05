package game

import "core:fmt"
import "core:strings"

Purchase_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize:       bool,
	pending_production_rules: ^Integer_Map,
}

// games.strategy.triplea.delegate.PurchaseDelegate#getRemoteType()
// Java returns `Class<IPurchaseDelegate>`; Odin mirrors IDelegate#getRemoteType
// and returns the corresponding `typeid`.
purchase_delegate_get_remote_type :: proc(self: ^Purchase_Delegate) -> typeid {
	return I_Purchase_Delegate
}

// games.strategy.triplea.delegate.PurchaseDelegate#lambda$static$0(games.strategy.engine.data.RepairRule)
// Body of the static comparator key extractor:
//   `o -> (UnitType) o.getAnyResultKey()`
// used to build `repairRuleComparator`. Java's RepairRule.getAnyResultKey()
// returns CollectionUtils.getAny(getResults().keySet()); for a RepairRule the
// result keys are always UnitType instances.
purchase_delegate_lambda_static_0 :: proc(rule: ^Repair_Rule) -> ^Unit_Type {
	if rule == nil || rule.results == nil {
		return nil
	}
	for k, _ in rule.results.map_values {
		return cast(^Unit_Type)k
	}
	return nil
}

// games.strategy.triplea.delegate.PurchaseDelegate#getUnitRepairs(java.util.Map)
// Java is `private static IntegerMap<Unit> getUnitRepairs(Map<Unit, IntegerMap<RepairRule>>)`.
// Builds an Integer_Map<Unit> summing, for each unit, rules.getInt(repairRule)
// * repairRule.getResults().getInt(unit.getType()) across every repair rule.
// Java sorts via `repairRuleComparator` before iterating — that is purely
// cosmetic since `repairMap.add` is associative and commutative; the resulting
// integer map is independent of iteration order, so we iterate the keys
// directly.
purchase_delegate_get_unit_repairs :: proc(repair_rules: map[^Unit]^Integer_Map) -> ^Integer_Map {
	repair_map := integer_map_new()
	for u, rules in repair_rules {
		if rules == nil {
			continue
		}
		for rk, count in rules.map_values {
			repair_rule := cast(^Repair_Rule)rk
			results := repair_rule_get_results(repair_rule)
			per_unit: i32 = 0
			if results != nil {
				per_unit = integer_map_get_int(results, rawptr(unit_get_type(u)))
			}
			quantity := count * per_unit
			integer_map_add(repair_map, rawptr(u), quantity)
		}
	}
	return repair_map
}

// games.strategy.triplea.delegate.PurchaseDelegate#lambda$purchaseRepair$1(IntegerMap, Territory)
// Java lambda body: `territory -> !Collections.disjoint(territory.getUnits(), damageMap.keySet())`.
// Captures `damageMap`, lifted to a free proc with the captured Integer_Map<Unit>
// as the first parameter. Returns true iff the territory contains at least one
// unit that appears as a key in the damage map.
purchase_delegate_lambda_purchase_repair_1 :: proc(damage_map: ^Integer_Map, territory: ^Territory) -> bool {
	if damage_map == nil || territory == nil {
		return false
	}
	collection := territory_get_unit_collection(territory)
	if collection == nil {
		return false
	}
	for unit in collection.units {
		if _, ok := damage_map.map_values[rawptr(unit)]; ok {
			return true
		}
	}
	return false
}

// games.strategy.triplea.delegate.PurchaseDelegate#loadState(java.io.Serializable)
// Java casts the opaque Serializable to PurchaseExtendedDelegateState, replays
// the embedded super state, and copies `needToInitialize` /
// `pendingProductionRules` back onto the delegate.
purchase_delegate_load_state :: proc(self: ^Purchase_Delegate, state: rawptr) {
	s := cast(^Purchase_Extended_Delegate_State)state
	base_triple_a_delegate_load_state(
		&self.base_triple_a_delegate,
		cast(^Base_Delegate_State)s.super_state,
	)
	self.need_to_initialize = s.need_to_initialize
	self.pending_production_rules = s.pending_production_rules
}

// games.strategy.triplea.delegate.PurchaseDelegate#<init>()
// Java's implicit no-arg constructor: needToInitialize defaults to `true`
// (declared inline), pendingProductionRules to null, and the embedded
// BaseTripleADelegate / AbstractDelegate fields are zero-initialized.
purchase_delegate_new :: proc() -> ^Purchase_Delegate {
	self := new(Purchase_Delegate)
	self.need_to_initialize = true
	self.pending_production_rules = nil
	return self
}

// games.strategy.triplea.delegate.PurchaseDelegate#getResults(org.triplea.java.collections.IntegerMap)
// Java: `private static IntegerMap<NamedAttachable> getResults(IntegerMap<ProductionRule>)`.
// For each production rule key, accumulates `rule.getResults() * productionRules.getInt(rule)`
// into a fresh IntegerMap<NamedAttachable>.
purchase_delegate_get_results :: proc(production_rules: ^Integer_Map) -> ^Integer_Map {
	costs := integer_map_new()
	if production_rules == nil {
		return costs
	}
	for k, count in production_rules.map_values {
		rule := cast(^Production_Rule)k
		results := production_rule_get_results(rule)
		integer_map_add_multiple(costs, &results, count)
	}
	return costs
}

// games.strategy.triplea.delegate.PurchaseDelegate#saveState()
// Builds a PurchaseExtendedDelegateState wrapping the super state and
// snapshotting the two delegate fields.
purchase_delegate_save_state :: proc(self: ^Purchase_Delegate) -> ^Purchase_Extended_Delegate_State {
	state := purchase_extended_delegate_state_new()
	state.super_state = rawptr(base_triple_a_delegate_save_state(&self.base_triple_a_delegate))
	state.need_to_initialize = self.need_to_initialize
	state.pending_production_rules = self.pending_production_rules
	return state
}

// games.strategy.triplea.delegate.PurchaseDelegate#canAfford(IntegerMap, GamePlayer)
// Java: `return player.getResources().has(costs);`
// `ResourceCollection.has(IntegerMap<Resource>)` delegates to
// `resources.greaterThanOrEqualTo(map)`, i.e. for every key in `costs` the
// player's wallet must hold at least that quantity. Costs here is the
// generic Integer_Map produced by purchase_delegate_get_costs (rawptr keys
// to ^Resource), so we iterate it directly against the typed
// Resource_Collection wallet.
purchase_delegate_can_afford :: proc(
	self:   ^Purchase_Delegate,
	costs:  ^Integer_Map,
	player: ^Game_Player,
) -> bool {
	wallet := game_player_get_resources(player)
	if costs == nil {
		return true
	}
	for k, required in costs.map_values {
		resource := cast(^Resource)k
		if resource_collection_get_quantity(wallet, resource) < required {
			return false
		}
	}
	return true
}

// games.strategy.triplea.delegate.PurchaseDelegate#canWePurchaseOrRepair()
// Java iterates the player's production frontier rules and then the repair
// frontier rules, returning true if the player's resources cover any single
// rule's cost. `player.getResources().has(rule.getCosts())` is inlined here:
// rule.getCosts() returns an Integer_Map keyed by ^Resource (rawptr-typed),
// and the wallet check mirrors `resource_collection_has` — every rule-cost
// entry must be <= the player's quantity for that resource.
purchase_delegate_can_we_purchase_or_repair :: proc(self: ^Purchase_Delegate) -> bool {
	player := self.player
	wallet := game_player_get_resources(player)
	pf := player.production_frontier
	if pf != nil {
		rules := production_frontier_get_rules(pf)
		for rule in rules {
			costs := production_rule_get_costs(rule)
			defer delete(costs.map_values)
			affordable := true
			for k, required in costs.map_values {
				resource := cast(^Resource)k
				if resource_collection_get_quantity(wallet, resource) < required {
					affordable = false
					break
				}
			}
			if affordable {
				return true
			}
		}
	}
	rf := game_player_get_repair_frontier(player)
	if rf != nil {
		rules := repair_frontier_get_rules(rf)
		for rule in rules {
			costs := repair_rule_get_costs(rule)
			defer delete(costs.map_values)
			affordable := true
			for k, required in costs.map_values {
				resource := cast(^Resource)k
				if resource_collection_get_quantity(wallet, resource) < required {
					affordable = false
					break
				}
			}
			if affordable {
				return true
			}
		}
	}
	return false
}

// games.strategy.triplea.delegate.PurchaseDelegate#getCosts(IntegerMap<ProductionRule>)
// Java: `private static IntegerMap<Resource> getCosts(IntegerMap<ProductionRule>)`.
// For each production rule key, accumulates `rule.getCosts() *
// productionRules.getInt(rule)` into a fresh IntegerMap<Resource>.
purchase_delegate_get_costs :: proc(production_rules: ^Integer_Map) -> ^Integer_Map {
	costs := integer_map_new()
	if production_rules == nil {
		return costs
	}
	for k, count in production_rules.map_values {
		rule := cast(^Production_Rule)k
		rule_costs := production_rule_get_costs(rule)
		integer_map_add_multiple(costs, &rule_costs, count)
		delete(rule_costs.map_values)
	}
	return costs
}

// games.strategy.triplea.delegate.PurchaseDelegate#removeFromPlayer(IntegerMap<Resource>, CompositeChange)
// Builds the "Remaining resources: <n> <name>; ..." status string from the
// player's wallet minus the costs, and appends a per-resource
// changeResourcesChange(player, resource, -cost) to the supplied composite
// change. Java's `(int) (float) costs.getInt(resource)` is a noop in Odin:
// integer_map values are already i32, so we negate directly.
purchase_delegate_remove_from_player :: proc(
	self: ^Purchase_Delegate,
	costs: ^Integer_Map,
	changes: ^Composite_Change,
) -> string {
	b: strings.Builder
	strings.builder_init(&b)
	strings.write_string(&b, "Remaining resources: ")
	player := self.player
	left := resource_collection_get_resources_copy(game_player_get_resources(player))
	defer delete(left)
	if costs != nil {
		for k, v in costs.map_values {
			resource := cast(^Resource)k
			existing, _ := left[resource]
			left[resource] = existing - v
		}
	}
	for resource, value in left {
		strings.write_int(&b, int(value))
		strings.write_byte(&b, ' ')
		strings.write_string(&b, resource.named.base.name)
		strings.write_string(&b, "; ")
	}
	if costs != nil {
		for k, quantity in costs.map_values {
			resource := cast(^Resource)k
			cost := quantity
			composite_change_add(
				changes,
				change_factory_change_resources_change(player, resource, -cost),
			)
		}
	}
	return strings.to_string(b)
}

// games.strategy.triplea.delegate.PurchaseDelegate#delegateCurrentlyRequiresUserInput()
// Java:
//   if (!canWePurchaseOrRepair()) return false;
//   return TerritoryAttachment.doWeHaveEnoughCapitalsToProduce(player, getData().getMap());
purchase_delegate_delegate_currently_requires_user_input :: proc(self: ^Purchase_Delegate) -> bool {
	if !purchase_delegate_can_we_purchase_or_repair(self) {
		return false
	}
	return territory_attachment_do_we_have_enough_capitals_to_produce(
		self.player,
		game_data_get_map(abstract_delegate_get_data(&self.abstract_delegate)),
	)
}

// games.strategy.triplea.delegate.PurchaseDelegate#purchase(IntegerMap<ProductionRule>)
// Validates affordability and per-unit-type build limits, builds CompositeChange
// for added resources, added units and spent resources, writes a transcript
// history event ("<player> buy <list>; <remaining>" or "<player> buy nothing;
// <remaining>"), and commits the change. Returns "" for Java's null (success);
// returns "Not enough resources" or a build-limit error message on rejection.
// Empty string "" mirrors Java's @Nullable String null per the abstract trigger
// attachment convention used elsewhere in odin_flat.
purchase_delegate_purchase :: proc(
	self: ^Purchase_Delegate,
	production_rules: ^Integer_Map,
) -> string {
	costs := purchase_delegate_get_costs(production_rules)
	results := purchase_delegate_get_results(production_rules)
	if !purchase_delegate_can_afford(self, costs, self.player) {
		return "Not enough resources"
	}
	// check building limits
	for k, _ in results.map_values {
		na := cast(^Named_Attachable)k
		if na.default_named.named.kind != .Unit_Type {
			continue
		}
		type := cast(^Unit_Type)k
		quantity := integer_map_get_int(results, k)
		max_built := unit_attachment_get_max_built_per_player(unit_type_get_unit_attachment(type))
		if max_built == 0 {
			return fmt.aprintf(
				"May not build any of this unit right now: %s",
				type.named.base.name,
			)
		} else if max_built > 0 {
			currently_built: i32 = 0
			player_uc := game_player_get_unit_collection(self.player)
			if player_uc != nil {
				for u in player_uc.units {
					if unit_get_type(u) == type {
						currently_built += 1
					}
				}
			}
			game_map := game_data_get_map(abstract_delegate_get_data(&self.abstract_delegate))
			for t in game_map_get_territories(game_map) {
				t_uc := territory_get_unit_collection(t)
				if t_uc == nil {
					continue
				}
				for u in t_uc.units {
					if unit_get_type(u) == type && unit_is_owned_by(u, self.player) {
						currently_built += 1
					}
				}
			}
			allowed_build := max(i32(0), max_built - currently_built)
			if quantity > allowed_build {
				return fmt.aprintf(
					"May only build %d of %s this turn, may only build %d total",
					allowed_build,
					type.named.base.name,
					max_built,
				)
			}
		}
	}
	// remove first, since add logs PUs remaining
	total_units: [dynamic]^Unit
	total_unit_types: [dynamic]^Unit_Type
	total_resources: [dynamic]^Resource
	changes := composite_change_new()
	// add changes for added resources, find all added units
	for k, _ in results.map_values {
		na := cast(^Named_Attachable)k
		quantity := integer_map_get_int(results, k)
		if na.default_named.named.kind != .Unit_Type {
			resource := cast(^Resource)k
			composite_change_add(
				changes,
				change_factory_change_resources_change(self.player, resource, quantity),
			)
			for i: i32 = 0; i < quantity; i += 1 {
				append(&total_resources, resource)
			}
		} else {
			type := cast(^Unit_Type)k
			units := unit_type_create_2(type, quantity, self.player)
			for u in units {
				append(&total_units, u)
			}
			delete(units)
			for i: i32 = 0; i < quantity; i += 1 {
				append(&total_unit_types, type)
			}
		}
	}
	total_all: [dynamic]^Default_Named
	for ut in total_unit_types {
		append(&total_all, cast(^Default_Named)ut)
	}
	for r in total_resources {
		append(&total_all, cast(^Default_Named)r)
	}
	// add changes for added units
	if len(total_units) > 0 {
		composite_change_add(
			changes,
			change_factory_add_units(cast(^Unit_Holder)self.player, total_units),
		)
	}
	// add changes for spent resources
	remaining := purchase_delegate_remove_from_player(self, costs, changes)
	// add history event
	transcript_text: string
	player_name := self.player.named.base.name
	if len(total_units) > 0 {
		transcript_text = fmt.aprintf(
			"%s buy %s; %s",
			player_name,
			my_formatter_default_named_to_text_list(total_all, ", ", true),
			remaining,
		)
	} else {
		transcript_text = fmt.aprintf("%s buy nothing; %s", player_name, remaining)
	}
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		transcript_text,
		rawptr(&total_units),
	)
	// commit changes
	i_delegate_bridge_add_change(self.bridge, cast(^Change)changes)
	return ""
}

// games.strategy.triplea.delegate.PurchaseDelegate#getRepairCosts(java.util.Map, GamePlayer)
// Java: `private IntegerMap<Resource> getRepairCosts(
//   Map<Unit, IntegerMap<RepairRule>> repairRules, GamePlayer player)`.
// Sums `rule.getCosts() * map.getInt(rule)` over every (unit -> rule -> count)
// entry into a fresh Integer_Map<Resource>, then applies the player's
// repair-tech discount (1.0 means no discount). The discount is
// TechAbilityAttachment.getRepairDiscount over the player's current tech
// advances drawn from `getData().getTechnologyFrontier()`.
purchase_delegate_get_repair_costs :: proc(
	self:         ^Purchase_Delegate,
	repair_rules: map[^Unit]^Integer_Map,
	player:       ^Game_Player,
) -> ^Integer_Map {
	costs := integer_map_new()
	for _, rules in repair_rules {
		if rules == nil {
			continue
		}
		for k, count in rules.map_values {
			rule := cast(^Repair_Rule)k
			rule_costs := repair_rule_get_costs(rule)
			integer_map_add_multiple(costs, &rule_costs, count)
			delete(rule_costs.map_values)
		}
	}
	data := abstract_delegate_get_data(&self.abstract_delegate)
	advances := tech_tracker_get_current_tech_advances(
		player,
		game_data_get_technology_frontier(data),
	)
	defer delete(advances)
	discount := tech_ability_attachment_get_repair_discount_with_techs(advances)
	if discount != 1.0 {
		integer_map_multiply_all_values_by(costs, discount)
	}
	return costs
}

// games.strategy.triplea.delegate.PurchaseDelegate#purchaseRepair(java.util.Map)
// Java: `public @Nullable String purchaseRepair(Map<Unit, IntegerMap<RepairRule>>)`.
// Validates affordability via `getRepairCosts`, short-circuits when the
// `damageFromBombingDoneToUnitsInsteadOfTerritories` property is off, builds a
// damage_map of `max(0, currentDamage - repairCount)` per repaired factory,
// emits a CompositeChange holding `bombingUnitDamage(damageMap, affectedTerritories)`
// where the territories are those still containing any damaged unit, charges
// the player via `removeFromPlayer`, writes a "<player> repair damage of <list>;
// <remaining>" / "<player> repair nothing; <remaining>" history event whose
// rendering data is the damage_map's key set, and finally commits the change
// when non-empty. Returns "" on success (Java's null) and "Not enough resources"
// on rejection.
purchase_delegate_purchase_repair :: proc(
	self:         ^Purchase_Delegate,
	repair_rules: map[^Unit]^Integer_Map,
) -> string {
	costs := purchase_delegate_get_repair_costs(self, repair_rules, self.player)
	if !purchase_delegate_can_afford(self, costs, self.player) {
		return "Not enough resources"
	}
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if !properties_get_damage_from_bombing_done_to_units_instead_of_territories(
		game_data_get_properties(data),
	) {
		return ""
	}
	// Get the map of the factories that were repaired and how much for each
	repair_map := purchase_delegate_get_unit_repairs(repair_rules)
	if integer_map_is_empty(repair_map) {
		return ""
	}
	// remove first, since add logs PUs remaining
	changes := composite_change_new()
	damage_map := integer_map_new()
	for k, _ in repair_map.map_values {
		unit := cast(^Unit)k
		repair_count := integer_map_get_int(repair_map, k)
		// Display appropriate damaged/repaired factory and factory damage totals
		if repair_count > 0 {
			current := unit_get_unit_damage(unit)
			new_damage_total := max(i32(0), current - repair_count)
			if new_damage_total != current {
				integer_map_put(damage_map, k, new_damage_total)
			}
		}
	}
	if !integer_map_is_empty(damage_map) {
		typed := new(Integer_Map_Unit)
		typed.entries = make(map[^Unit]i32)
		for k, v in damage_map.map_values {
			typed.entries[cast(^Unit)k] = v
		}
		territories: [dynamic]^Territory
		for t in game_map_get_territories(game_data_get_map(data)) {
			if purchase_delegate_lambda_purchase_repair_1(damage_map, t) {
				append(&territories, t)
			}
		}
		composite_change_add(changes, change_factory_bombing_unit_damage(typed, territories))
	}
	// add changes for spent resources
	remaining := purchase_delegate_remove_from_player(self, costs, changes)
	// add history event
	transcript_text: string
	player_name := self.player.named.base.name
	if !integer_map_is_empty(damage_map) {
		transcript_text = fmt.aprintf(
			"%s repair damage of %s; %s",
			player_name,
			my_formatter_integer_unit_map_to_string(repair_map, ", ", "x ", true),
			remaining,
		)
	} else {
		transcript_text = fmt.aprintf("%s repair nothing; %s", player_name, remaining)
	}
	// rendering data is `new HashSet<>(damageMap.keySet())`
	damaged_keys: [dynamic]^Unit
	for k, _ in damage_map.map_values {
		append(&damaged_keys, cast(^Unit)k)
	}
	i_delegate_history_writer_start_event(
		i_delegate_bridge_get_history_writer(self.bridge),
		transcript_text,
		rawptr(&damaged_keys),
	)
	// commit changes
	if !composite_change_is_empty(changes) {
		i_delegate_bridge_add_change(self.bridge, cast(^Change)changes)
	}
	return ""
}

// games.strategy.triplea.delegate.PurchaseDelegate#end()
// Java body:
//   super.end();
//   pendingProductionRules = null;
//   needToInitialize = true;
purchase_delegate_end :: proc(self: ^Purchase_Delegate) {
	base_triple_a_delegate_end(&self.base_triple_a_delegate)
	self.pending_production_rules = nil
	self.need_to_initialize = true
}

// AND-chained Predicate<TriggerAttachment> used by PurchaseDelegate.start():
//   availableUses
//     .and(whenOrDefaultMatch(null, null))
//     .and(prodMatch().or(prodFrontierEditMatch()).or(purchaseMatch()))
// `availableUses`, `prodMatch`, `prodFrontierEditMatch`, and `purchaseMatch`
// are non-capturing bare procs; only `whenOrDefaultMatch` carries a
// captured (proc, rawptr) pair, so the composite ctx stores only it.
Purchase_Delegate_Ctx_trigger_match :: struct {
	when_pred: proc(rawptr, ^Trigger_Attachment) -> bool,
	when_ctx:  rawptr,
}

purchase_delegate_lambda_trigger_match :: proc(
	ctx_ptr: rawptr,
	t: ^Trigger_Attachment,
) -> bool {
	ctx := cast(^Purchase_Delegate_Ctx_trigger_match)ctx_ptr
	if !abstract_trigger_attachment_lambda_static_0(t) {
		return false
	}
	if !ctx.when_pred(ctx.when_ctx, t) {
		return false
	}
	if trigger_attachment_lambda_prod_match(t) {
		return true
	}
	if trigger_attachment_lambda_prod_frontier_edit_match(t) {
		return true
	}
	return trigger_attachment_lambda_purchase_match(t)
}

// games.strategy.triplea.delegate.PurchaseDelegate#start()
// Java body translated branch-for-branch. Fires every prod / prod-frontier-edit
// / purchase trigger attached to `player` that has uses left and whose `when`
// list is empty (i.e. the default firing location). The triple-OR predicate
// is built inline as `purchase_delegate_lambda_trigger_match`.
purchase_delegate_start :: proc(self: ^Purchase_Delegate) {
	base_triple_a_delegate_start(&self.base_triple_a_delegate)
	data := abstract_delegate_get_data(&self.abstract_delegate)
	if self.need_to_initialize {
		if properties_get_triggers(game_data_get_properties(data)) {
			when_pred, when_ctx := abstract_trigger_attachment_when_or_default_match("", "")
			match_ctx := new(Purchase_Delegate_Ctx_trigger_match)
			match_ctx.when_pred = when_pred
			match_ctx.when_ctx = when_ctx

			players_set := make(map[^Game_Player]struct {})
			defer delete(players_set)
			players_set[self.player] = {}

			to_fire_possible := trigger_attachment_collect_for_all_triggers_matching(
				players_set,
				purchase_delegate_lambda_trigger_match,
				rawptr(match_ctx),
			)
			if len(to_fire_possible) != 0 {
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
				fire_trigger_params := fire_trigger_params_new(
					"", "", true, true, true, true,
				)
				trigger_attachment_trigger_production_change(
					to_fire_tested_and_satisfied,
					self.bridge,
					fire_trigger_params,
				)
				trigger_attachment_trigger_production_frontier_edit_change(
					to_fire_tested_and_satisfied,
					self.bridge,
					fire_trigger_params,
				)
				trigger_attachment_trigger_purchase(
					to_fire_tested_and_satisfied,
					self.bridge,
					fire_trigger_params,
				)
			}
		}
		self.need_to_initialize = false
	}
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PurchaseDelegate

