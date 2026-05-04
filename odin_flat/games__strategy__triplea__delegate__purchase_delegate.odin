package game

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

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PurchaseDelegate

