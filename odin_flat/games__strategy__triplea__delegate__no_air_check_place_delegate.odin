package game

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.NoAirCheckPlaceDelegate

// This extended delegate exists solely to do everything PlaceDelegate does, but NOT check for air
// that can't land.
No_Air_Check_Place_Delegate :: struct {
	using parent: Place_Delegate,
}

