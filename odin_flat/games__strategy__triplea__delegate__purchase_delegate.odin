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

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PurchaseDelegate

