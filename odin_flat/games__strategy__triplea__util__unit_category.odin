package game

Unit_Category :: struct {
	type:           ^Unit_Type,
	dependents:     [dynamic]^Unit_Owner,
	movement:       f64,
	transport_cost: i32,
	can_retreat:    bool,
	owner:          ^Game_Player,
	units:          [dynamic]^Unit,
	damaged:        i32,
	bombing_damage: i32,
	disabled:       bool,
}

