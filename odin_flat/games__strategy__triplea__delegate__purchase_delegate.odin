package game

Purchase_Delegate :: struct {
	using base_triple_a_delegate: Base_Triple_A_Delegate,
	need_to_initialize:       bool,
	pending_production_rules: ^Integer_Map,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PurchaseDelegate

