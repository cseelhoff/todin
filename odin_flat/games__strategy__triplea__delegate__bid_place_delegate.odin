package game

Bid_Place_Delegate :: struct {
	using abstract_place_delegate: Abstract_Place_Delegate,
}

// games.strategy.triplea.delegate.BidPlaceDelegate#<init>()
// Java's implicit no-arg constructor. Defers to AbstractPlaceDelegate's
// implicit constructor (which initializes `produced` and `placements`).
bid_place_delegate_new :: proc() -> ^Bid_Place_Delegate {
	self := new(Bid_Place_Delegate)
	self.produced = make(map[^Territory][dynamic]^Unit)
	self.placements = make([dynamic]^Undoable_Placement)
	return self
}

// games.strategy.triplea.delegate.BidPlaceDelegate#lambda$getUnitsToBePlaced$0(int, Unit)
// Body of the `cantBePlacedDueToTerritoryProduction` predicate inside
// getUnitsToBePlaced: returns true (i.e. unit cannot be placed) when the
// unit's UnitAttachment declares a positive `canOnlyBePlacedInTerritoryValuedAtX`
// requirement that exceeds the destination territory's production value.
bid_place_delegate_lambda_get_units_to_be_placed_0 :: proc(territory_production: i32, u: ^Unit) -> bool {
	required_production := unit_attachment_get_can_only_be_placed_in_territory_valued_at_x(unit_get_unit_attachment(u))
	return required_production != -1 && required_production > territory_production
}

// games.strategy.triplea.delegate.BidPlaceDelegate#lambda$unitWhichRequiresUnitsHasRequiredUnits$1(Unit)
// Body: `u -> true`. Bids ignore "require units" constraints.
bid_place_delegate_lambda_unit_which_requires_units_has_required_units_1 :: proc(ctx: rawptr, u: ^Unit) -> bool {
	_ = ctx
	_ = u
	return true
}

