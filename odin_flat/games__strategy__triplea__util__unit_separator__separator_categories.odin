package game

Unit_Separator_Separator_Categories :: struct {
	dependents:                  map[^Unit][dynamic]^Unit,
	movement:                    bool,
	movement_for_air_units_only: bool,
	transport_cost:              bool,
	transport_movement:          bool,
	retreat_possibility:         bool,
}

