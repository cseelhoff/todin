package game

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

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PurchaseDelegate

