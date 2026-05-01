package game

Transport_Tracker_Allied_Air_Transport_Change :: struct {
	change:     ^Composite_Change,
	allied_air: [dynamic]^Unit,
}

allied_air_transport_change_new :: proc(
	change: ^Composite_Change,
	allied_air: [dynamic]^Unit,
) -> ^Transport_Tracker_Allied_Air_Transport_Change {
	self := new(Transport_Tracker_Allied_Air_Transport_Change)
	self.change = change
	self.allied_air = allied_air
	return self
}

allied_air_transport_change_get_change :: proc(
	self: ^Transport_Tracker_Allied_Air_Transport_Change,
) -> ^Composite_Change {
	return self.change
}

allied_air_transport_change_get_allied_air :: proc(
	self: ^Transport_Tracker_Allied_Air_Transport_Change,
) -> [dynamic]^Unit {
	return self.allied_air
}

// Java owners covered by this file:
//   - games.strategy.triplea.delegate.TransportTracker$AlliedAirTransportChange

