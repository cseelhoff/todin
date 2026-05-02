package game

Transport_Tracker :: struct {}

Allied_Air_Transport_Change :: struct {
	change:     ^Composite_Change,
	allied_air: [dynamic]^Unit,
}

transport_tracker_get_territory_transport_has_unloaded_to :: proc(transport: ^Unit) -> ^Territory {
	unloaded := unit_get_unloaded(transport)
	if len(unloaded) == 0 {
		return nil
	}
	return unit_get_unloaded_to(unloaded[0])
}

transport_tracker_transporting_with_fn :: proc(
	units: [dynamic]^Unit,
	get_units_transported_by_transport: proc(transport: ^Unit) -> [dynamic]^Unit,
) -> map[^Unit][dynamic]^Unit {
	return_val: map[^Unit][dynamic]^Unit
	for transported in units {
		transport := unit_get_transported_by(transported)
		if transport != nil {
			transporting := get_units_transported_by_transport(transport)
			return_val[transport] = transporting
		}
	}
	return return_val
}

