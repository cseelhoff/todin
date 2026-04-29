package game

// Java owners covered by this file:
//   - games.strategy.triplea.util.UnitSeparator$SeparatorCategories$SeparatorCategoriesBuilder

Separator_Categories_Builder :: struct {
	dependents:                  map[^Unit][dynamic]^Unit,
	movement:                    bool,
	movement_for_air_units_only: bool,
	transport_cost:              bool,
	transport_movement:          bool,
	retreat_possibility:         bool,
}

