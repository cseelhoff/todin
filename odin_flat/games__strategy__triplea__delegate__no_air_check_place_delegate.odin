package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.NoAirCheckPlaceDelegate

// This extended delegate exists solely to do everything PlaceDelegate does, but NOT check for air
// that can't land.
No_Air_Check_Place_Delegate :: struct {
	using place_delegate: Place_Delegate,
}


// Stub: not on WW2v5 AI test path.
no_air_check_place_delegate_new :: proc() -> ^No_Air_Check_Place_Delegate {
	return new(No_Air_Check_Place_Delegate)
}
