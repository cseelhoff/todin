package game

Unit_Separator_Separator_Categories :: struct {
	dependents:                  map[^Unit][dynamic]^Unit,
	movement:                    bool,
	movement_for_air_units_only: bool,
	transport_cost:              bool,
	transport_movement:          bool,
	retreat_possibility:         bool,
}

unit_separator_separator_categories_default_dependents :: proc() -> map[^Unit][dynamic]^Unit {
	return nil
}

unit_separator_separator_categories_default_movement :: proc() -> bool {
	return false
}

unit_separator_separator_categories_default_movement_for_air_units_only :: proc() -> bool {
	return false
}

unit_separator_separator_categories_default_retreat_possibility :: proc() -> bool {
	return false
}

unit_separator_separator_categories_default_transport_cost :: proc() -> bool {
	return false
}

unit_separator_separator_categories_default_transport_movement :: proc() -> bool {
	return false
}

unit_separator_separator_categories_builder :: proc() -> ^Unit_Separator_Separator_Categories_Separator_Categories_Builder {
	return unit_separator_separator_categories_separator_categories_builder_new()
}

unit_separator_separator_categories_new :: proc(
	dependents: map[^Unit][dynamic]^Unit,
	movement: bool,
	movement_for_air_units_only: bool,
	transport_cost: bool,
	transport_movement: bool,
	retreat_possibility: bool,
) -> ^Unit_Separator_Separator_Categories {
	self := new(Unit_Separator_Separator_Categories)
	self.dependents = dependents
	self.movement = movement
	self.movement_for_air_units_only = movement_for_air_units_only
	self.transport_cost = transport_cost
	self.transport_movement = transport_movement
	self.retreat_possibility = retreat_possibility
	return self
}

