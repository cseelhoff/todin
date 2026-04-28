package game

Unit_Battle_Comparator :: struct {
	costs:                            map[^Unit_Type]i32,
	bonus:                            bool,
	ignore_primary_power:             bool,
	multi_hitpoint_can_repair:        map[^Unit_Type]struct{},
	combat_value_calculator:          ^Combat_Value,
	reversed_combat_value_calculator: ^Combat_Value,
}

