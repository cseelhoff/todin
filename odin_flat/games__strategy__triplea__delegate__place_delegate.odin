package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.PlaceDelegate

Place_Delegate :: struct {
	using abstract_place_delegate: Abstract_Place_Delegate,
}

// games.strategy.triplea.delegate.PlaceDelegate#<init>()
// Java's implicit no-arg constructor. PlaceDelegate adds no fields beyond
// AbstractPlaceDelegate, so allocate a Place_Delegate and initialize the
// embedded parent in-place by copying the parent constructor's result.
place_delegate_new :: proc() -> ^Place_Delegate {
	self := new(Place_Delegate)
	parent := abstract_place_delegate_new()
	self.abstract_place_delegate = parent^
	free(parent)
	return self
}

