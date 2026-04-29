package game

Add_Units :: struct {
	using parent: Change,
	name:           string,
	units:          [dynamic]^Unit,
	type:           string,
	unit_owner_map: map[Uuid]string,
}

