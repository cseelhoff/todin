package game

// games.strategy.triplea.delegate.remote.IPurchaseDelegate
// Java pure-interface modeled in Odin as a vtable struct. Concrete
// implementation Purchase_Delegate (and its subclasses Bid_Purchase_Delegate,
// No_Pu_Purchase_Delegate) build an instance via
// purchase_delegate_to_i_purchase_delegate, populating `concrete` with the
// real delegate pointer and the proc fields with per-impl thunks.
I_Purchase_Delegate :: struct {
	using i_abstract_forum_poster_delegate: I_Abstract_Forum_Poster_Delegate,

	// Pointer to the underlying concrete delegate (e.g. ^Purchase_Delegate).
	concrete: rawptr,

	// Java: @Nullable String purchase(IntegerMap<ProductionRule>)
	purchase: proc(self: ^I_Purchase_Delegate, production_rules: ^Integer_Map) -> string,

	// Java: @Nullable String purchaseRepair(Map<Unit, IntegerMap<RepairRule>>)
	purchase_repair: proc(self: ^I_Purchase_Delegate, production_rules: map[^Unit]^Integer_Map) -> string,
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.remote.IPurchaseDelegate

// Public dispatch proc for purchase(IntegerMap<ProductionRule>).
i_purchase_delegate_purchase :: proc(
	self: ^I_Purchase_Delegate,
	production_rules: ^Integer_Map,
) -> string {
	return self.purchase(self, production_rules)
}

// Public dispatch proc for purchaseRepair(Map<Unit, IntegerMap<RepairRule>>).
i_purchase_delegate_purchase_repair :: proc(
	self: ^I_Purchase_Delegate,
	production_rules: map[^Unit]^Integer_Map,
) -> string {
	return self.purchase_repair(self, production_rules)
}

