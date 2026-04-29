package game

// games.strategy.triplea.util.UnitSeparator
//
// Utility class with no instance fields. The Phase A type artifact
// is the inner @Builder static class `SeparatorCategories`.

Unit_Separator :: struct {}

Unit_Separator_Separator_Categories :: struct {
	// if not nil, group units with the same dependents
	dependents:                  map[^Unit][dynamic]^Unit,
	has_dependents:              bool,
	// whether to categorize by movement
	movement:                    bool,
	// whether to categorize by movement for air units only
	movement_for_air_units_only: bool,
	// whether to categorize by transport cost
	transport_cost:              bool,
	// whether to categorize transports by movement
	transport_movement:          bool,
	// whether to categorize by whether the unit can retreat or not
	retreat_possibility:         bool,
}

