package game

// games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate
// Pure Java interface modeled in Odin as a vtable struct. Concrete
// implementations (AbstractPlaceDelegate and its subclasses BidPlaceDelegate,
// NoAirCheckPlaceDelegate, PlaceDelegate) build an instance of this struct
// via abstract_place_delegate_to_i_abstract_place_delegate, populating
// `concrete` with the real delegate pointer and the proc fields with
// per-impl thunks. The Java interface extends IAbstractMoveDelegate, so the
// move-delegate fields are embedded by value as the first field per the
// single-inheritance convention.
I_Abstract_Place_Delegate :: struct {
	using i_abstract_move_delegate: I_Abstract_Move_Delegate,

	// Pointer to the underlying concrete delegate (e.g. ^Abstract_Place_Delegate
	// or one of its subclasses). The vtable thunks cast this back to the
	// concrete type before forwarding.
	concrete: rawptr,

	// games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate#getPlaceableUnits(Collection,Territory)
	get_placeable_units: proc(
		self: ^I_Abstract_Place_Delegate,
		units: [dynamic]^Unit,
		to: ^Territory,
	) -> ^Placeable_Units,

	// games.strategy.triplea.delegate.remote.IAbstractPlaceDelegate#placeUnits(Collection,Territory,BidMode)
	// The two-arg Java overload `placeUnits(units, at)` is the default method
	// that calls this one with BidMode.NOT_BID, so we only need a single
	// vtable slot (the dispatch proc below applies the default at the call
	// site via a default argument).
	place_units_with_bid_mode: proc(
		self: ^I_Abstract_Place_Delegate,
		units: [dynamic]^Unit,
		at: ^Territory,
		mode: I_Abstract_Place_Delegate_Bid_Mode,
	) -> Maybe(string),
}

// Public dispatch proc for getPlaceableUnits(Collection, Territory).
i_abstract_place_delegate_get_placeable_units :: proc(
	self: ^I_Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	to: ^Territory,
) -> ^Placeable_Units {
	return self.get_placeable_units(self, units, to)
}

// Public dispatch proc covering both Java overloads of placeUnits.
// Java's default method `placeUnits(units, at)` delegates to
// `placeUnits(units, at, BidMode.NOT_BID)`; in Odin we collapse both
// overloads into one proc using a default argument for `mode`.
i_abstract_place_delegate_place_units :: proc(
	self: ^I_Abstract_Place_Delegate,
	units: [dynamic]^Unit,
	at: ^Territory,
	mode: I_Abstract_Place_Delegate_Bid_Mode = .NOT_BID,
) -> Maybe(string) {
	return self.place_units_with_bid_mode(self, units, at, mode)
}
