package game

Target_Group :: struct {
	firing_unit_types: map[^Unit_Type]struct{},
	target_unit_types: map[^Unit_Type]struct{},
}
