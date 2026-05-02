package game

// Java owners covered by this file:
//   - games.strategy.triplea.util.UnitSeparator$SeparatorCategories$SeparatorCategoriesBuilder

Unit_Separator_Separator_Categories_Separator_Categories_Builder :: struct {
	dependents:                  map[^Unit][dynamic]^Unit,
	movement:                    bool,
	movement_for_air_units_only: bool,
	transport_cost:              bool,
	transport_movement:          bool,
	retreat_possibility:         bool,
}

unit_separator_separator_categories_separator_categories_builder_new :: proc() -> ^Unit_Separator_Separator_Categories_Separator_Categories_Builder {
	b := new(Unit_Separator_Separator_Categories_Separator_Categories_Builder)
	return b
}

unit_separator_separator_categories_separator_categories_builder_dependents :: proc(self: ^Unit_Separator_Separator_Categories_Separator_Categories_Builder, dependents: map[^Unit][dynamic]^Unit) -> ^Unit_Separator_Separator_Categories_Separator_Categories_Builder {
	self.dependents = dependents
	return self
}

unit_separator_separator_categories_separator_categories_builder_retreat_possibility :: proc(self: ^Unit_Separator_Separator_Categories_Separator_Categories_Builder, retreat_possibility: bool) -> ^Unit_Separator_Separator_Categories_Separator_Categories_Builder {
	self.retreat_possibility = retreat_possibility
	return self
}

unit_separator_separator_categories_separator_categories_builder_transport_cost :: proc(self: ^Unit_Separator_Separator_Categories_Separator_Categories_Builder, transport_cost: bool) -> ^Unit_Separator_Separator_Categories_Separator_Categories_Builder {
	self.transport_cost = transport_cost
	return self
}

unit_separator_separator_categories_separator_categories_builder_build :: proc(self: ^Unit_Separator_Separator_Categories_Separator_Categories_Builder) -> ^Unit_Separator_Separator_Categories {
	out := new(Unit_Separator_Separator_Categories)
	out.dependents = self.dependents
	out.movement = self.movement
	out.movement_for_air_units_only = self.movement_for_air_units_only
	out.transport_cost = self.transport_cost
	out.transport_movement = self.transport_movement
	out.retreat_possibility = self.retreat_possibility
	return out
}

