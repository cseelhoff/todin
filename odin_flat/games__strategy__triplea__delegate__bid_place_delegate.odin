package game

Bid_Place_Delegate :: struct {
	using abstract_place_delegate: Abstract_Place_Delegate,
}

// games.strategy.triplea.delegate.BidPlaceDelegate#lambda$unitWhichRequiresUnitsHasRequiredUnits$1(Unit)
// Body: `u -> true`. Bids ignore "require units" constraints.
bid_place_delegate_lambda_unit_which_requires_units_has_required_units_1 :: proc(ctx: rawptr, u: ^Unit) -> bool {
	_ = ctx
	_ = u
	return true
}

